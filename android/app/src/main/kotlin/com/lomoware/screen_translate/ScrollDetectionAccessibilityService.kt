package com.lomoware.screen_translate

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import kotlin.math.abs

class ScrollDetectionAccessibilityService : AccessibilityService() {
    companion object {
        const val SCROLL_DETECTED_ACTION = "com.lomoware.screen_translate.SCROLL_DETECTED"
        // Fired when the foreground window changes to a different package —
        // switching apps, going Home, or opening Recents. Without this, a
        // translation overlay captured for one screen kept floating over
        // whatever the user navigated to next (e.g. the Recents task
        // switcher), which looked like leftover garbage plastered over
        // unrelated content.
        const val WINDOW_CHANGED_ACTION = "com.lomoware.screen_translate.WINDOW_CHANGED"
        var instance: ScrollDetectionAccessibilityService? = null
            private set

        private const val TAG = "ScrollDetectionService"
    }

    // Track scroll state for different packages
    private val scrollStateMap = mutableMapOf<String, ScrollState>()

    // Inner class to track scroll state
    private data class ScrollState(
        var lastScrollX: Int = 0,
        var lastScrollY: Int = 0,
        var lastScrollTimestamp: Long = 0
    )

    private var isScrolling = false
    private var lastScrolledPackage: String? = null
    private var scrollStartTimestamp: Long = 0

    // Track foreground window changes, debounced — a single app switch can
    // fire several TYPE_WINDOW_STATE_CHANGED events within milliseconds
    // (e.g. an intermediate transition window), which would otherwise
    // spam redundant hide/cancel broadcasts.
    private var lastForegroundPackage: String? = null
    private var lastWindowChangeTimestamp: Long = 0

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
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                handleScrollEvent(event)
            }
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                handleWindowStateChanged(event)
            }
            // Other event types can be handled here if needed
        }
    }

    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        val currentTime = System.currentTimeMillis()

        if (packageName == lastForegroundPackage) return
        if (currentTime - lastWindowChangeTimestamp < 300) return

        lastForegroundPackage = packageName
        lastWindowChangeTimestamp = currentTime

        Log.d(TAG, "Foreground window changed to $packageName")

        val intent = Intent(WINDOW_CHANGED_ACTION).apply {
            putExtra("package", packageName)
        }

        try {
            LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending window-changed broadcast", e)
        }
    }

    private fun handleScrollEvent(event: AccessibilityEvent) {
        val currentTime = System.currentTimeMillis()
        val packageName = event.packageName?.toString() ?: "unknown"

        // Get or create scroll state for this package
        val scrollState = scrollStateMap.getOrPut(packageName) { ScrollState() }

        // Calculate scroll deltas
        val scrollXDelta = event.scrollX - scrollState.lastScrollX
        val scrollYDelta = event.scrollY - scrollState.lastScrollY

        // Log raw event details for debugging
        Log.d(TAG, "Raw Scroll Event Details:")
        Log.d(TAG, "Current ScrollX: ${event.scrollX}, Last ScrollX: ${scrollState.lastScrollX}")
        Log.d(TAG, "Current ScrollY: ${event.scrollY}, Last ScrollY: ${scrollState.lastScrollY}")
        Log.d(TAG, "Calculated X Delta: $scrollXDelta, Y Delta: $scrollYDelta")

        // More conservative scroll detection
        val isSignificantScroll = 
            abs(scrollXDelta) > 50 || 
            abs(scrollYDelta) > 50

        val isSystemPackage = packageName == "com.android.systemui"

        if (isSignificantScroll && !isSystemPackage) {
            // Update scroll state
            scrollState.lastScrollX = event.scrollX
            scrollState.lastScrollY = event.scrollY
            scrollState.lastScrollTimestamp = currentTime

            // Broadcast scroll event
            val intent = Intent(SCROLL_DETECTED_ACTION).apply {
                putExtra("package", packageName)
                putExtra("scrollXDelta", scrollXDelta)
                putExtra("scrollYDelta", scrollYDelta)
            }
            
            try {
                Log.d(TAG, "Significant Scroll Detected in $packageName")
                Log.d(TAG, "X Delta: $scrollXDelta, Y Delta: $scrollYDelta")
                
                LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error sending scroll broadcast", e)
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
            this.eventTypes = AccessibilityEvent.TYPE_VIEW_SCROLLED or AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
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
