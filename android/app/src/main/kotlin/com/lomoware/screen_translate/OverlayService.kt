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
import android.view.GestureDetector
import android.widget.ScrollView
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
import android.util.DisplayMetrics
import android.graphics.drawable.GradientDrawable
import android.widget.FrameLayout
import android.widget.ImageButton
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private val overlayViews = mutableMapOf<Int, View>()
    private val overlayParams = mutableMapOf<Int, WindowManager.LayoutParams>()
    private val originalPositions = mutableMapOf<Int, Pair<Int, Int>>()  // Store original x,y positions
    private var controlButton: ImageView? = null
    private var translateButton: ImageButton? = null
    private var translateButtonParams: WindowManager.LayoutParams? = null
    private var tooltipView: TextView? = null
    private var expandedTextView: View? = null
    private var displayMode = DisplayMode.AUTO
    private var lastTouchX = 0f
    private var lastTouchY = 0f
    private var originalX = 0
    private var originalY = 0
    private var tooltipHideRunnable: Runnable? = null
    private val handler = Handler()
    private var isTouchingControlButtons = false
    private var bringToFrontPending = false
    private val bringToFrontRunnable = Runnable {
        if (isTouchingControlButtons) {
            // Re-adding a window mid-gesture cancels the drag and snaps the
            // button back — wait until the finger lifts.
            bringToFrontPending = true
        } else {
            bringControlButtonsToFrontNow()
        }
    }
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var oldScreenWidth: Int = 0
    private var oldScreenHeight: Int = 0
    private var screenDensity: Int = 0
    private var currentRotation: Int = Surface.ROTATION_0
    private var TAG = "OverlayService"
    private lateinit var methodChannel: MethodChannel
    @Volatile
    private var isStopped = false

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

        // Android refuses to add more than ~30 TYPE_APPLICATION_OVERLAY
        // windows per app ("excessive same type windows" BadTokenException,
        // which crashed dense manga/game pages). The control button,
        // translate button, tooltip and expanded-text dialog need room too.
        private const val MAX_TEXT_OVERLAYS = 24

        // See showOverlay(): must stay translucent enough for
        // FrameStabilizer's under-box change detection.
        private const val BOX_BACKGROUND_ALPHA = 250
    }

    private lateinit var displayMetrics: DisplayMetrics
    private var windowManagerInstance: WindowManager? = null

    // When the screen rotates (e.g. a landscape game comes to the front),
    // keep the floating buttons at the same relative spot. Positions are
    // absolute pixels, so the default right-edge spot in portrait landed in
    // the middle of a landscape screen — on top of the game's dialogue.
    override fun onConfigurationChanged(newConfig: android.content.res.Configuration) {
        super.onConfigurationChanged(newConfig)
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager?.defaultDisplay?.getRealMetrics(metrics)
        val newW = metrics.widthPixels
        val newH = metrics.heightPixels
        val oldW = buttonLayoutWidth
        val oldH = buttonLayoutHeight
        buttonLayoutWidth = newW
        buttonLayoutHeight = newH
        if (oldW <= 0 || oldH <= 0 || (oldW == newW && oldH == newH)) return
        val button = controlButton ?: return
        val params = button.layoutParams as? WindowManager.LayoutParams ?: return
        val size = 48.dpToPx()
        params.x = (params.x * newW / oldW).coerceIn(0, maxOf(0, newW - size))
        params.y = (params.y * newH / oldH).coerceIn(0, maxOf(0, newH - size))
        try {
            windowManager?.updateViewLayout(button, params)
            updateTranslateButtonPosition(params.x, params.y)
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "Control button not attached", e)
        }
    }

    // Screen size the button positions were laid out for.
    private var buttonLayoutWidth = 0
    private var buttonLayoutHeight = 0

    override fun onCreate() {
        super.onCreate()

        // Initialize display metrics in onCreate
        displayMetrics = DisplayMetrics()
        windowManagerInstance = getSystemService(Context.WINDOW_SERVICE) as? WindowManager

        try {
            // Try to get metrics from WindowManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                windowManagerInstance?.defaultDisplay?.getRealMetrics(displayMetrics)
            } else {
                windowManagerInstance?.defaultDisplay?.getMetrics(displayMetrics)
            }

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
    }

    enum class DisplayMode(val icon: Int, val labelRes: Int) {
        AUTO(R.drawable.ic_translate_mode, R.string.mode_auto_translate),
        ORIGINAL(R.drawable.ic_original_mode, R.string.mode_original_text),
        MANUAL(R.drawable.ic_manual_translate, R.string.mode_manual_translate);

        fun getLocalizedLabel(context: Context): String = context.getString(labelRes)
    }

    private fun updateModeIcon() {
        controlButton?.setImageResource(displayMode.icon)
    }

    // removeView() throws if the view was already detached (e.g. the tooltip
    // was torn down by "stop" while its reference was still held), which
    // crashed the app the next time translation was started.
    private fun safeRemoveView(view: View?) {
        if (view == null || !view.isAttachedToWindow) return
        try {
            windowManager?.removeView(view)
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "View already detached from window manager", e)
        }
    }

    // addView() can throw BadTokenException (window limit, overlay permission
    // revoked mid-session) — losing one overlay is fine, crashing is not.
    private fun safeAddView(view: View, params: WindowManager.LayoutParams): Boolean {
        return try {
            windowManager?.addView(view, params)
            true
        } catch (e: WindowManager.BadTokenException) {
            Log.e(TAG, "Unable to add overlay window", e)
            false
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Overlay window already added", e)
            false
        }
    }

    private fun showTooltip(text: String) {
        // Remove existing tooltip if any
        safeRemoveView(tooltipView)
        tooltipView = null

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

        OverlayRegions.track(newTooltip, isControl = true)
        if (!safeAddView(newTooltip, params)) {
            tooltipView = null
            return
        }

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
                        safeRemoveView(currentTooltip)
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
            DisplayMode.AUTO -> DisplayMode.ORIGINAL
            DisplayMode.ORIGINAL -> DisplayMode.MANUAL
            DisplayMode.MANUAL -> DisplayMode.AUTO
        }

        controlButton?.apply {
            animate()
                .rotationBy(360f)
                .setDuration(300)
                .withEndAction {
                    updateModeIcon()
                    showTooltip(displayMode.getLocalizedLabel(context))
                    updateTranslateButtonVisibility()
                }
                .start()
        }

        updateOverlayVisibility()
    }

    fun getCurrentTranslationMode(): String {
        return when (displayMode) {
            DisplayMode.AUTO -> "auto"
            DisplayMode.MANUAL -> "manual"
            DisplayMode.ORIGINAL -> "original"
        }
    }

    private fun createControlButton() {
        controlButton = ImageView(this).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                setOnApplyWindowInsetsListener { _, insets ->
                    OverlayRegions.statusBarVisible =
                        insets.isVisible(android.view.WindowInsets.Type.statusBars())
                    insets
                }
            }
            setImageResource(displayMode.icon)
            background = ContextCompat.getDrawable(context, R.drawable.floating_button_bg)
            elevation = 8f
            alpha = 0.95f

            val size = 48.dpToPx()

            val padding = (size * 0.25f).toInt()
            setPadding(padding, padding, padding, padding)

            setOnTouchListener { view, event ->
                trackControlButtonTouch(event)
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

                        // Update translate button position to match
                        updateTranslateButtonPosition(params.x, params.y)
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

        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager?.defaultDisplay?.getRealMetrics(metrics)
        buttonLayoutWidth = metrics.widthPixels
        buttonLayoutHeight = metrics.heightPixels
        controlButton?.let { button ->
            OverlayRegions.track(button, isControl = true)
            if (!safeAddView(button, params)) {
                controlButton = null
                return
            }
        }
        showTooltip(displayMode.getLocalizedLabel(this))
    }

    private fun createTranslateButton() {
        translateButton = ImageButton(this).apply {
            setImageResource(R.drawable.ic_translate_mode)
            background = ContextCompat.getDrawable(context, R.drawable.floating_button_bg)
            elevation = 8f
            alpha = 0.95f

            val size = 48.dpToPx()
            val padding = (size * 0.25f).toInt()
            setPadding(padding, padding, padding, padding)

            setOnClickListener { view ->
                // Animate button press
                view.animate()
                    .scaleX(0.9f)
                    .scaleY(0.9f)
                    .setDuration(100)
                    .withEndAction {
                        view.animate()
                            .scaleX(1f)
                            .scaleY(1f)
                            .setDuration(100)
                            .start()
                    }
                    .start()

                // Trigger translation
                triggerManualTranslation()
            }

            // Custom touch handling to move with control button without switching modes
            var lastTouchX = 0f
            var lastTouchY = 0f
            var isDragging = false

            setOnTouchListener { view, event ->
                trackControlButtonTouch(event)
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        lastTouchX = event.rawX
                        lastTouchY = event.rawY
                        isDragging = false
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val deltaX = event.rawX - lastTouchX
                        val deltaY = event.rawY - lastTouchY

                        // Consider it a drag if moved more than 5 pixels
                        if (!isDragging &&
                            (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5)) {
                            isDragging = true
                        }

                        if (isDragging) {
                            // Move control button, which will automatically move translate button
                            controlButton?.let { controlBtn ->
                                val controlParams = controlBtn.layoutParams as WindowManager.LayoutParams
                                controlParams.x = (controlParams.x + deltaX).toInt()
                                controlParams.y = (controlParams.y + deltaY).toInt()
                                windowManager?.updateViewLayout(controlBtn, controlParams)
                            }

                            lastTouchX = event.rawX
                            lastTouchY = event.rawY
                        }
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        // If not dragging, treat as a normal click
                        if (!isDragging) {
                            performClick()
                        }
                        true
                    }
                    else -> false
                }
            }
        }

        translateButtonParams = WindowManager.LayoutParams(
            48.dpToPx(),
            48.dpToPx(),
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            // Position slightly offset from control button
            x = resources.displayMetrics.widthPixels - 64.dpToPx() - 48.dpToPx()
            y = resources.displayMetrics.heightPixels / 3
        }

        translateButton?.visibility = View.GONE
        translateButton?.let { button ->
            OverlayRegions.track(button, isControl = true)
            if (!safeAddView(button, translateButtonParams!!)) translateButton = null
        }
    }

    // Update method to sync translate button position with control button
    private fun updateTranslateButtonPosition(x: Int, y: Int) {
        translateButtonParams?.let { params ->
            // Adjust x position to be right next to control button
            params.x = x - 48.dpToPx()
            params.y = y
            translateButton?.let {
                windowManager?.updateViewLayout(it, params)
            }
        }
    }

    private fun updateTranslateButtonVisibility() {
        translateButton?.visibility = when (displayMode) {
            DisplayMode.MANUAL -> View.VISIBLE
            else -> View.GONE
        }
    }

    private fun triggerManualTranslation() {
        if (displayMode == DisplayMode.MANUAL) {
            Log.d(TAG, "Manually triggering translation")

            if (!::methodChannel.isInitialized) return
            // Send method call to Flutter side to request manual translation
            methodChannel.invokeMethod("requestManualTranslation", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d(TAG, "Method invocation successful")
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "Method invocation error: $errorCode, $errorMessage")
                }

                override fun notImplemented() {
                    Log.e(TAG, "Method not implemented")
                }
            })
        }
    }

    private fun Int.dpToPx(): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            this.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    // Each translated text box is added as its own TYPE_APPLICATION_OVERLAY
    // window, and newly-added windows of that type draw on top of
    // previously-added ones. The control/translate buttons are created once
    // when translation starts, so any text box added afterwards — including
    // ones the OCR happens to position near the button's corner — silently
    // draws over it, making it look like the button vanished. Re-adding the
    // buttons after every new text box keeps them on top of whatever content
    // is currently on screen.
    //
    // A single tick can add many boxes, so this is debounced to one re-add
    // after the burst instead of tearing the button windows down and
    // rebuilding them once per box.
    private fun bringControlButtonsToFront() {
        handler.removeCallbacks(bringToFrontRunnable)
        handler.postDelayed(bringToFrontRunnable, 100)
    }

    private fun trackControlButtonTouch(event: MotionEvent) {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> isTouchingControlButtons = true
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                isTouchingControlButtons = false
                if (bringToFrontPending) {
                    bringToFrontPending = false
                    bringControlButtonsToFront()
                }
            }
        }
    }

    private fun bringControlButtonsToFrontNow() {
        controlButton?.let { button ->
            if (button.isAttachedToWindow) {
                val params = button.layoutParams as WindowManager.LayoutParams
                safeRemoveView(button)
                safeAddView(button, params)
            }
        }
        translateButton?.let { button ->
            if (button.isAttachedToWindow) {
                val params = button.layoutParams as WindowManager.LayoutParams
                safeRemoveView(button)
                safeAddView(button, params)
            }
        }
    }

    private fun showOverlay(id: Int, text: String, x: Float = -1f, y: Float = -1f, width: Float = -1f, height: Float = -1f, overlayColor: Int = -1, backgroundColor: Int = -1, isLight: Boolean = false, imgWidth: Float = -1f, imgHeight: Float = -1f) {
        if (!hasOverlayPermission(this)) {
            print("Cannot show overlay: permission not granted")
            return
        }

        // Dynamically get the current screen metrics to handle rotation!
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                windowManager?.defaultDisplay?.getRealMetrics(displayMetrics)
            } else {
                windowManager?.defaultDisplay?.getMetrics(displayMetrics)
            }
            screenWidth = displayMetrics.widthPixels
            screenHeight = displayMetrics.heightPixels
            screenDensity = displayMetrics.densityDpi
            Log.d(TAG, "showOverlay dynamic metrics: ${screenWidth}x${screenHeight}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to dynamically get metrics in showOverlay", e)
        }

        if (overlayViews.containsKey(id)) {
            safeRemoveView(overlayViews[id])
            overlayViews.remove(id)
            overlayParams.remove(id)
            originalPositions.remove(id)
        } else if (overlayViews.size >= MAX_TEXT_OVERLAYS) {
            Log.w(TAG, "showOverlay: skipping box $id, already showing ${overlayViews.size} boxes")
            return
        }

        // Get status bar height
        var statusBarHeight = 0
        val resourceId = resources.getIdentifier("status_bar_height", "dimen", "android")
        if (resourceId > 0) {
            statusBarHeight = resources.getDimensionPixelSize(resourceId)
        }

        // Coordinate transformation from image space to screen space using aspect-fit
        val imgAspectRatio = imgWidth / imgHeight
        val screenAspectRatio = screenWidth.toFloat() / screenHeight.toFloat()

        var scale: Float
        var transformedX: Float
        var transformedY: Float

        if (screenAspectRatio < imgAspectRatio) {
            Log.d(TAG, "Screen is taller relative to image: $screenAspectRatio vs $imgAspectRatio (portrait display showing landscape image)")
            // Screen is taller, so the image is scaled to fit the screen width
            scale = screenWidth.toFloat() / imgWidth
            val yPadding = (screenHeight - imgHeight * scale) / 2f
            
            transformedX = x * scale
            transformedY = y * scale + yPadding
        } else {
            Log.d(TAG, "Screen is wider relative to image: $screenAspectRatio vs $imgAspectRatio (landscape display showing portrait image)")
            // Screen is wider, so the image is scaled to fit the screen height
            scale = screenHeight.toFloat() / imgHeight
            val xPadding = (screenWidth - imgWidth * scale) / 2f
            
            transformedX = x * scale + xPadding
            transformedY = y * scale
        }

        var transformedWidth = width * scale
        var transformedHeight = height * scale

        // Clamp the box fully inside the screen. OCR/coordinate-mapping
        // rounding can put x + width a few px past the right edge (or
        // y + height past the bottom); WindowManager doesn't reflow an
        // overlay window that extends past the display, so the TextView
        // wraps its lines at the box's *declared* width while the part
        // beyond the physical screen is simply never drawn — the visible
        // effect is translated text looking cut off on the right even
        // though nothing was actually clipped by our own view code. Shift
        // the box left/up first so its full width/height stays visible;
        // only shrink it as a last resort for boxes wider/taller than the
        // screen itself.
        if (transformedX + transformedWidth > screenWidth) {
            transformedX = (screenWidth - transformedWidth).coerceAtLeast(0f)
            if (transformedWidth > screenWidth) transformedWidth = screenWidth.toFloat()
        }
        if (transformedX < 0f) transformedX = 0f
        if (transformedY + transformedHeight > screenHeight) {
            transformedY = (screenHeight - transformedHeight).coerceAtLeast(0f)
            if (transformedHeight > screenHeight) transformedHeight = screenHeight.toFloat()
        }
        if (transformedY < 0f) transformedY = 0f

        Log.d(TAG, "Original box (x:$x, y:$y, w:$width, h:$height) on image ($imgWidth x $imgHeight)")
        Log.d(TAG, "Transformed box (x:$transformedX, y:$transformedY, w:$transformedWidth, h:$transformedHeight) for screen ($screenWidth x $screenHeight) with status bar: $statusBarHeight")

        // if (x != -1f && y != -1f) {
        //     (transformedX, transformedY) = reverseAspectRatioCoordinates(x, y, oldScreenWidth, oldScreenHeight, screenWidth, screenHeight, imgWidth, imgHeight)
        // }

        val finalView: View = if (false) {
            // 调试模式：只创建一个带红色边框的透明视图
            View(this).apply {
                background = GradientDrawable().apply {
                    setStroke(3, Color.RED)  // 3px 宽的红色边框
                    setColor(Color.TRANSPARENT)  // 透明背景
                }
            }
        } else {
            // 正常模式：创建带有文本的完整视图
            val containerLayout = FrameLayout(this).apply {
                elevation = 4.dpToPx().toFloat() // Subtle shadow for a clean look
                // Do not force minimumWidth = transformedWidth. Let the FrameLayout wrap content beautifully!
            }
            val overlayView = AppCompatTextView(this).apply {
                setText(text)

                val overlayTextColor = if (isLight) Color.WHITE else Color.BLACK
                // Nearly opaque. A clearly translucent background let the
                // original text bleed through and looked messy, but a small
                // bleed (~2%) is invisible in practice and is what lets
                // FrameStabilizer notice the text UNDER a box changing (the
                // next dialogue line in the same game text box): screen
                // capture sees our boxes too, so a fully opaque box hid any
                // change beneath it and left a stale translation on screen.
                val overlayBackgroundColor = Color.argb(
                    BOX_BACKGROUND_ALPHA,
                    Color.red(overlayColor),
                    Color.green(overlayColor),
                    Color.blue(overlayColor)
                )

                setTextColor(overlayTextColor)
                setBackgroundColor(overlayBackgroundColor)
                
                // Add a subtle shadow for better text contrast
                setShadowLayer(2f, 1f, 1f, if(isLight) Color.BLACK else Color.argb(80, 0, 0, 0))

                // Make dimensions exactly match the original text box to preserve layout
                val exactWidth = if (transformedWidth > 0) transformedWidth.toInt() else WindowManager.LayoutParams.WRAP_CONTENT
                val exactHeight = if (transformedHeight > 0) transformedHeight.toInt() else WindowManager.LayoutParams.WRAP_CONTENT

                // A little breathing room so text doesn't touch the box
                // edges — the box itself stays sized to the original text's
                // bounds, so autosize just shrinks the font slightly more to
                // make room for this.
                setPadding(4.dpToPx(), 2.dpToPx(), 4.dpToPx(), 2.dpToPx())
                setSingleLine(false)

                // Cap vertical growth so pathologically long translations
                // can't push the box far past its original bounds — but do
                // NOT set ellipsize here: Android's TextView autosizing
                // (setAutoSizeTextTypeUniformWithConfiguration below) is
                // documented to conflict with ellipsize, and combining them
                // was found to break autosizing outright, leaving text
                // rendered past the box's right/bottom edge where
                // clipChildren then silently discarded it instead of
                // shrinking to fit. maxLines alone is compatible with
                // autosize — the sizing algorithm treats it as an available
                // space constraint.
                maxLines = 15

                setAutoSizeTextTypeUniformWithConfiguration(
                    6, 100, 1, TypedValue.COMPLEX_UNIT_SP
                )
                gravity = Gravity.CENTER
            }
            containerLayout.clipChildren = true
            containerLayout.addView(overlayView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))
            containerLayout
        }

        val exactWidth = if (transformedWidth > 0) transformedWidth.toInt() else WindowManager.LayoutParams.WRAP_CONTENT
        val exactHeight = if (transformedHeight > 0) transformedHeight.toInt() else WindowManager.LayoutParams.WRAP_CONTENT

        // 使用精准的边界约束
        val layoutParams = WindowManager.LayoutParams(
            exactWidth,
            exactHeight,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            this.x = transformedX.toInt()
            this.y = transformedY.toInt()
        }

        var initialX = 0f
        var initialY = 0f
        var initialTouchX = 0f
        var initialTouchY = 0f

        var isDragging = false
        val gestureDetector = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onDoubleTap(e: MotionEvent): Boolean {
                showExpandedTextDialog(text, isLight)
                return true
            }
        })

        finalView.setOnTouchListener { v, event ->
            gestureDetector.onTouchEvent(event)
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = layoutParams.x.toFloat()
                    initialY = layoutParams.y.toFloat()
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = event.rawX - initialTouchX
                    val deltaY = event.rawY - initialTouchY
                    if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
                        isDragging = true
                    }
                    if (isDragging) {
                        layoutParams.x = (initialX + deltaX).toInt()
                        layoutParams.y = (initialY + deltaY).toInt()
                        windowManager?.updateViewLayout(finalView, layoutParams)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        v.performClick()
                    }
                    true
                }
                else -> false
            }
        }

        OverlayRegions.track(finalView)
        if (!safeAddView(finalView, layoutParams)) return
        originalPositions[id] = Pair(layoutParams.x, layoutParams.y)
        overlayViews[id] = finalView
        overlayParams[id] = layoutParams
        Log.d(TAG, "Overlay $id added to window manager at (${layoutParams.x}, ${layoutParams.y}), displayMode=$displayMode")
        bringControlButtonsToFront()

        updateOverlayVisibility(id)
    }

    private fun updateOverlayVisibility(specificId: Int? = null) {
        val idsToUpdate = specificId?.let { listOf(it) } ?: overlayViews.keys.toList()

        idsToUpdate.forEach { id ->
            val view = overlayViews[id] ?: return@forEach
            val params = overlayParams[id] ?: return@forEach
            val (originalX, originalY) = originalPositions[id] ?: return@forEach

            when (displayMode) {
                DisplayMode.AUTO -> {
                    view.visibility = View.VISIBLE
                    params.x = originalX
                    params.y = originalY
                    windowManager?.updateViewLayout(view, params)
                }
                DisplayMode.ORIGINAL -> {
                    view.visibility = View.GONE
                    params.x = originalX
                    params.y = originalY
                    windowManager?.updateViewLayout(view, params)
                }
                DisplayMode.MANUAL -> {
                    view.visibility = View.VISIBLE
                    params.x = originalX
                    params.y = originalY
                    windowManager?.updateViewLayout(view, params)
                }
            }
        }
    }

    private fun hideAllOverlays() {
        Log.d(TAG, "hideAllOverlays: removing ${overlayViews.size} overlays")
        overlayViews.forEach { (id, view) ->
            try {
                windowManager?.removeView(view)
                Log.d(TAG, "hideAllOverlays: removed overlay $id")
            } catch (e: Exception) {
                Log.e(TAG, "Error removing view $id: ${e.message}")
            }
        }
        overlayViews.clear()
        overlayParams.clear()
        originalPositions.clear()
    }

    // Removes a single overlay by id, leaving the rest untouched — used when
    // only one translated box has changed/disappeared instead of the whole
    // screen, so unrelated boxes don't flicker out and back on every tick.
    private fun hideOverlay(id: Int) {
        overlayViews[id]?.let { view ->
            try {
                windowManager?.removeView(view)
                Log.d(TAG, "hideOverlay: removed overlay $id")
            } catch (e: Exception) {
                Log.e(TAG, "Error removing view $id: ${e.message}")
            }
        }
        overlayViews.remove(id)
        overlayParams.remove(id)
        originalPositions.remove(id)
    }

    private fun dismissExpandedTextDialog() {
        safeRemoveView(expandedTextView)
        expandedTextView = null
    }

    private fun showExpandedTextDialog(text: String, isLight: Boolean) {
        // Only one at a time: each is a full-screen window, and repeated
        // double-taps used to stack them toward the per-app window limit.
        dismissExpandedTextDialog()
        val container = FrameLayout(this).apply {
            setBackgroundColor(Color.argb(200, 0, 0, 0)) // Semi-transparent dim background
            setOnClickListener { dismissExpandedTextDialog() }
        }
        expandedTextView = container

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val padding = 20.dpToPx()
            setPadding(padding, padding, padding, padding)
            background = GradientDrawable().apply {
                setColor(if (isLight) Color.DKGRAY else Color.WHITE)
                cornerRadius = 16.dpToPx().toFloat()
            }
        }

        val textView = TextView(this).apply {
            this.text = text
            textSize = 22f
            setTextColor(if (isLight) Color.WHITE else Color.BLACK)
            // Allow text selection in the expanded view!
            setTextIsSelectable(true)
        }
        
        val scrollView = ScrollView(this).apply {
            addView(textView)
        }
        
        // Prevent dialog from being too tall by using weight
        scrollView.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            0,
            1f
        )

        val cardParams = FrameLayout.LayoutParams(
            (screenWidth * 0.85).toInt(),
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER
            val margin = 24.dpToPx()
            setMargins(margin, margin, margin, margin)
        }
        
        card.addView(scrollView)

        val closeText = TextView(this).apply {
            this.text = getString(R.string.tap_outside_to_close)
            textSize = 12f
            setTextColor(Color.GRAY)
            gravity = Gravity.CENTER
            setPadding(0, 16.dpToPx(), 0, 0)
        }
        card.addView(closeText)

        container.addView(card, cardParams)

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        OverlayRegions.track(container, isControl = true)
        if (!safeAddView(container, layoutParams)) expandedTextView = null
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "start" -> {
                // The system can re-deliver this start intent after killing
                // the process in the background (seen on Vivo/Oppo/Android
                // 16), with no Activity and hence no Flutter engine. There
                // is no translation session to attach to — just go away.
                val messenger = MainActivity.binaryMessenger
                if (messenger == null) {
                    Log.w(TAG, "start: Flutter engine not attached, stopping")
                    stopSelf()
                    return START_NOT_STICKY
                }
                // Reset stopped flag when starting the service
                isStopped = false
                methodChannel = MethodChannel(messenger, "com.lomoware.screen_translate/translationService")
                // A repeated start must not stack a second set of buttons.
                if (controlButton == null) createControlButton()
                if (translateButton == null) createTranslateButton()
                Log.d(TAG, "Service started, reset stopped flag")
            }
            "show" -> {
                Log.d(TAG, "onStartCommand: show action received, isStopped=$isStopped")
                // Reset stopped flag when showing
                if (!isStopped) {
                    val text = intent.getStringExtra("text")
                    val x = intent.getFloatExtra("x", -1f)
                    val y = intent.getFloatExtra("y", -1f)
                    val width = intent.getFloatExtra("width", -1f)
                    val height = intent.getFloatExtra("height", -1f)
                    val id = intent.getIntExtra("id", -1)
                    val overlayColor = intent.getIntExtra("overlayColor", -1)
                    val backgroundColor = intent.getIntExtra("backgroundColor", -1)
                    val isLight = intent.getBooleanExtra("isLight", false)
                    val imgWidth = intent.getFloatExtra("imgWidth", -1f)
                    val imgHeight = intent.getFloatExtra("imgHeight", -1f)

                    Log.d(TAG, "onStartCommand show: text='${text?.take(30)}', id=$id, overlayColor=${String.format("#%08X", overlayColor)}, isLight=$isLight")

                    if (text != null && id >= 0) {
                        showOverlay(id, text, x, y, width, height, overlayColor, backgroundColor, isLight, imgWidth, imgHeight)
                    } else {
                        Log.w(TAG, "onStartCommand show: invalid params text=$text, id=$id")
                    }
                } else {
                    Log.w(TAG, "onStartCommand show: SKIPPED because isStopped=true")
                }
            }
            "hideAll" -> {
                hideAllOverlays()
            }
            "hideOne" -> {
                val id = intent.getIntExtra("id", -1)
                if (id >= 0) hideOverlay(id)
            }
            "stop" -> {
                isStopped = true
                handler.removeCallbacks(bringToFrontRunnable)
                bringToFrontPending = false
                hideAllOverlays()
                removeOverlayButtons()
            }
        }
        return START_NOT_STICKY
    }

    private fun removeOverlayButtons() {
        if (isStopped) {
            Log.d(TAG, "Service is stopped, removing overlay buttons")
        }

        controlButton?.let { button ->
            Log.d(TAG, "Attempting to remove control button")
            if (windowManager != null) {
                try {
                    windowManager?.removeView(button)
                    Log.d(TAG, "Control button removed successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error removing control button: ${e.message}", e)
                }
            } else {
                Log.e(TAG, "windowManager is null, cannot remove control button")
            }
            controlButton = null
        }

        translateButton?.let { button ->
            Log.d(TAG, "Attempting to remove translate button")
            if (windowManager != null) {
                try {
                    windowManager?.removeView(button)
                    Log.d(TAG, "Translate button removed successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error removing translate button: ${e.message}", e)
                }
            } else {
                Log.e(TAG, "windowManager is null, cannot remove translate button")
            }
            translateButton = null
        }

        safeRemoveView(tooltipView)
        tooltipView = null
        tooltipHideRunnable?.let { handler.removeCallbacks(it) }
        // A full-screen dialog left behind after stopping would swallow
        // every touch until the user found the (now invisible) way out.
        dismissExpandedTextDialog()
    }

    override fun onDestroy() {
        super.onDestroy()
        hideAllOverlays()
        removeOverlayButtons()
        // Disconnect the method channel to prevent further calls
        if (::methodChannel.isInitialized) {
            methodChannel.setMethodCallHandler(null)
        }
        windowManager = null
    }

    private fun reverseAspectRatioCoordinates(x: Float, y: Float, originalWidth: Int, originalHeight: Int, newWidth: Int, newHeight: Int, imgWidth: Float, imgHeight: Float): Pair<Float, Float> {
        Log.d(TAG, "Reverse Aspect Ratio Coordinates Input:")
        Log.d(TAG, "Original Coordinates: (x: $x, y: $y)")
        Log.d(TAG, "Original Dimensions: ${originalWidth}x$originalHeight")
        Log.d(TAG, "New Dimensions: ${newWidth}x$newHeight")

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
            val scaleX = newWidth.toFloat() / imgWidth
            val scaleY = newHeight.toFloat() / imgHeight
            adjustedX = x * scaleX
            adjustedY = y * scaleY
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
