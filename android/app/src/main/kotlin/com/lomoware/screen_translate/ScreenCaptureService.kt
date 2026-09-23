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
        const val MIN_CHANGED_SAMPLES = 3 // ignore a single blinking cursor
        const val STABILIZATION_DELAY_MS = 300L // quiet time before translating
    }

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

    private fun countChanged(prev: IntArray, cur: IntArray, mask: List<Rect>): Int {
        var changed = 0
        for (row in 0 until GRID) {
            val y = sampleYs[row]
            for (col in 0 until GRID) {
                val i = row * GRID + col
                if (abs(prev[i] - cur[i]) <= LUMA_TOLERANCE) continue
                val x = sampleXs[col]
                if (mask.any { it.contains(x, y) }) continue
                changed++
            }
        }
        return changed
    }

    @Synchronized
    fun onNewFrame(currentFrame: ByteArray, currentTime: Long, onStable: (ByteArray) -> Unit) {
        latestFrame = currentFrame
        latestOnStable = onStable
        val samples = sample(currentFrame)
        val mask = OverlayRegions.snapshot()
        val prev = lastSamples
        // Ignore regions covered by our own windows in EITHER frame: one
        // just added/moved/removed changes pixels in both its old and new
        // spot without the underlying content having changed.
        val changed = if (prev == null) 0 else countChanged(prev, samples, lastMask + mask)
        lastSamples = samples
        lastMask = mask

        val isFirstFrame = prev == null
        if (!isFirstFrame && changed < MIN_CHANGED_SAMPLES) {
            // Not a content change — but if we're already waiting for the
            // screen to settle, prefer the newest frame: right after a
            // real change our overlays are being torn down, and the queued
            // frame must not still contain them (OCR would read our own
            // translations back as source text).
            if (stabilizationPending) lastFrame = currentFrame
            return
        }

        Log.d("FrameStabilizer", "Content change: $changed samples differ")
        if (!isFirstFrame) onMotionDetected()
        scheduleStable(currentFrame, currentTime, onStable)
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
        val frame = latestFrame ?: return
        val onStable = latestOnStable ?: return
        scheduleStable(frame, System.currentTimeMillis(), onStable)
    }

    private fun scheduleStable(frame: ByteArray, currentTime: Long, onStable: (ByteArray) -> Unit) {
        stabilizationTimer?.cancel()
        lastFrame = frame
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
                        mainHandler.post {
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
        if (messenger != null) {
            MethodChannel(messenger, "com.lomoware.screen_translate/translationService")
        } else {
            Log.e(TAG, "Cannot create method channel: Binary messenger is null")
            throw IllegalStateException("Binary messenger is not available")
        }
    }

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
        
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            wm.defaultDisplay.getRealMetrics(metrics)
        } else {
            wm.defaultDisplay.getMetrics(metrics)
        }
        screenWidth = metrics.widthPixels
        screenHeight = metrics.heightPixels
        screenDensity = metrics.densityDpi
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

    fun captureScreen(result: MethodChannel.Result) {
        try {
            if (!isCapturing.get()) {
                result.error("NOT_CAPTURING", "Screen capture is not active", null)
                return
            }

            // Check if screen orientation changed dynamically!
            try {
                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val metrics = DisplayMetrics()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                    wm.defaultDisplay.getRealMetrics(metrics)
                } else {
                    wm.defaultDisplay.getMetrics(metrics)
                }
                val currentW = metrics.widthPixels
                val currentH = metrics.heightPixels
                if (currentW != screenWidth || currentH != screenHeight) {
                    Log.d(TAG, "Screen rotation detected! Updating dimensions: ${screenWidth}x${screenHeight} -> ${currentW}x${currentH}")
                    screenWidth = currentW
                    screenHeight = currentH
                    frameStabilizer = createFrameStabilizer()
                    setupVirtualDisplay()
                }
            } catch (rotationEx: Exception) {
                Log.e(TAG, "Error checking screen rotation in captureScreen: ${rotationEx.message}", rotationEx)
            }
           
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

    private fun cleanup() {
        try {
            Log.d(TAG, "Starting cleanup")
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
            synchronized(localImageReader) {
                try {
                    Log.d(TAG, "Attempting to close ImageReader")
                    
                    // Remove listener to prevent new callbacks
                    localImageReader.setOnImageAvailableListener(null, null)
                    
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

    private fun createImageAvailableListener(): ImageReader.OnImageAvailableListener {
        return ImageReader.OnImageAvailableListener { reader ->
            try {
                frameCount.incrementAndGet()
                // Log.d(TAG, "onImageAvailable called, frame #${frameCount.get()}")
                        
                // Synchronized using the specific reader instance
                synchronized(reader) {
                    val image = reader.acquireLatestImage()
                    if (image != null) {
                        val width = image.width
                        val height = image.height
                        // Log.d(TAG, "Captured image dimensions: ${width}x${height}")
                        // saveImagePreview(image, width, height, currentRotation)

                        // val dominantColor = image.extractDominantColor()
                        // Log.d(TAG, "Captured image dominant color: ${String.format("#%06X", 0xFFFFFF and dominantColor)}")

                        val bytes = imageToBytes(image)
                        if (bytes != null) {
                            val currentTime = System.currentTimeMillis()
                            // Pass a callback to process the stable frame
                            frameStabilizer.onNewFrame(bytes, currentTime) { stableFrame ->
                                // Remove old frames if queue is too large
                                while (imageQueue.size >= MAX_QUEUE_SIZE) {
                                    imageQueue.removeFirst()
                                }
                                imageQueue.addLast(CapturedFrame(stableFrame, currentTime, width, height))
                                Log.d(TAG, "New frame queued, queue size: ${imageQueue.size}")
                            }
                        } else {
                            Log.e(TAG, "Failed to convert image to bytes")
                        }
                        image.close()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error in image available listener", e)
            }
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

    fun imageToBytes(image: Image): ByteArray? {
        try {
            val width = image.width
            val height = image.height
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride

            // 1. Read entire buffer to a fast local array to eliminate JNI crossing overhead
            val bufferBytes = ByteArray(buffer.capacity())
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
