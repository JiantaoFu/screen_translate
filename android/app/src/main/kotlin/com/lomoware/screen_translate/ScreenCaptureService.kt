package com.lomoware.screen_translate

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.SystemClock
import android.util.DisplayMetrics
import android.util.Log
import android.view.Surface
import android.view.WindowManager
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.ConcurrentLinkedDeque
import java.util.Timer
import java.util.TimerTask
import android.graphics.ImageFormat
import kotlin.math.abs
import android.os.Build
import com.lomoware.screen_translate.utils.ColorUtils
import com.lomoware.screen_translate.utils.extractDominantColor

data class CapturedFrame(
    val frameBytes: ByteArray,
    val timestamp: Long,
    val width: Int,
    val height: Int
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as CapturedFrame

        if (!frameBytes.contentEquals(other.frameBytes)) return false
        if (timestamp != other.timestamp) return false
        if (width != other.width) return false
        if (height != other.height) return false

        return true
    }

    override fun hashCode(): Int {
        var result = frameBytes.contentHashCode()
        result = 31 * result + timestamp.hashCode()
        result = 31 * result + width
        result = 31 * result + height
        return result
    }

    override fun toString(): String {
        return "CapturedFrame(timestamp=$timestamp, dimensions=${width}x$height)"
    }
}

class FrameStabilizer(
    private val screenWidth: Int,
    private val screenHeight: Int,
    // Rows above this are the status bar — its clock and the screen-capture
    // indicator's running timer change every second and aren't content.
    private val ignoreTopPx: Int,
    private val onMotionDetected: () -> Unit
) {
    private companion object {
        const val GRID = 32 // GRID x GRID luma sample points
        const val LUMA_TOLERANCE = 16 // ignore compression/dither noise
        // Any difference above this counts as movement for learning where the
        // screen animates (slow fades/pans move a few luma levels per frame).
        const val MOTION_TOLERANCE = 2
        const val STABILIZATION_DELAY_MS = 300L // quiet time before translating
        // While something keeps animating (video, game scene) the static text
        // around it is re-read this often, so subtitles/typed-out dialogue in
        // or over the animated area still get picked up.
        const val ANIMATION_REFRESH_MS = 2500L
        // Time for a newly added/moved box to be fully drawn before its
        // look is recorded as the reference for under-box changes.
        const val BOX_SETTLE_MS = 400L
        // BoxWatch sampling: every STEP px inside a box; MIN_PIXELS differing
        // pixels is a few glyphs rather than noise. Through a ~98% opaque
        // box, full-contrast text beneath shifts luma by ~4-5; a static
        // screen capture is pixel-exact (0-1).
        const val STEP = 4
        const val MIN_PIXELS = 12
        const val CHANGE_TOLERANCE = 2
        const val MOVE_TOLERANCE = 1
    }

    private val classifier = MotionClassifier(GRID, GRID)
    // Samples of the content last translated (or last content change): slow
    // changes such as typed-out dialogue stay under the per-frame threshold
    // but add up against this.
    private var baseline: IntArray? = null
    private var baselineMask: List<Rect> = emptyList()
    private var pendingSamples: IntArray? = null
    private var lastDeliveredAt = 0L

    @Volatile private var disposed = false

    // Watches the content under each of our translated boxes (see
    // BoxWatch). Rebuilt whenever our windows change.
    private var boxVersion = -1L
    private var boxWatches: List<BoxWatch> = emptyList()
    private var boxBaselineDueAt = 0L

    private var lastFrame: ByteArray? = null
    private var lastFrameTime = 0L
    private var stabilizationTimer: Timer? = null
    private var stabilizationPending = false
    private val mainHandler = Handler(Looper.getMainLooper())

    private var lastSamples: IntArray? = null
    private var lastMask: List<Rect> = emptyList()
    // Most recent frame regardless of whether it counted as a change, and
    // the consumer it was delivered with — used by requestFreshFrame().
    private var latestFrame: ByteArray? = null
    private var latestOnStable: ((ByteArray) -> Unit)? = null

    private val sampleXs = IntArray(GRID) { (screenWidth * (2 * it + 1)) / (2 * GRID) }
    private val sampleYs = IntArray(GRID) {
        ignoreTopPx + ((screenHeight - ignoreTopPx) * (2 * it + 1)) / (2 * GRID)
    }

    // `bytes` is the NV21 buffer produced by imageToBytes(): the Y (luma)
    // plane comes first, one byte per pixel, tightly packed (no row
    // padding), so it is indexed directly.
    private fun sample(bytes: ByteArray): IntArray {
        val out = IntArray(GRID * GRID)
        for (row in 0 until GRID) {
            val rowBase = sampleYs[row] * screenWidth
            for (col in 0 until GRID) {
                val index = rowBase + sampleXs[col]
                out[row * GRID + col] = if (index < bytes.size) bytes[index].toInt() and 0xFF else 0
            }
        }
        return out
    }

    private fun changedSamples(
        prev: IntArray, cur: IntArray, mask: List<Rect>, tolerance: Int = LUMA_TOLERANCE
    ): BooleanArray {
        val changed = BooleanArray(GRID * GRID)
        for (row in 0 until GRID) {
            val y = sampleYs[row]
            for (col in 0 until GRID) {
                val i = row * GRID + col
                if (abs(prev[i] - cur[i]) <= tolerance) continue
                val x = sampleXs[col]
                if (mask.any { it.contains(x, y) }) continue
                changed[i] = true
            }
        }
        return changed
    }

    /**
     * The content under one of our translated boxes. Screen capture sees our
     * own boxes, so a change beneath one (the next line in a game's dialogue
     * box, a new page with the same layout) was invisible and its stale
     * translation stayed up. The boxes are drawn ~98% opaque, so what's
     * beneath shows through at a few luma levels — below what the eye
     * notices, but measurable. Text strokes are thin, so this samples the
     * box densely (the coarse screen grid landed between strokes).
     */
    private inner class BoxWatch(private val rect: Rect) {
        private val xs = (rect.left + STEP / 2 until rect.right step STEP)
            .filter { it in 0 until screenWidth }.toIntArray()
        private val ys = (rect.top + STEP / 2 until rect.bottom step STEP)
            .filter { it in 0 until screenHeight }.toIntArray()
        private val size = xs.size * ys.size
        // Enough differing pixels to be a few glyphs, not noise.
        private val threshold = maxOf(MIN_PIXELS, size / 250)
        private var baseline: IntArray? = null
        private var prev: IntArray? = null
        private var moveStreak = 0
        private var lastMove = Long.MIN_VALUE / 2

        private fun read(frame: ByteArray): IntArray {
            val out = IntArray(size)
            var k = 0
            for (y in ys) {
                val row = y * screenWidth
                for (x in xs) {
                    val idx = row + x
                    out[k++] = if (idx < frame.size) frame[idx].toInt() and 0xFF else 0
                }
            }
            return out
        }

        private fun count(a: IntArray, b: IntArray, tolerance: Int) =
            a.indices.count { abs(a[it] - b[it]) > tolerance }

        fun captureBaseline(frame: ByteArray) {
            baseline = read(frame).also { prev = it }
        }

        /** True when the content under this box changed since its baseline. */
        fun changed(frame: ByteArray, now: Long): Boolean {
            val base = baseline ?: return false
            if (size == 0) return false
            val cur = read(frame)
            val last = prev ?: cur
            prev = cur
            // Only a change that has settled counts: something that keeps
            // moving under the box (a video under a subtitle) never settles,
            // while a new dialogue line changes once and then holds.
            val moving = count(cur, last, MOVE_TOLERANCE) >= threshold
            if (moving) {
                moveStreak = if (now - lastMove <= MotionClassifier.STREAK_GAP_MS) moveStreak + 1 else 1
                lastMove = now
                return false
            }
            val animated = moveStreak >= MotionClassifier.ANIMATION_STREAK &&
                now - lastMove <= MotionClassifier.STREAK_GAP_MS
            if (animated) return false
            if (count(cur, base, CHANGE_TOLERANCE) < threshold) return false
            baseline = cur // acknowledged; the boxes get cleared next
            return true
        }
    }

    private fun drift(base: IntArray, cur: IntArray, mask: List<Rect>, now: Long): Int {
        val changed = changedSamples(base, cur, mask)
        return changed.indices.count { changed[it] && !classifier.isAnimated(it, now) }
    }

    @Synchronized
    fun onNewFrame(currentFrame: ByteArray, currentTime: Long, onStable: (ByteArray) -> Unit) {
        if (disposed) return
        latestFrame = currentFrame
        latestOnStable = onStable
        val samples = sample(currentFrame)
        val mask = OverlayRegions.snapshot()
        val prev = lastSamples
        val prevMask = lastMask
        lastSamples = samples
        lastMask = mask

        val version = OverlayRegions.version()
        val boxesStable = version == boxVersion
        if (!boxesStable) {
            boxVersion = version
            // Like the rest of change detection, leave the status bar out:
            // its clock and the screen-sharing timer tick on their own.
            boxWatches = OverlayRegions.textBoxRects()
                .filter { it.top >= ignoreTopPx }
                .map { BoxWatch(it) }
            boxBaselineDueAt = currentTime + BOX_SETTLE_MS
        } else if (boxBaselineDueAt > 0 && currentTime >= boxBaselineDueAt) {
            boxWatches.forEach { it.captureBaseline(currentFrame) }
            boxBaselineDueAt = 0
        }

        if (prev == null) {
            baseline = samples
            baselineMask = mask
            scheduleStable(currentFrame, samples, currentTime, onStable)
            return
        }

        // Ignore regions covered by our own windows in EITHER frame: one
        // just added/moved/removed changes pixels in both its old and new
        // spot without the underlying content having changed.
        val frameMask = prevMask + mask
        var change = classifier.classify(
            changedSamples(prev, samples, frameMask),
            changedSamples(prev, samples, frameMask, MOTION_TOLERANCE),
            currentTime
        )
        var reason = "frame"
        val base = baseline
        if (change != FrameChange.CONTENT && base != null &&
            drift(base, samples, baselineMask + mask, currentTime) >= MotionClassifier.MIN_CHANGED_SAMPLES) {
            change = FrameChange.CONTENT
            reason = "drift"
        }
        if (boxesStable && boxBaselineDueAt == 0L) {
            // Evaluate every box (not short-circuiting) so each keeps its
            // own motion history up to date.
            val underChanged = boxWatches.map { it.changed(currentFrame, currentTime) }.any { it }
            if (change != FrameChange.CONTENT && underChanged) {
                change = FrameChange.CONTENT
                reason = "under our boxes"
            }
        }

        when (change) {
            FrameChange.CONTENT -> {
                Log.d("FrameStabilizer", "Content change ($reason)")
                baseline = samples
                baselineMask = mask
                onMotionDetected()
                scheduleStable(currentFrame, samples, currentTime, onStable)
            }
            FrameChange.ANIMATION -> {
                // Animation must neither clear the translations of the static
                // text around it nor postpone translating it.
                if (stabilizationPending) {
                    lastFrame = currentFrame
                    pendingSamples = samples
                } else if (currentTime - lastDeliveredAt >= ANIMATION_REFRESH_MS) {
                    Log.d("FrameStabilizer", "Animation only, refreshing")
                    scheduleStable(currentFrame, samples, currentTime, onStable)
                }
            }
            FrameChange.NONE -> {
                // If we're already waiting for the screen to settle, prefer
                // the newest frame: right after a real change our overlays
                // are being torn down, and the queued frame must not still
                // contain them (OCR would read our own translations back).
                if (stabilizationPending) {
                    lastFrame = currentFrame
                    pendingSamples = samples
                }
            }
        }
    }

    /** Stops any pending delivery; the instance must not be used afterwards. */
    @Synchronized
    fun dispose() {
        disposed = true
        stabilizationTimer?.cancel()
        stabilizationTimer = null
        stabilizationPending = false
        lastFrame = null
        latestFrame = null
        latestOnStable = null
    }

    /**
     * Queue the current screen again once it has been quiet for the
     * stabilization delay, even though nothing changed. Needed after an
     * external cancel (scroll/window-change event): Dart drops whatever
     * frame it was processing, and on a static screen no content change
     * would ever produce another one, leaving the screen untranslated.
     */
    @Synchronized
    fun requestFreshFrame() {
        if (disposed) return
        val frame = latestFrame ?: return
        val onStable = latestOnStable ?: return
        scheduleStable(frame, lastSamples, System.currentTimeMillis(), onStable)
    }

    private fun scheduleStable(frame: ByteArray, samples: IntArray?, currentTime: Long, onStable: (ByteArray) -> Unit) {
        stabilizationTimer?.cancel()
        lastFrame = frame
        pendingSamples = samples
        lastFrameTime = currentTime
        stabilizationPending = true

        stabilizationTimer = Timer().apply {
            schedule(object : TimerTask() {
                override fun run() {
                    synchronized(this@FrameStabilizer) {
                        // Only fire if no content change has arrived since scheduling
                        if (currentTime != lastFrameTime) return
                        stabilizationPending = false
                        val stableFrame = lastFrame ?: return
                        lastFrame = null
                        pendingSamples?.let {
                            baseline = it
                            baselineMask = lastMask
                        }
                        lastDeliveredAt = System.currentTimeMillis()
                        mainHandler.post {
                            // Disposed (screen rotated) since this was posted:
                            // the frame has the old orientation.
                            if (disposed) return@post
                            Log.d("FrameStabilizer", "Frame stabilized after $STABILIZATION_DELAY_MS ms")
                            onStable(stableFrame)
                        }
                    }
                }
            }, STABILIZATION_DELAY_MS)
        }
    }
}

class ScreenCaptureService(private val context: Context, private val activity: Activity) {
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var screenDensity: Int = 0
    private val TAG = "ScreenCaptureService"
    private val isCapturing = AtomicBoolean(false)
    private val frameCount = AtomicInteger(0)
    private val MAX_QUEUE_SIZE = 1
    private val MAX_FRAME_AGE = 2000L
    private val imageQueue = ConcurrentLinkedDeque<CapturedFrame>() // Pair of bytes and timestamp
    private val handlerThread = HandlerThread("ImageReaderThread").apply { start() }
    private val imageReaderHandler = Handler(handlerThread.looper)
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var frameStabilizer: FrameStabilizer
    private var latestResultCode: Int = 0
    private lateinit var latestProjectionIntent: Intent
    private lateinit var latestProjectionResult: MethodChannel.Result
    private var currentRotation: Int = 0
    private val methodChannel: MethodChannel by lazy {
        val messenger = MainActivity.binaryMessenger
            ?: throw IllegalStateException("Binary messenger is not available")
        MethodChannel(messenger, "com.lomoware.screen_translate/translationService")
    }

    // Reused across frames: a full-screen RGBA buffer is ~10MB, and
    // allocating a fresh one for every ImageReader frame was OOM-ing
    // low-memory devices. Only touched on the ImageReader thread.
    private var rgbaScratch: ByteArray? = null

    companion object {
        private const val PREF_TRANSLATION_MODE = "translation_mode"
        private const val MODE_AUTO = "auto"
        private const val MODE_MANUAL = "manual"
        private const val MODE_OFF = "off"
        private const val MODE_ORIGINAL = "original"
    }

    init {
        // Log service initialization details
        Log.d(TAG, "ScreenCaptureService initialized")
        Log.d(TAG, "Context: $context")
        Log.d(TAG, "Context class: ${context.javaClass.name}")
        
        val (w, h) = currentScreenSize()
        screenWidth = w
        screenHeight = h
        screenDensity = context.resources.displayMetrics.densityDpi
        Log.d(TAG, "Screen metrics (real): $screenWidth x $screenHeight @ $screenDensity")

        frameStabilizer = createFrameStabilizer()

        // Register scroll detection receiver during initialization
        registerScrollDetectionReceiver()
        
        // Automatically check and prompt for Accessibility Service
        checkAccessibilityServiceOnFirstLaunch()
    }

    fun startProjection(resultCode: Int, data: Intent, result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Starting projection with result code: $resultCode")

            ForegroundService.startAndAwaitForeground(context) {
                try {
                    Log.d(TAG, "Creating MediaProjection...")
                    val mpManager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    mediaProjection = mpManager.getMediaProjection(resultCode, data)?.apply {
                        registerCallback(object : MediaProjection.Callback() {
                            override fun onStop() {
                                Log.d(TAG, "MediaProjection stopped")
                                mainHandler.post {
                                    cleanup()
                                    context.stopService(Intent(context, ForegroundService::class.java))
                                }
                            }
                        }, null)
                    }
                    
                    if (mediaProjection == null) {
                        val error = "Failed to create MediaProjection"
                        Log.e(TAG, error)
                        result.error("PROJECTION_ERROR", error, null)
                        return@startAndAwaitForeground
                    }
                    
                    Log.d(TAG, "MediaProjection created successfully")
                    setupVirtualDisplay()
                    isCapturing.set(true) // Set capturing to true when projection starts
                    displayManager()?.registerDisplayListener(displayListener, mainHandler)
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Error creating MediaProjection", e)
                    result.error("PROJECTION_ERROR", "Error creating MediaProjection: ${e.message}", null)
                    cleanup()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting projection", e)
            result.error("PROJECTION_ERROR", "Error starting projection: ${e.message}", null)
            cleanup()
        }
    }

    fun stopProjection() {
        Log.d(TAG, "Stopping projection")
        try {
            mediaProjection?.stop()
            mediaProjection = null
            cleanup()
            isCapturing.set(false) // Set capturing to false when projection stops
            context.stopService(Intent(context, ForegroundService::class.java))
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping projection", e)
        }
    }

    // The screen's real size in its CURRENT orientation. Deliberately not
    // read through the Activity's WindowManager: on Android 14+ that reports
    // the Activity's own window configuration, which stays portrait while
    // our (backgrounded) app is portrait and the game in front runs
    // landscape — so rotation was never detected in exactly that case, and
    // landscape games were captured squeezed into a portrait frame.
    private fun currentScreenSize(): Pair<Int, Int> {
        val appContext = context.applicationContext ?: context
        val display = (appContext.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager)
            ?.getDisplay(android.view.Display.DEFAULT_DISPLAY)
        if (display == null) {
            val m = context.resources.displayMetrics
            return m.widthPixels to m.heightPixels
        }
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        display.getRealMetrics(metrics)
        var w = metrics.widthPixels
        var h = metrics.heightPixels
        // Cross-check against the display's actual rotation.
        val mode = display.mode
        val naturalLandscape = mode.physicalWidth > mode.physicalHeight
        val rotated = display.rotation == Surface.ROTATION_90 || display.rotation == Surface.ROTATION_270
        val landscapeNow = rotated != naturalLandscape
        if ((landscapeNow && w < h) || (!landscapeNow && w > h)) {
            val t = w; w = h; h = t
        }
        return w to h
    }

    // Rotation (e.g. a landscape game coming to the front). Must run on the
    // main thread.
    private fun handleScreenSizeChange() {
        if (!isCapturing.get()) return
        try {
            val (currentW, currentH) = currentScreenSize()
            if (currentW == screenWidth && currentH == screenHeight) return
            Log.d(TAG, "Screen rotation detected! Updating dimensions: ${screenWidth}x${screenHeight} -> ${currentW}x${currentH}")
            screenWidth = currentW
            screenHeight = currentH
            // A frame the old stabilizer is still waiting on has the old
            // orientation; it must not be delivered after this.
            frameStabilizer.dispose()
            frameStabilizer = createFrameStabilizer()
            resizeVirtualDisplay()
            // Everything on screen moved: boxes placed for the old
            // orientation are wrong now, and so is any OCR still in flight.
            cancelAllTranslations()
        } catch (e: Exception) {
            Log.e(TAG, "Error handling screen size change", e)
        }
    }

    // Reacts to rotation immediately. Detecting it only when Dart next polled
    // captureScreen() let an OCR cycle already running on an old-orientation
    // frame (Dart doesn't poll while processing) draw its boxes, misplaced,
    // on the rotated screen before they were cleared.
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {}
        override fun onDisplayRemoved(displayId: Int) {}
        override fun onDisplayChanged(displayId: Int) {
            if (displayId == android.view.Display.DEFAULT_DISPLAY) handleScreenSizeChange()
        }
    }

    private fun displayManager(): DisplayManager? =
        (context.applicationContext ?: context).getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager

    fun captureScreen(result: MethodChannel.Result) {
        try {
            if (!isCapturing.get()) {
                result.error("NOT_CAPTURING", "Screen capture is not active", null)
                return
            }

            // Normally handled as it happens by displayListener; checked here
            // too in case a display change was missed.
            handleScreenSizeChange()
           
            val frame = imageQueue.pollLast() // Atomically peek and remove
            if (frame != null) {
                val (bytes, timestamp, width, height) = frame
                val age = System.currentTimeMillis() - timestamp

                if (age <= MAX_FRAME_AGE) {
                    Log.d(TAG, "Sending image bytes: ${bytes.size}, frame age: ${age}ms")
                } else {
                    Log.w(TAG, "Frame too old: ${age}ms")
                }

                result.success(mapOf(
                    "bytes" to bytes,
                    "width" to width,
                    "height" to height
                ))
            } else {
                // No frame available yet - return null so Flutter can retry on next tick
                // CRITICAL: We must ALWAYS call result.success or result.error,
                // otherwise the Flutter method channel will hang forever!
                Log.d(TAG, "captureScreen: No frame available in queue, returning null")
                result.success(null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error capturing screen", e)
            result.error("CAPTURE_ERROR", "Error capturing screen: ${e.message}", null)
        }
    }

    private fun setupVirtualDisplay() {
        try {
            Log.d(TAG, "Setting up virtual display")
            
            if (mediaProjection == null) {
                Log.e(TAG, "MediaProjection is null")
                return
            }

            // Clean up existing resources first
            safeCloseImageReader()
            imageReader = null
            virtualDisplay?.release()
            virtualDisplay = null
            
            Log.d(TAG, "Creating ImageReader with dimensions: ${screenWidth}x${screenHeight}")
            imageReader = ImageReader.newInstance(
                screenWidth, screenHeight,
                PixelFormat.RGBA_8888, 4  // Increased buffer size
            ).apply {
                setOnImageAvailableListener(createImageAvailableListener(), imageReaderHandler)
            }
            
            if (imageReader?.surface == null) {
                Log.e(TAG, "Failed to create ImageReader surface")
                return
            }

            Log.d(TAG, "Creating virtual display...")
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "ScreenCapture",
                screenWidth, screenHeight, screenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface, null, null
            )

            if (virtualDisplay == null) {
                Log.e(TAG, "Failed to create virtual display")
                return
            }
            
            // Verify setup
            val displayValid = virtualDisplay?.display?.isValid == true
            val surfaceValid = imageReader?.surface?.isValid == true
            Log.d(TAG, "Virtual display setup complete. Display valid: $displayValid, Surface valid: $surfaceValid")
            
            if (!displayValid || !surfaceValid) {
                Log.e(TAG, "Display or surface is invalid after setup")
                cleanup()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up virtual display", e)
            cleanup()
        }
    }

    // Android 14+ allows only one createVirtualDisplay() per MediaProjection;
    // re-running setupVirtualDisplay() on rotation threw SecurityException
    // and killed capture the moment a user turned the phone to landscape —
    // i.e. in almost every game. Resize the existing display and point it at
    // a new, correctly-sized ImageReader instead.
    private fun resizeVirtualDisplay() {
        val display = virtualDisplay
        if (display == null) {
            setupVirtualDisplay()
            return
        }
        try {
            val newReader = ImageReader.newInstance(
                screenWidth, screenHeight,
                PixelFormat.RGBA_8888, 4
            ).apply {
                setOnImageAvailableListener(createImageAvailableListener(), imageReaderHandler)
            }
            // Surface first, then resize: the system recomputes how the
            // mirrored screen is scaled into our buffer when it handles the
            // resize, reading the display's CURRENT surface size. Resizing
            // first raced with setSurface — when the old (other-orientation)
            // surface was still attached, the screen got mapped at the wrong
            // scale/offset (e.g. portrait content shrunk into the right edge)
            // and stayed that way until the next rotation.
            display.surface = newReader.surface
            display.resize(screenWidth, screenHeight, screenDensity)
            safeCloseImageReader()
            imageReader = newReader
            // Frames queued before the swap have the old dimensions.
            imageQueue.clear()
            Log.d(TAG, "Virtual display resized to ${screenWidth}x${screenHeight}")
        } catch (e: Exception) {
            Log.e(TAG, "Error resizing virtual display", e)
        }
    }

    private fun cleanup() {
        try {
            Log.d(TAG, "Starting cleanup")
            displayManager()?.unregisterDisplayListener(displayListener)
            imageQueue.clear()
            frameCount.set(0)
            virtualDisplay?.release()
            virtualDisplay = null
            
            safeCloseImageReader()
            mediaProjection?.stop()
            mediaProjection = null

            // Unregister broadcast receiver
            unregisterScrollDetectionReceiver()

            // Also stop and clear all overlays
            val intent = Intent(context, OverlayService::class.java).apply {
                action = "stop"
            }
            context.startService(intent)

            Log.d(TAG, "Cleanup complete")
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        }
    }

    private fun safeCloseImageReader() {
        val localImageReader = imageReader
        if (localImageReader != null) {
            synchronized(imageLock) {
                try {
                    Log.d(TAG, "Attempting to close ImageReader")
                    
                    // Remove listener to prevent new callbacks
                    localImageReader.setOnImageAvailableListener(null, null)
                    dropHeldImageLocked()
                    
                    // Close any remaining images
                    var image: Image?
                    do {
                        image = localImageReader.acquireLatestImage()
                        image?.close()
                    } while (image != null)
                    
                    // Close the ImageReader
                    localImageReader.close()
                    imageReader = null
                    
                    Log.d(TAG, "ImageReader closed successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error closing ImageReader", e)
                }
            }
        }
    }

    // Reading an Image's pixels (getPlanes) locks its buffer for the CPU,
    // which costs a full-screen copy + conversion and, on some graphics
    // drivers (seen on the emulator), leaks one sync-fence fd per locked
    // frame until the process hits its fd limit and aborts. Video/animation
    // produces 30-60 frames/s, but change detection only needs a few, so
    // pixels are read at most once per MIN_READ_INTERVAL_MS. Frames in
    // between are dropped without being read — except the newest one,
    // which is held and read when the interval elapses, so the screen's
    // final state after motion stops is never missed.
    private val MIN_READ_INTERVAL_MS = 120L
    private var lastReadAt = 0L
    private var heldImage: Image? = null
    // Guards reading/holding/closing captured Images and closing readers.
    // Deliberately NOT the ImageReader itself: ImageReader locks its own
    // monitor internally when releasing an Image, so sharing it deadlocked
    // (image thread closing an old reader's held Image under the NEW
    // reader's monitor vs. the main thread closing the old reader on
    // rotation). Everything below takes this lock first.
    private val imageLock = Any()
    private val readHeld = Runnable {
        synchronized(imageLock) { readHeldLocked() }
    }

    private fun readHeldLocked() {
        val image = heldImage ?: return
        heldImage = null
        lastReadAt = SystemClock.uptimeMillis()
        try {
            image.use { processImage(it) }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing captured frame", e)
        }
    }

    // Must be called with imageLock held.
    private fun dropHeldImageLocked() {
        imageReaderHandler.removeCallbacks(readHeld)
        heldImage?.close()
        heldImage = null
    }

    private fun createImageAvailableListener(): ImageReader.OnImageAvailableListener {
        return ImageReader.OnImageAvailableListener { reader ->
            try {
                frameCount.incrementAndGet()
                synchronized(imageLock) {
                    // Newer frame supersedes the one we were holding.
                    dropHeldImageLocked()
                    val image = reader.acquireLatestImage() ?: return@synchronized
                    heldImage = image
                    val wait = lastReadAt + MIN_READ_INTERVAL_MS - SystemClock.uptimeMillis()
                    if (wait <= 0) readHeldLocked()
                    else imageReaderHandler.postDelayed(readHeld, wait)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error in image available listener", e)
            }
        }
    }

    private fun processImage(image: Image) {
        val width = image.width
        val height = image.height
        val bytes = imageToBytes(image)
        if (bytes == null) {
            Log.e(TAG, "Failed to convert image to bytes")
            return
        }
        val currentTime = System.currentTimeMillis()
        frameStabilizer.onNewFrame(bytes, currentTime) { stableFrame ->
            // Our buttons, and the status bar while it's shown (its clock and
            // the screen-sharing timer aren't content and tick constantly).
            val hidden = OverlayRegions.controlRects().toMutableList()
            if (OverlayRegions.statusBarVisible) hidden += Rect(0, 0, width, statusBarHeight())
            blankRects(stableFrame, width, height, hidden)
            // Remove old frames if queue is too large
            while (imageQueue.size >= MAX_QUEUE_SIZE) {
                imageQueue.removeFirst()
            }
            imageQueue.addLast(CapturedFrame(stableFrame, currentTime, width, height))
            Log.d(TAG, "New frame queued, queue size: ${imageQueue.size}")
        }
    }

    private fun saveImagePreview(image: Image, width: Int, height: Int, rotation: Int) {
        try {
            // Create bitmap directly from the first plane (ARGB)
            val planes = image.planes
            val buffer = planes[0].buffer
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            bitmap.copyPixelsFromBuffer(buffer)

            // Create a unique filename with timestamp and rotation
            val timestamp = System.currentTimeMillis()
            val filename = "screen_capture_${timestamp}_rot${rotation}.png"
            
            // Get the external files directory
            val directory = context.getExternalFilesDir(null)
            val file = File(directory, "previews/$filename")
            
            // Ensure the directory exists
            file.parentFile?.mkdirs()

            // Save the bitmap
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }

            Log.d(TAG, "Image preview saved: ${file.absolutePath}")
            Log.d(TAG, "Image details: ${width}x${height}, rotation: $rotation")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving image preview", e)
        }
    }

    // Paints [rects] flat grey in an NV21 frame so OCR can't read them.
    private fun blankRects(nv21: ByteArray, width: Int, height: Int, rects: List<Rect>) {
        val grey = 0x80.toByte()
        for (r in rects) {
            val l = r.left.coerceIn(0, width)
            val rt = r.right.coerceIn(0, width)
            val t = r.top.coerceIn(0, height)
            val b = r.bottom.coerceIn(0, height)
            if (l >= rt || t >= b) continue
            for (y in t until b) java.util.Arrays.fill(nv21, y * width + l, y * width + rt, grey)
            val uvBase = width * height
            for (y in t / 2 until (b + 1) / 2) {
                val row = uvBase + y * width
                java.util.Arrays.fill(nv21, (row + (l and 1.inv())).coerceAtMost(nv21.size), (row + rt).coerceAtMost(nv21.size), grey)
            }
        }
    }

    fun imageToBytes(image: Image): ByteArray? {
        try {
            val width = image.width
            val height = image.height
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride

            // 1. Read entire buffer to a fast local array to eliminate JNI crossing overhead
            val bufferBytes = rgbaScratch?.takeIf { it.size == buffer.capacity() }
                ?: ByteArray(buffer.capacity()).also { rgbaScratch = it }
            buffer.position(0)
            buffer.get(bufferBytes)

            // NV21 format size: height * width + 2 * (height/2 * width/2)
            val nv21Size = width * height + 2 * ((height + 1) / 2) * ((width + 1) / 2)
            val nv21Bytes = ByteArray(nv21Size)
            
            var yPos = 0
            // Fill Y plane
            for (row in 0 until height) {
                var pos = row * rowStride
                for (col in 0 until width) {
                    val r = bufferBytes[pos].toInt() and 0xFF
                    val g = bufferBytes[pos + 1].toInt() and 0xFF
                    val b = bufferBytes[pos + 2].toInt() and 0xFF
                    
                    val y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                    nv21Bytes[yPos++] = y.toByte()
                    pos += pixelStride
                }
            }
            
            // Fill UV plane
            val uvPos = width * height
            var posNv21 = uvPos
            for (row in 0 until height step 2) {
                var pos = row * rowStride
                for (col in 0 until width step 2) {
                    val r = bufferBytes[pos].toInt() and 0xFF
                    val g = bufferBytes[pos + 1].toInt() and 0xFF
                    val b = bufferBytes[pos + 2].toInt() and 0xFF
                    
                    // Nearest neighbor NV21 UV calculation (faster, sufficient for ML Kit)
                    val u = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                    val v = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128
                    
                    nv21Bytes[posNv21++] = v.toByte()
                    nv21Bytes[posNv21++] = u.toByte()
                    pos += pixelStride * 2
                }
            }
            
            return nv21Bytes
        } catch (e: Exception) {
            Log.e(TAG, "Error converting image to bytes", e)
            return null
        } catch (e: OutOfMemoryError) {
            // Drop this frame rather than the whole process; the next
            // frame retries once the GC has caught up.
            Log.e(TAG, "Out of memory converting image, dropping frame", e)
            rgbaScratch = null
            return null
        }
    }

    // Called by Dart after it drops a frame as stale (a cancel arrived
    // while it was processing), so the current screen gets queued again
    // even if nothing on it changes afterwards.
    fun requestFreshFrame() {
        if (::frameStabilizer.isInitialized) frameStabilizer.requestFreshFrame()
    }

    private fun createFrameStabilizer(): FrameStabilizer {
        return FrameStabilizer(screenWidth, screenHeight, statusBarHeight()) {
            // This fires synchronously from onNewFrame() on the
            // imageReaderHandler background thread, but cancelAllTranslations()
            // goes through a Flutter MethodChannel, which requires the main
            // thread and throws otherwise. That exception used to escape
            // onNewFrame() uncaught, aborting it before it could reschedule
            // the stabilization timer — so on almost every frame where
            // anything changed, no new frame ever made it into the capture
            // queue. Posting to the main thread keeps this from throwing.
            mainHandler.post {
                val intent = Intent(context, OverlayService::class.java)
                intent.action = "hideAll"
                context.startService(intent)
                cancelAllTranslations()
            }
        }
    }

    private fun statusBarHeight(): Int {
        val id = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (id > 0) context.resources.getDimensionPixelSize(id) else 0
    }

    private fun cancelAllTranslations() {
        Log.d(TAG, "Canceling all translations")
        
        try {
            methodChannel.invokeMethod("cancelTranslation", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d(TAG, "Translation cancellation method invocation successful")
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "Translation cancellation method invocation error: $errorCode, $errorMessage")
                }

                override fun notImplemented() {
                    Log.e(TAG, "Translation cancellation method not implemented")
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Error invoking translation cancellation method", e)
        }
    }

    // Scroll detection broadcast receiver
    private var scrollDetectionReceiver: BroadcastReceiver? = null

    private fun createScrollDetectionReceiver(): BroadcastReceiver {
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                try {
                    // Log all intent details for debugging
                    Log.d(TAG, "Local Broadcast received")
                    Log.d(TAG, "Intent action: ${intent.action}")
                    Log.d(TAG, "Intent extras: ${intent.extras}")

                    when (intent.action) {
                        ScrollDetectionAccessibilityService.SCROLL_DETECTED_ACTION -> {
                            val packageName = intent.getStringExtra("package") ?: "unknown"
                            val scrollXDelta = intent.getIntExtra("scrollXDelta", 0)
                            val scrollYDelta = intent.getIntExtra("scrollYDelta", 0)

                            Log.d(TAG, "Scroll event received - Package: $packageName, X Delta: $scrollXDelta, Y Delta: $scrollYDelta")

                            // Pause translation or take appropriate action
                            val overlayIntent = Intent(context, OverlayService::class.java)
                            overlayIntent.action = "hideAll"
                            context.startService(overlayIntent)

                            cancelAllTranslations()
                            frameStabilizer.requestFreshFrame()
                        }
                        ScrollDetectionAccessibilityService.WINDOW_CHANGED_ACTION -> {
                            val packageName = intent.getStringExtra("package") ?: "unknown"
                            Log.d(TAG, "Foreground window changed to $packageName — clearing stale overlays")

                            // The captured screen no longer matches what's on
                            // screen (user switched apps, went Home, or opened
                            // Recents) — leaving the old overlay up just
                            // plasters stale translated text over unrelated
                            // content.
                            val overlayIntent = Intent(context, OverlayService::class.java)
                            overlayIntent.action = "hideAll"
                            context.startService(overlayIntent)

                            cancelAllTranslations()
                            frameStabilizer.requestFreshFrame()
                        }
                        else -> {
                            Log.w(TAG, "Unexpected intent action: ${intent.action}")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in scroll detection receiver", e)
                }
            }
        }
    }

    private fun registerScrollDetectionReceiver() {
        try {
            // Ensure previous receiver is unregistered
            unregisterScrollDetectionReceiver()

            // Create a new receiver
            scrollDetectionReceiver = createScrollDetectionReceiver()

            // Detailed logging about receiver registration
            Log.d(TAG, "Attempting to register local scroll detection receiver")
            Log.d(TAG, "Current context: $context")
            Log.d(TAG, "Context class: ${context.javaClass.name}")
            
            val filter = IntentFilter(ScrollDetectionAccessibilityService.SCROLL_DETECTED_ACTION)
            filter.addAction(ScrollDetectionAccessibilityService.WINDOW_CHANGED_ACTION)
            
            // Register using LocalBroadcastManager with application context
            val appContext = context.applicationContext
            scrollDetectionReceiver?.let { receiver ->
                LocalBroadcastManager.getInstance(appContext)
                    .registerReceiver(receiver, filter)
                
                Log.d(TAG, "Local scroll detection receiver registered successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error registering local scroll detection receiver", e)
            
            // Additional context logging for debugging
            Log.e(TAG, "Context details:")
            Log.e(TAG, "Context: $context")
            Log.e(TAG, "Context class: ${context.javaClass.name}")
            Log.e(TAG, "Exception: ${e.message}")
            Log.e(TAG, "Stack trace: ${e.stackTraceToString()}")
        }
    }

    private fun unregisterScrollDetectionReceiver() {
        try {
            scrollDetectionReceiver?.let { receiver ->
                // Unregister using LocalBroadcastManager with application context
                val appContext = context.applicationContext
                LocalBroadcastManager.getInstance(appContext)
                    .unregisterReceiver(receiver)
                
                Log.d(TAG, "Local scroll detection receiver unregistered")
                
                // Set to null to prevent multiple unregistrations
                scrollDetectionReceiver = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering local scroll detection receiver", e)
            Log.e(TAG, "Exception: ${e.message}")
            Log.e(TAG, "Stack trace: ${e.stackTraceToString()}")
        }
    }

    // Ensure receiver is unregistered when service is stopped or destroyed
    fun onStop() {
        unregisterScrollDetectionReceiver()
    }

    // Automatically check and prompt for Accessibility Service
    fun checkAccessibilityServiceOnFirstLaunch() {
        try {
            // Use application context to avoid potential context-related issues
            val appContext = context.applicationContext
            val permissionDialog = AccessibilityPermissionDialog(appContext)
            Log.d(TAG, "Checking accessibility service on first launch")
            permissionDialog.show()
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility service", e)
        }
    }
}
