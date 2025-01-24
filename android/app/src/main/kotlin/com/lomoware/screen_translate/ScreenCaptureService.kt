package com.lomoware.screen_translate

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.PixelFormat
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
import android.view.WindowManager
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.ConcurrentLinkedDeque
import java.util.Timer
import java.util.TimerTask
import kotlin.math.abs

class FrameStabilizer(
    private var screenWidth: Int, 
    private var screenHeight: Int
) {
    private var lastFrame: ByteArray? = null
    private var lastFrameTime = 0L
    private var stabilizationTimer: Timer? = null
    private val stabilizationDelay = 1000L // ms to wait before translating
    private val mainHandler = Handler(Looper.getMainLooper())
    private var lastImageHash: Long = 0
    private var consecutiveScrollFrames = 0
    private val MAX_CONSECUTIVE_SCROLL_FRAMES = 1
    private val scrollDetectionThreshold = 0.05

    fun detectScrolling(currentFrame: ByteArray): Boolean {
        lastFrame?.let { previous ->
            if (previous.size == currentFrame.size) {
                val pixelDifference = computePixelDifference(previous, currentFrame)
                
                if (pixelDifference > scrollDetectionThreshold) {
                    consecutiveScrollFrames++
                    
                    if (consecutiveScrollFrames >= MAX_CONSECUTIVE_SCROLL_FRAMES) {
                        Log.d("FrameStabilizer", "Scrolling detected: $pixelDifference")
                        return true
                    }
                } else {
                    consecutiveScrollFrames = 0
                }
            }
        }
        
        lastFrame = currentFrame.clone()
        return false
    }

    private fun computePixelDifference(frame1: ByteArray, frame2: ByteArray): Double {
        var differentPixels = 0
        val totalPixels = frame1.size / 4 // Assuming RGBA

        for (i in frame1.indices step 4) {
            // Compare color channels, ignore alpha
            val isDifferent = (0..2).any { channel -> 
                abs(frame1[i + channel].toInt() - frame2[i + channel].toInt()) > 20 
            }
            
            if (isDifferent) differentPixels++
        }

        return differentPixels.toDouble() / totalPixels
    }

    // Method to update screen dimensions on orientation change
    fun updateScreenDimensions(newWidth: Int, newHeight: Int) {
        Log.d("FrameStabilizer", "Screen dimensions updated: $newWidth x $newHeight")
        screenWidth = newWidth
        screenHeight = newHeight
        // Reset last hash to force processing of next frame
        lastImageHash = 0
    }

    private fun computeImageHash(bytes: ByteArray): Long {
        // Sample pixels from different regions of the image
        val sampleSize = 16
        
        var hash: Long = 0
        for (y in 0 until screenHeight step (screenHeight / sampleSize)) {
            for (x in 0 until screenWidth step (screenWidth / sampleSize)) {
                val index = (y * screenWidth + x) * 4  // RGBA
                if (index + 3 < bytes.size) {
                    hash = 31 * hash + bytes[index].toLong()  // Use alpha or a color channel
                }
            }
        }
        return hash
    }

    fun onNewFrame(currentFrame: ByteArray, currentTime: Long, onStable: (ByteArray) -> Unit) {
        // Compute hash of current frame
        val currentImageHash = computeImageHash(currentFrame)

        // Always proceed on first frame or after screen rotation
        val shouldProcess = currentImageHash != lastImageHash

        if (shouldProcess) {
            Log.d("FrameStabilizer", "Processing frame, last hash: $lastImageHash, current hash: $currentImageHash")
            // Cancel previous timer
            stabilizationTimer?.cancel()

            // Always update last frame
            lastFrame = currentFrame
            lastFrameTime = currentTime
            lastImageHash = currentImageHash

            // Start a new timer
            stabilizationTimer = Timer().apply {
                schedule(object : TimerTask() {
                    override fun run() {
                        synchronized(this@FrameStabilizer) {
                            // Check if no new frame has arrived since scheduling this timer
                            if (currentTime == lastFrameTime) {
                                lastFrame?.let { stableFrame ->
                                    // Post to main handler to ensure thread safety
                                    mainHandler.post {
                                        Log.d("FrameStabilizer", "Frame stabilized after $stabilizationDelay ms")
                                        onStable(stableFrame)
                                        lastFrame = null
                                    }
                                }
                            }
                        }
                    }
                }, stabilizationDelay)
            }
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
    private val imageQueue = ConcurrentLinkedDeque<Pair<ByteArray, Long>>() // Pair of bytes and timestamp
    private val handlerThread = HandlerThread("ImageReaderThread").apply { start() }
    private val imageReaderHandler = Handler(handlerThread.looper)
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var frameStabilizer: FrameStabilizer

    // Add a broadcast receiver to handle configuration changes
    private val configurationChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_CONFIGURATION_CHANGED -> {
                    Log.d(TAG, "Configuration changed broadcast received")
                    
                    val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                    val display = windowManager.defaultDisplay
                    val displayMetrics = DisplayMetrics()
                    display.getMetrics(displayMetrics)

                    val currentConfiguration = context.resources.configuration
                    
                    Log.d(TAG, "Current Configuration:")
                    Log.d(TAG, "Orientation: ${currentConfiguration.orientation}")
                    Log.d(TAG, "Screen Width (dp): ${currentConfiguration.screenWidthDp}")
                    Log.d(TAG, "Screen Height (dp): ${currentConfiguration.screenHeightDp}")
                    Log.d(TAG, "Screen Layout: ${currentConfiguration.screenLayout}")
                    
                    Log.d(TAG, "Display Metrics:")
                    Log.d(TAG, "Width (pixels): ${displayMetrics.widthPixels}")
                    Log.d(TAG, "Height (pixels): ${displayMetrics.heightPixels}")
                    Log.d(TAG, "Density: ${displayMetrics.density}")

                    // Trigger virtual display restart with new dimensions
                    handleScreenOrientationChange(
                        displayMetrics.widthPixels, 
                        displayMetrics.heightPixels
                    )
                }
            }
        }
    }

    // Method to register configuration change listener
    private fun registerConfigurationChangeListener() {
        try {
            val intentFilter = IntentFilter(Intent.ACTION_CONFIGURATION_CHANGED)
            context.registerReceiver(configurationChangeReceiver, intentFilter)
            Log.d(TAG, "Configuration change listener registered")
        } catch (e: Exception) {
            Log.e(TAG, "Error registering configuration change listener", e)
        }
    }

    // Method to unregister configuration change listener
    private fun unregisterConfigurationChangeListener() {
        try {
            context.unregisterReceiver(configurationChangeReceiver)
            Log.d(TAG, "Configuration change listener unregistered")
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering configuration change listener", e)
        }
    }

    init {
        val metrics = context.resources.displayMetrics
        screenWidth = metrics.widthPixels
        screenHeight = metrics.heightPixels
        screenDensity = metrics.densityDpi
        Log.d(TAG, "Screen metrics: $screenWidth x $screenHeight @ $screenDensity")

        frameStabilizer = FrameStabilizer(screenWidth, screenHeight)
    }

    fun startProjection(resultCode: Int, data: Intent, result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Starting projection with result code: $resultCode")
            cleanup() // Cleanup any existing resources

            val serviceIntent = Intent(context, ForegroundService::class.java)
            context.startForegroundService(serviceIntent)
            
            mainHandler.postDelayed({
                try {
                    Log.d(TAG, "Creating MediaProjection...")
                    val mpManager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    mediaProjection = mpManager.getMediaProjection(resultCode, data).apply {
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
                        return@postDelayed
                    }
                    
                    Log.d(TAG, "MediaProjection created successfully")
                    setupVirtualDisplay()
                    isCapturing.set(true) // Set capturing to true when projection starts
                    result.success(true)
                    
                    // Register configuration change listener
                    registerConfigurationChangeListener()
                } catch (e: Exception) {
                    Log.e(TAG, "Error creating MediaProjection", e)
                    result.error("PROJECTION_ERROR", "Error creating MediaProjection: ${e.message}", null)
                    cleanup()
                }
            }, 500)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting projection", e)
            result.error("PROJECTION_ERROR", "Error starting projection: ${e.message}", null)
            cleanup()
        }
    }

    fun stopProjection() {
        Log.d(TAG, "Stopping projection")
        try {
            cleanup()
            isCapturing.set(false) // Set capturing to false when projection stops
            context.stopService(Intent(context, ForegroundService::class.java))
            
            // Unregister configuration change listener
            unregisterConfigurationChangeListener()
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
           
            val frame = imageQueue.pollLast() // Atomically peek and remove
            if (frame != null) {
                val (bytes, timestamp) = frame
                val age = System.currentTimeMillis() - timestamp
                
                if (age <= MAX_FRAME_AGE) {
                    Log.d(TAG, "Sending image bytes: ${bytes.size}, frame age: ${age}ms")
                    result.success(mapOf(
                        "bytes" to bytes,
                        "width" to screenWidth,
                        "height" to screenHeight
                    ))
                } else {
                    Log.w(TAG, "Frame too old: ${age}ms")
                    result.error("FRAME_TOO_OLD", "Captured frame is too old", null)
                } 
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

    private fun restartVirtualDisplay(newWidth: Int, newHeight: Int) {
        Log.d(TAG, "Restarting virtual display with new dimensions: ${newWidth}x${newHeight}")

        imageQueue.clear()
        frameCount.set(0)

        // Update frame stabilizer with new dimensions
        frameStabilizer.updateScreenDimensions(newWidth, newHeight)
        
        // Update local screen dimensions
        screenWidth = newWidth
        screenHeight = newHeight

        setupVirtualDisplay()
        
        Log.d(TAG, "Virtual display restarted successfully")
    }

    fun handleScreenOrientationChange(newWidth: Int, newHeight: Int) {
        // Only restart if dimensions have actually changed
        if (newWidth != screenWidth || newHeight != screenHeight) {
            Log.d(TAG, "Screen orientation change detected")
            Log.d(TAG, "Old dimensions: ${screenWidth}x${screenHeight}")
            Log.d(TAG, "New dimensions: ${newWidth}x${newHeight}")
            
            restartVirtualDisplay(newWidth, newHeight)
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
                Log.d(TAG, "onImageAvailable called, frame #${frameCount.get()}")

                // Synchronized using the specific reader instance
                synchronized(reader) {
                    val image = reader.acquireLatestImage()
                    if (image != null) {
                        val bytes = imageToBytes(image)
                        if (bytes != null) {
                            if (frameStabilizer.detectScrolling(bytes)) {
                                // Clear translation overlay
                                val intent = Intent(context, OverlayService::class.java)
                                intent.action = "hideAll"
                                context.startService(intent)
                            }
                            val currentTime = System.currentTimeMillis()
                            // Pass a callback to process the stable frame
                            frameStabilizer.onNewFrame(bytes, currentTime) { stableFrame ->
                                // Remove old frames if queue is too large
                                while (imageQueue.size >= MAX_QUEUE_SIZE) {
                                    imageQueue.removeFirst()
                                }
                                imageQueue.addLast(Pair(stableFrame, currentTime))
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

    fun imageToBytes(image: Image): ByteArray? {
        try {
            val width = image.width
            val height = image.height
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride
            val rowPadding = rowStride - pixelStride * width

            Log.d(TAG, "Converting image: ${width}x${height}")
            Log.d(TAG, "Buffer capacity: ${buffer.capacity()}")
            Log.d(TAG, "PixelStride: $pixelStride")
            Log.d(TAG, "RowStride: $rowStride")
            Log.d(TAG, "RowPadding: $rowPadding")

            // NV21 format size: height * width + 2 * (height/2 * width/2)
            val nv21Size = width * height + 2 * ((height + 1) / 2) * ((width + 1) / 2)
            val nv21Bytes = ByteArray(nv21Size)
            
            // Fill Y plane
            var yPos = 0
            for (row in 0 until height) {
                for (col in 0 until width) {
                    val pos = row * rowStride + col * pixelStride
                    buffer.position(pos)
                    
                    // Read RGBA values
                    val r = buffer.get().toInt() and 0xFF
                    val g = buffer.get().toInt() and 0xFF
                    val b = buffer.get().toInt() and 0xFF
                    buffer.get() // Skip alpha
                    
                    // Convert to Y
                    val y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                    nv21Bytes[yPos++] = y.toByte()
                }
            }
            
            // Fill UV plane
            val uvPos = width * height
            var pos = uvPos
            for (row in 0 until height step 2) {
                for (col in 0 until width step 2) {
                    val rgbaPos = row * rowStride + col * pixelStride
                    buffer.position(rgbaPos)
                    
                    // Average 2x2 block
                    var avgR = 0
                    var avgG = 0
                    var avgB = 0
                    
                    // Top left pixel
                    var r = buffer.get().toInt() and 0xFF
                    var g = buffer.get().toInt() and 0xFF
                    var b = buffer.get().toInt() and 0xFF
                    buffer.get() // Skip alpha
                    avgR += r
                    avgG += g
                    avgB += b
                    
                    // Top right pixel (if within bounds)
                    if (col + 1 < width) {
                        buffer.position(rgbaPos + pixelStride * 1)
                        r = buffer.get().toInt() and 0xFF
                        g = buffer.get().toInt() and 0xFF
                        b = buffer.get().toInt() and 0xFF
                        avgR += r
                        avgG += g
                        avgB += b
                    }
                    
                    // Bottom left pixel (if within bounds)
                    if (row + 1 < height) {
                        buffer.position(rgbaPos + rowStride)
                        r = buffer.get().toInt() and 0xFF
                        g = buffer.get().toInt() and 0xFF
                        b = buffer.get().toInt() and 0xFF
                        avgR += r
                        avgG += g
                        avgB += b
                    }
                    
                    // Bottom right pixel (if within bounds)
                    if (row + 1 < height && col + 1 < width) {
                        buffer.position(rgbaPos + rowStride + pixelStride)
                        r = buffer.get().toInt() and 0xFF
                        g = buffer.get().toInt() and 0xFF
                        b = buffer.get().toInt() and 0xFF
                        avgR += r
                        avgG += g
                        avgB += b
                    }
                    
                    avgR = avgR shr 2
                    avgG = avgG shr 2
                    avgB = avgB shr 2
                    
                    // Convert to V and U
                    val v = (128 + (112 * avgR - 94 * avgG - 18 * avgB + 128) shr 8).toByte()
                    val u = (128 + (-38 * avgR - 74 * avgG + 112 * avgB + 128) shr 8).toByte()
                    
                    nv21Bytes[pos++] = v
                    nv21Bytes[pos++] = u
                }
            }

            return nv21Bytes
        } catch (e: Exception) {
            Log.e(TAG, "Error converting image to bytes", e)
            return null
        }
    }
}
