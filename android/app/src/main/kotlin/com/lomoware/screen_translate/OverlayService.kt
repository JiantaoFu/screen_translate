package com.lomoware.screen_translate

import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Handler
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import android.content.Context
import android.util.TypedValue
import androidx.appcompat.widget.AppCompatTextView
import androidx.core.content.ContextCompat
import android.widget.LinearLayout
import android.view.ContextThemeWrapper
import android.util.Log
import android.os.Build
import android.app.Activity
import android.net.Uri
import android.view.Surface
import com.lomoware.screen_translate.LocalizationHelper
import android.util.DisplayMetrics

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private val overlayViews = mutableMapOf<Int, View>()
    private val overlayParams = mutableMapOf<Int, WindowManager.LayoutParams>()
    private val originalPositions = mutableMapOf<Int, Pair<Int, Int>>()  // Store original x,y positions
    private var controlButton: ImageView? = null
    private var tooltipView: TextView? = null
    private var displayMode = DisplayMode.TRANSLATION_ON
    private var lastTouchX = 0f
    private var lastTouchY = 0f
    private var originalX = 0
    private var originalY = 0
    private var tooltipHideRunnable: Runnable? = null
    private val handler = Handler()
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var oldScreenWidth: Int = 0
    private var oldScreenHeight: Int = 0
    private var screenDensity: Int = 0
    private var currentRotation: Int = Surface.ROTATION_0
    private var TAG = "OverlayService"

    companion object {
        // Use @Volatile to ensure visibility across threads
        @Volatile
        private var instance: OverlayService? = null

        // Thread-safe getInstance method using double-checked locking
        fun getInstance(): OverlayService? {
            // First check without locking
            if (instance == null) {
                synchronized(this) {
                    // Second check with locking
                    if (instance == null) {
                        return null
                    }
                }
            }
            return instance
        }

        // Thread-safe setInstance method
        fun setInstance(service: OverlayService) {
            synchronized(this) {
                instance = service
            }
        }

        // Thread-safe clearInstance method
        fun clearInstance() {
            synchronized(this) {
                instance = null
            }
        }

        fun hasOverlayPermission(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(context)
            } else {
                // For older Android versions, always return true
                true
            }
        }
    
        fun requestOverlayPermission(activity: Activity) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !hasOverlayPermission(activity)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${activity.packageName}")
                )
                activity.startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
            }
        }
    
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 5469
    }

    private lateinit var displayMetrics: DisplayMetrics
    private var windowManagerInstance: WindowManager? = null

    override fun onCreate() {
        super.onCreate()
        
        // Initialize display metrics in onCreate
        displayMetrics = DisplayMetrics()
        windowManagerInstance = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        
        try {
            // Try to get metrics from WindowManager
            windowManagerInstance?.defaultDisplay?.getMetrics(displayMetrics)
            
            screenWidth = displayMetrics.widthPixels
            screenHeight = displayMetrics.heightPixels
            screenDensity = displayMetrics.densityDpi
        } catch (e: Exception) {
            // Fallback to resources if WindowManager fails
            Log.e(TAG, "Failed to get metrics from WindowManager", e)
            
            val resources = applicationContext?.resources
            if (resources != null) {
                screenWidth = resources.displayMetrics.widthPixels
                screenHeight = resources.displayMetrics.heightPixels
                screenDensity = resources.displayMetrics.densityDpi
            } else {
                Log.e(TAG, "Both WindowManager and resources metric retrieval failed")
                // Set some default or safe values
                screenWidth = 1080  // Common Full HD width
                screenHeight = 1920 // Common Full HD height
                screenDensity = 480 // Common high-density DPI
            }
        }
        oldScreenWidth = screenWidth
        oldScreenHeight = screenHeight
        
        Log.d(TAG, "Screen metrics: $screenWidth x $screenHeight @ $screenDensity")
        setInstance(this)
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createControlButton()
    }

    enum class DisplayMode(val icon: Int, val labelKey: String) {
        TRANSLATION_ON(R.drawable.ic_translate_mode, "translation_mode"),
        ORIGINAL_ONLY(R.drawable.ic_original_mode, "original_text_mode");
        
        fun getLocalizedLabel(context: Context): String {
            return LocalizationHelper.getLocalizedString(context, labelKey)
        }
    }

    private fun updateModeIcon() {
        controlButton?.setImageResource(displayMode.icon)
    }

    private fun showTooltip(text: String) {
        // Remove existing tooltip if any
        tooltipView?.let {
            windowManager?.removeView(it)
            tooltipView = null
        }

        // Create new tooltip
        val newTooltip = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 12f
            background = ContextCompat.getDrawable(context, R.drawable.tooltip_background)
            setPadding(8.dpToPx(), 4.dpToPx(), 8.dpToPx(), 4.dpToPx())
            this.text = text
            elevation = 8f  // Match button elevation
        }
        
        tooltipView = newTooltip
        
        // Measure the view
        newTooltip.measure(
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        )

        // Use TYPE_APPLICATION_OVERLAY for overlay windows on newer Android versions
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else 
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.START or Gravity.TOP
        }

        val buttonParams = controlButton?.layoutParams as? WindowManager.LayoutParams
        if (buttonParams != null) {
            val screenWidth = resources.displayMetrics.widthPixels
            val buttonSize = 48.dpToPx()
            
            // Position directly below button with minimal gap
            params.y = buttonParams.y + buttonSize + 1.dpToPx()
            
            // Center horizontally with button
            params.x = buttonParams.x + (buttonSize - newTooltip.measuredWidth) / 2
            
            // Keep tooltip on screen
            if (params.x < 4.dpToPx()) {
                params.x = 4.dpToPx()
            } else if (params.x + newTooltip.measuredWidth > screenWidth - 4.dpToPx()) {
                params.x = screenWidth - newTooltip.measuredWidth - 4.dpToPx()
            }
        }

        windowManager?.addView(newTooltip, params)
        
        // Quick pop animation
        newTooltip.alpha = 0f
        newTooltip.scaleX = 0.9f
        newTooltip.scaleY = 0.9f
        newTooltip.animate()
            .alpha(1f)
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(150)
            .start()

        // Remove previous hide runnable
        tooltipHideRunnable?.let { handler.removeCallbacks(it) }

        // Schedule hide
        tooltipHideRunnable = Runnable {
            val currentTooltip = tooltipView
            if (currentTooltip != null) {
                currentTooltip.animate()
                    .alpha(0f)
                    .scaleX(0.9f)
                    .scaleY(0.9f)
                    .setDuration(150)
                    .withEndAction {
                        if (currentTooltip != null && currentTooltip.isAttachedToWindow) {
                            try {
                                windowManager?.removeView(currentTooltip)
                                if (tooltipView == currentTooltip) {
                                    tooltipView = null
                                }
                            } catch (e: IllegalArgumentException) {
                                // Log the error or handle it gracefully
                                Log.e("OverlayService", "Error removing tooltip view", e)
                            }
                        }
                    }
                    .start()
            }
        }.also {
            handler.postDelayed(it, 2000)
        }
    }

    private fun switchMode() {
        displayMode = when (displayMode) {
            DisplayMode.TRANSLATION_ON -> DisplayMode.ORIGINAL_ONLY
            DisplayMode.ORIGINAL_ONLY -> DisplayMode.TRANSLATION_ON
        }
        
        controlButton?.apply {
            animate()
                .rotationBy(360f)
                .setDuration(300)
                .withEndAction { 
                    updateModeIcon()
                    showTooltip(displayMode.getLocalizedLabel(context))
                }
                .start()
        }
        
        updateOverlayVisibility()
    }

    private fun createControlButton() {
        controlButton = ImageView(this).apply {
            setImageResource(displayMode.icon)
            background = ContextCompat.getDrawable(context, R.drawable.floating_button_bg)
            elevation = 8f
            alpha = 0.95f
            
            val size = 48.dpToPx()
            
            val padding = (size * 0.25f).toInt()
            setPadding(padding, padding, padding, padding)

            setOnTouchListener { view, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        view.animate().scaleX(0.9f).scaleY(0.9f).setDuration(100).start()
                        lastTouchX = event.rawX
                        lastTouchY = event.rawY
                        originalX = (view.layoutParams as WindowManager.LayoutParams).x
                        originalY = (view.layoutParams as WindowManager.LayoutParams).y
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        view.animate().scaleX(1f).scaleY(1f).setDuration(100).start()
                        val moved = Math.abs(event.rawX - lastTouchX) > 5 || 
                                  Math.abs(event.rawY - lastTouchY) > 5
                        if (!moved) {
                            switchMode()
                        }
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val params = view.layoutParams as WindowManager.LayoutParams
                        params.x = (originalX + (event.rawX - lastTouchX)).toInt()
                        params.y = (originalY + (event.rawY - lastTouchY)).toInt()
                        windowManager?.updateViewLayout(view, params)
                        true
                    }
                    else -> false
                }
            }
        }

        val params = WindowManager.LayoutParams(
            48.dpToPx(),
            48.dpToPx(),
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = resources.displayMetrics.widthPixels - 64.dpToPx()
            y = resources.displayMetrics.heightPixels / 3
        }

        windowManager?.addView(controlButton, params)
        showTooltip(displayMode.getLocalizedLabel(this))
    }

    private fun Int.dpToPx(): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            this.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun showOverlay(id: Int, text: String, x: Float = -1f, y: Float = -1f, width: Float = -1f, height: Float = -1f) {
        if (!hasOverlayPermission(this)) {
            print("Cannot show overlay: permission not granted")
            return
        }

        if (overlayViews.containsKey(id)) {
            try {
                val existingView = overlayViews[id]
                windowManager?.removeView(existingView)
                overlayViews.remove(id)
                overlayParams.remove(id)
                originalPositions.remove(id)
            } catch (e: Exception) {
                print("Error removing existing overlay: ${e.message}")
            }
        }

        val (transformedX, transformedY) = if (x != -1f && y != -1f) {
            reverseAspectRatioCoordinates(x, y, oldScreenWidth, oldScreenHeight, screenWidth, screenHeight)
        } else {
            Pair(x, y)
        }

        Log.d(TAG, "Showing overlay at transformed coordinates: ($transformedX, $transformedY)")

        val themedContext = ContextThemeWrapper(this, R.style.Theme_AppCompat_Light)
        val overlayView = AppCompatTextView(themedContext).apply {
            setText(text)
            setTextColor(android.graphics.Color.WHITE)
            setBackgroundColor(android.graphics.Color.argb(220, 0, 0, 0))
            setPadding(2, 1, 2, 1)

            setSingleLine(false)

            setAutoSizeTextTypeUniformWithConfiguration(
                6,
                16,
                1,
                TypedValue.COMPLEX_UNIT_SP
            )
        }

        val layoutParams = createLayoutParams(transformedX, transformedY, width, height)   
        originalPositions[id] = Pair(layoutParams.x, layoutParams.y)
        overlayViews[id] = overlayView
        overlayParams[id] = layoutParams

        var initialX = 0f
        var initialY = 0f
        var initialTouchX = 0f
        var initialTouchY = 0f
    
        overlayView.setOnTouchListener { v, event ->
            Log.d("DragHandle", "Touch event: ${event.action}")
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    Log.d("DragHandle", "Initial position: x=${event.rawX}, y=${event.rawY}")// Save the initial touch and position
                    initialX = layoutParams.x.toFloat()
                    initialY = layoutParams.y.toFloat()
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    Log.d("DragHandle", "Moving: x=${event.rawX}, y=${event.rawY}")
                    layoutParams.x = (initialX + (event.rawX - initialTouchX)).toInt()
                    layoutParams.y = (initialY + (event.rawY - initialTouchY)).toInt()
                    windowManager?.updateViewLayout(overlayView, layoutParams)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    Log.d("DragHandle", "Touch ended")
                    true
                }
                else -> false
            }
        }

        windowManager?.addView(overlayView, layoutParams)
        
        updateOverlayVisibility(id)
    }

    private fun updateOverlayVisibility(specificId: Int? = null) {
        val idsToUpdate = specificId?.let { listOf(it) } ?: overlayViews.keys.toList()
        
        idsToUpdate.forEach { id ->
            val view = overlayViews[id] ?: return@forEach
            val params = overlayParams[id] ?: return@forEach
            val (originalX, originalY) = originalPositions[id] ?: return@forEach
            
            when (displayMode) {
                DisplayMode.TRANSLATION_ON -> {
                    view.visibility = View.VISIBLE
                    params.x = originalX
                    params.y = originalY
                    windowManager?.updateViewLayout(view, params)
                }
                DisplayMode.ORIGINAL_ONLY -> {
                    view.visibility = View.GONE
                    params.x = originalX
                    params.y = originalY
                    windowManager?.updateViewLayout(view, params)
                }
            }
        }
    }

    private fun createLayoutParams(x: Float, y: Float, width: Float, height: Float): WindowManager.LayoutParams {
        return WindowManager.LayoutParams(
            if (width > 0) (width * 1.1f).toInt() else WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            
            if (x >= 0 && y >= 0) {
                this.x = x.toInt()
                this.y = y.toInt()
            }
        }
    }

    private fun hideAllOverlays() {
        overlayViews.forEach { (_, view) ->
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                print("Error removing view: ${e.message}")
            }
        }
        overlayViews.clear()
        overlayParams.clear()
        originalPositions.clear()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "show" -> {
                val text = intent.getStringExtra("text")
                val x = intent.getFloatExtra("x", -1f)
                val y = intent.getFloatExtra("y", -1f)
                val width = intent.getFloatExtra("width", -1f)
                val height = intent.getFloatExtra("height", -1f)
                val id = intent.getIntExtra("id", -1)
                if (text != null && id >= 0) {
                    showOverlay(id, text, x, y, width, height)
                }
            }
            "hideAll" -> {
                hideAllOverlays()
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        hideAllOverlays()
        controlButton?.let { windowManager?.removeView(it) }
        tooltipView?.let { windowManager?.removeView(it) }
        tooltipHideRunnable?.let { handler.removeCallbacks(it) }
        originalPositions.clear()
        windowManager = null
    }


    fun reverseAspectRatioCoordinates(x: Float, y: Float, originalWidth: Int, originalHeight: Int, newWidth: Int, newHeight: Int): Pair<Float, Float> {
        // Log input parameters
        Log.d(TAG, "Reverse Aspect Ratio Coordinates Input:")
        Log.d(TAG, "Original Coordinates: (x: $x, y: $y)")
        Log.d(TAG, "Original Dimensions: ${originalWidth}x$originalHeight")
        Log.d(TAG, "New Dimensions: ${newWidth}x$newHeight")

        // Calculate aspect ratios
        val originalAspectRatio = originalWidth.toFloat() / originalHeight
        val newAspectRatio = newWidth.toFloat() / newHeight

        Log.d(TAG, "Original Aspect Ratio: $originalAspectRatio")
        Log.d(TAG, "New Aspect Ratio: $newAspectRatio")

        // Adjust coordinates based on aspect ratio
        val adjustedX: Float
        val adjustedY: Float

        if (originalAspectRatio < newAspectRatio) {
            // New width is the limiting factor
            val scaleFactor =  originalWidth.toFloat() / newWidth
            adjustedX = x / scaleFactor
            adjustedY = (y - (originalHeight - newHeight * scaleFactor) / 2) / scaleFactor
            
            Log.d(TAG, "Width is limiting factor")
            Log.d(TAG, "Scale Factor: $scaleFactor")
        } else {
            // no need b/c no scaling in this case
            adjustedX = x
            adjustedY = y
        }

        // Log output coordinates
        Log.d(TAG, "Adjusted Coordinates: (x: $adjustedX, y: $adjustedY)")

        return Pair(adjustedX, adjustedY)
    }

    // Direct method to update display information
    fun updateDisplayInfo(
        widthPixels: Int, 
        heightPixels: Int, 
        density: Float, 
        rotation: Int
    ) {
        Log.d(TAG, "Updating Display Info:")
        Log.d(TAG, "Width Pixels: $widthPixels")
        Log.d(TAG, "Height Pixels: $heightPixels")
        Log.d(TAG, "Density: $density")
        Log.d(TAG, "Rotation: $rotation")
        Log.d(TAG, "Rotation Description: ${when(rotation) {
            Surface.ROTATION_0 -> "Portrait"
            Surface.ROTATION_90 -> "Landscape (90°)"
            Surface.ROTATION_180 -> "Portrait (180°)"
            Surface.ROTATION_270 -> "Landscape (270°)"
            else -> "Unknown"
        }}")

        // Update rotation
        currentRotation = rotation

        // Only update dimensions if they've changed
        if (widthPixels != screenWidth || heightPixels != screenHeight || density.toInt() != screenDensity) {
            Log.d(TAG, "Screen orientation change detected")
            Log.d(TAG, "Old dimensions: ${screenWidth}x${screenHeight}, density: $screenDensity")
            Log.d(TAG, "New dimensions: ${widthPixels}x${heightPixels}, density: ${density.toInt()}")

            // Update local screen dimensions
            oldScreenWidth = screenWidth
            oldScreenHeight = screenHeight
            screenWidth = widthPixels
            screenHeight = heightPixels
            screenDensity = density.toInt()
        }
    }
}
