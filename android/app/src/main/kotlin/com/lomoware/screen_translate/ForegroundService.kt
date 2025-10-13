package com.lomoware.screen_translate

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import android.view.Display
import android.view.Surface
import android.view.WindowManager
import androidx.core.app.NotificationCompat

class ForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "screen_translate_channel"
        private const val NOTIFICATION_ID = 1
        private const val TAG = "ForegroundService"
    }

    // Configuration change receiver
    private val configurationChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_CONFIGURATION_CHANGED -> {
                    Log.d(TAG, "Configuration changed broadcast received")
                    broadcastDisplayInfo()
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        // Register configuration change receiver
        val filter = IntentFilter(Intent.ACTION_CONFIGURATION_CHANGED)
        registerReceiver(configurationChangeReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Unregister receiver to prevent memory leaks
        unregisterReceiver(configurationChangeReceiver)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen Translate")
            .setContentText("Screen capture is active")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        return START_NOT_STICKY
    }

    private fun broadcastDisplayInfo() {
        // Get current configuration
        val currentConfiguration = resources.configuration
        Log.d(TAG, "Current Configuration:")
        Log.d(TAG, "Orientation: ${when(currentConfiguration.orientation) {
            Configuration.ORIENTATION_PORTRAIT -> "Portrait"
            Configuration.ORIENTATION_LANDSCAPE -> "Landscape"
            else -> "Unknown"
        }}")
        Log.d(TAG, "Screen Width (dp): ${currentConfiguration.screenWidthDp}")
        Log.d(TAG, "Screen Height (dp): ${currentConfiguration.screenHeightDp}")

        // WindowManager approach
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val defaultDisplay = windowManager.defaultDisplay
        val displayMetrics = DisplayMetrics()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            defaultDisplay.getRealMetrics(displayMetrics)
        } else {
            defaultDisplay.getMetrics(displayMetrics)
        }

        Log.d(TAG, "WindowManager Display Info:")
        Log.d(TAG, "Screen Width: ${displayMetrics.widthPixels}")
        Log.d(TAG, "Screen Height: ${displayMetrics.heightPixels}")
        Log.d(TAG, "Screen Density: ${displayMetrics.density}")

        // DisplayManager approach
        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val displays = displayManager.displays

        Log.d(TAG, "Number of Displays: ${displays.size}")

        displays.forEachIndexed { index, display ->
            Log.d(TAG, "Display $index:")
            Log.d(TAG, "  Display ID: ${display.displayId}")
            Log.d(TAG, "  Rotation: ${display.rotation}")
            Log.d(TAG, "  Rotation Description: ${when(display.rotation) {
                Surface.ROTATION_0 -> "Portrait"
                Surface.ROTATION_90 -> "Landscape (90°)"
                Surface.ROTATION_180 -> "Portrait (180°)"
                Surface.ROTATION_270 -> "Landscape (270°)"
                else -> "Unknown"
            }}")
        }

        // Find the OverlayService and update display info
        val overlayService = OverlayService.getInstance()
        overlayService?.updateDisplayInfo(
            displayMetrics.widthPixels,
            displayMetrics.heightPixels,
            displayMetrics.density,
            displays[0].rotation
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Translate Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Used for screen capture service"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
