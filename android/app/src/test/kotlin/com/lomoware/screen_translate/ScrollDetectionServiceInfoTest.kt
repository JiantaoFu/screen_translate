package com.lomoware.screen_translate

import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Play rejected Lite 1.2.6 over the accessibility service, and the listing
 * now states the service only receives scroll and app-switch events and
 * never reads screen text. These assertions are what keeps the runtime
 * configuration matching that statement.
 */
@RunWith(RobolectricTestRunner::class)
class ScrollDetectionServiceInfoTest {
    private val info = ScrollDetectionAccessibilityService.scrollDetectionServiceInfo()

    @Test
    fun `asks for scroll and window-state events only`() {
        assertEquals(
            AccessibilityEvent.TYPE_VIEW_SCROLLED or AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            info.eventTypes,
        )
    }

    @Test
    fun `asks for no flags at all`() {
        // Notably not AccessibilityServiceInfo.DEFAULT, which is the flag 1
        // ("invoked only if no package specific one exists") and would stop
        // scroll detection firing in apps another service has claimed, and
        // not FLAG_REQUEST_FILTER_KEY_EVENTS, which there is no handler for.
        assertEquals(0, info.flags)
    }

    @Test
    fun `does not request key-event filtering`() {
        assertEquals(
            0,
            info.flags and AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS,
        )
    }

    @Test
    fun `is not registered as the default service for its feedback type`() {
        assertEquals(0, info.flags and AccessibilityServiceInfo.DEFAULT)
    }
}
