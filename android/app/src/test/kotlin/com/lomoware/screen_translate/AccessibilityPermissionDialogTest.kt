package com.lomoware.screen_translate

import android.content.Context
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf

/**
 * Whether show() launches an explainer, and whether it says so.
 *
 * Dart asks for the explainer on resume now and uses the return value to
 * decide whether that resume is taken, so a show() that silently does
 * nothing but reports true would cost the review prompt its turn.
 *
 * These tests run once per flavor, which is also how the lite guard is
 * covered: lite has no accessibility service, so it must never explain one.
 */
@RunWith(RobolectricTestRunner::class)
class AccessibilityPermissionDialogTest {
    private val app get() = RuntimeEnvironment.getApplication()
    private val lite = BuildConfig.FLAVOR == "lite"

    private fun dialog() = AccessibilityPermissionDialog(app)

    private fun launchedActivity(): String? =
        shadowOf(app).nextStartedActivity?.component?.className

    private fun drainLaunches() {
        while (launchedActivity() != null) { /* nothing */ }
    }

    @Before
    fun setUp() {
        app.getSharedPreferences("AccessibilityPrefs", Context.MODE_PRIVATE)
            .edit().clear().commit()
        drainLaunches()
    }

    @Test
    fun `first call explains, and says it did`() {
        val shown = dialog().show()
        if (lite) {
            assertFalse(shown)
            assertNull(launchedActivity())
            return
        }
        assertTrue(shown)
        assertEquals(AccessibilityPermissionActivity::class.java.name, launchedActivity())
    }

    @Test
    fun `a second call declines, so the caller can do something else`() {
        dialog().show()
        drainLaunches()

        assertFalse(dialog().show())
        assertNull(launchedActivity())
    }

    @Test
    fun `resetting the prompt lets it explain again`() {
        dialog().show()
        drainLaunches()
        dialog().resetAccessibilityPrompt()

        assertEquals(!lite, dialog().show())
    }
}
