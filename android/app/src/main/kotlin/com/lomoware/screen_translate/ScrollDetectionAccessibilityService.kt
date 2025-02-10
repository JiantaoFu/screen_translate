package com.lomoware.screen_translate

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import androidx.localbroadcastmanager.content.LocalBroadcastManager

class ScrollDetectionAccessibilityService : AccessibilityService() {
    companion object {
        const val SCROLL_DETECTED_ACTION = "com.lomoware.screen_translate.SCROLL_DETECTED"
        var instance: ScrollDetectionAccessibilityService? = null
            private set

        private const val TAG = "ScrollDetectionService"
    }

    private var isScrolling = false
    private var lastScrolledPackage: String? = null
    private var scrollStartTimestamp: Long = 0

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "ScrollDetectionAccessibilityService created")
        instance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "ScrollDetectionAccessibilityService destroyed")
        instance = null
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        try {
            when (event.eventType) {
                AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                    handleScrollEvent(event)
                }
                else -> {
                    // Log other event types for debugging
                    Log.v(TAG, "Received event type: ${event.eventType}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing accessibility event", e)
        }
    }

    private fun handleScrollEvent(event: AccessibilityEvent) {
        val currentTime = System.currentTimeMillis()

        // Prevent rapid successive scroll events
        if (currentTime - scrollStartTimestamp < 100) {
            Log.d(TAG, "Ignoring rapid successive scroll event")
            return
        }

        // Calculate scroll difference
        val scrollDelta = when {
            event.scrollY != 0 -> event.scrollY
            event.scrollX != 0 -> event.scrollX
            event.fromIndex != null && event.toIndex != null -> event.toIndex - event.fromIndex
            else -> 0
        }

        if (scrollDelta != 0) {
            val packageName = event.packageName?.toString() ?: "unknown"
            
            isScrolling = true
            lastScrolledPackage = packageName
            scrollStartTimestamp = currentTime

            // Broadcast scroll event using LocalBroadcastManager
            val intent = Intent(SCROLL_DETECTED_ACTION).apply {
                putExtra("package", packageName)
                putExtra("scrollDelta", scrollDelta)
            }
            
            try {
                Log.d(TAG, "Preparing to send local broadcast")
                Log.d(TAG, "Broadcast Action: $SCROLL_DETECTED_ACTION")
                Log.d(TAG, "Package Name: $packageName")
                Log.d(TAG, "Scroll Delta: $scrollDelta")
                
                LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
                
                Log.d(TAG, "Local broadcast sent successfully")
                Log.d(TAG, "Scroll detected in $packageName, delta: $scrollDelta")
            } catch (e: Exception) {
                Log.e(TAG, "Error sending local broadcast", e)
                Log.e(TAG, "Exception details: ${e.message}")
                Log.e(TAG, "Exception stack trace: ${e.stackTraceToString()}")
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        
        Log.d(TAG, "Accessibility service connected")
        
        // Configure service capabilities
        val info = AccessibilityServiceInfo().apply {
            this.eventTypes = AccessibilityEvent.TYPE_VIEW_SCROLLED
            this.feedbackType = AccessibilityServiceInfo.FEEDBACK_VISUAL
            this.notificationTimeout = 100
            this.flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS
        }
        
        serviceInfo = info
        
        Log.d(TAG, "Accessibility service configured with scroll detection")
    }

    // Helper method to check if service is enabled
    fun isScrollDetectionEnabled(): Boolean {
        val isEnabled = instance != null
        Log.d(TAG, "Scroll detection enabled: $isEnabled")
        return isEnabled
    }
}
