package com.example.screen_translate

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

    enum class DisplayMode(val icon: Int, val description: String) {
        TRANSLATION_ON(R.drawable.ic_translate_mode, "Translation Mode"),
        ORIGINAL_ONLY(R.drawable.ic_original_mode, "Original Text Mode"),
        SIDE_BY_SIDE(R.drawable.ic_side_by_side_mode, "Side by Side Mode")
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

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
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
                        windowManager?.removeView(currentTooltip)
                        if (tooltipView == currentTooltip) {
                            tooltipView = null
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
            DisplayMode.TRANSLATION_ON -> DisplayMode.SIDE_BY_SIDE
            DisplayMode.SIDE_BY_SIDE -> DisplayMode.ORIGINAL_ONLY
            DisplayMode.ORIGINAL_ONLY -> DisplayMode.TRANSLATION_ON
        }
        
        controlButton?.apply {
            animate()
                .rotationBy(360f)
                .setDuration(300)
                .withEndAction { 
                    updateModeIcon()
                    showTooltip(displayMode.description)
                }
                .start()
        }
        
        updateOverlayVisibility()
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createControlButton()
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
        showTooltip(displayMode.description)
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


        val layoutParams = createLayoutParams(x, y, width, height)   
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
                DisplayMode.SIDE_BY_SIDE -> {
                    view.visibility = View.VISIBLE
                    params.x = originalX + view.width + 10.dpToPx()
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

    companion object {
        fun hasOverlayPermission(context: Context): Boolean {
            return Settings.canDrawOverlays(context)
        }

        fun requestOverlayPermission(context: Context) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                android.net.Uri.parse("package:${context.packageName}")
            )
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        }
    }
}
