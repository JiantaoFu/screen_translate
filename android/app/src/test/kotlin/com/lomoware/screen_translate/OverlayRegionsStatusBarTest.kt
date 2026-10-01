package com.lomoware.screen_translate

import android.os.SystemClock
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.shadows.ShadowSystemClock
import java.time.Duration

@RunWith(RobolectricTestRunner::class)
class OverlayRegionsStatusBarTest {
    @After
    fun reset() {
        OverlayRegions.statusBarVisible = true
    }

    @Test
    fun statusBarIsBlankedForAWhileAfterItHides() {
        OverlayRegions.statusBarVisible = true
        assertTrue(OverlayRegions.statusBarMayBeInFrame())

        // Insets say "hidden" as the hide animation starts; frames captured
        // just after can still show the bar.
        OverlayRegions.statusBarVisible = false
        assertTrue(OverlayRegions.statusBarMayBeInFrame())
        ShadowSystemClock.advanceBy(Duration.ofMillis(500))
        assertTrue(OverlayRegions.statusBarMayBeInFrame())

        ShadowSystemClock.advanceBy(Duration.ofMillis(600))
        assertFalse(OverlayRegions.statusBarMayBeInFrame())
    }

    @Test
    fun staysHiddenWhileImmersive() {
        OverlayRegions.statusBarVisible = false
        ShadowSystemClock.advanceBy(Duration.ofMillis(2000))
        // A repeated "hidden" report doesn't restart the grace period.
        OverlayRegions.statusBarVisible = false
        assertFalse(OverlayRegions.statusBarMayBeInFrame(SystemClock.uptimeMillis()))
    }
}
