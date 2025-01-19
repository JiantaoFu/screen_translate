package com.example.screen_translate

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.content.Context

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private val overlayViews = mutableMapOf<Int, View>()
    private val overlayParams = mutableMapOf<Int, WindowManager.LayoutParams>()
    private var nextId = 0

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
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
                val id = intent.getIntExtra("id", -1)
                if (text != null && id >= 0) {
                    showOverlay(id, text, x, y)
                }
            }
            "hideAll" -> {
                hideAllOverlays()
            }
        }
        return START_NOT_STICKY
    }

    private fun showOverlay(id: Int, text: String, x: Float = -1f, y: Float = -1f) {
        if (!hasOverlayPermission(this)) {
            print("Cannot show overlay: permission not granted")
            return
        }

        if (!overlayViews.containsKey(id)) {
            // Create new overlay view
            val overlayView = TextView(this).apply {
                setText(text)
                setTextColor(android.graphics.Color.WHITE)
                setBackgroundColor(android.graphics.Color.argb(230, 0, 0, 0))
                setPadding(40, 20, 40, 20)
                textSize = 16f
            }

            // Set up layout parameters
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_SECURE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = if (x >= 0 && y >= 0) {
                    Gravity.TOP or Gravity.START
                } else {
                    Gravity.TOP or Gravity.CENTER_HORIZONTAL
                }
                
                if (x >= 0 && y >= 0) {
                    this.x = x.toInt()
                    this.y = y.toInt()
                } else {
                    this.y = 200
                }
            }

            // Store view and params
            overlayViews[id] = overlayView
            overlayParams[id] = params

            // Add the view to window manager
            windowManager?.addView(overlayView, params)
        } else {
            // Update existing overlay
            val overlayView = overlayViews[id]
            val params = overlayParams[id]
            
            (overlayView as TextView).text = text
            if (x >= 0 && y >= 0 && params != null) {
                params.x = x.toInt()
                params.y = y.toInt()
                params.gravity = Gravity.TOP or Gravity.START
                windowManager?.updateViewLayout(overlayView, params)
            }
        }
    }

    private fun hideAllOverlays() {
        overlayViews.forEach { (_, view) ->
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        overlayViews.clear()
        overlayParams.clear()
    }

    override fun onDestroy() {
        super.onDestroy()
        hideAllOverlays()
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
