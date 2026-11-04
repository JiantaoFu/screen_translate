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
 * The explainer gets one showing per install, and the flag that spends it is
 * set by the activity, not by the launch: startActivity throws nothing when
 * the system refuses a background launch, so marking it at the request spent
 * the showing on a dialog the user never saw.
 *
 * The one step these cannot reach is AccessibilityPermissionActivity.onCreate
 * calling markPrompted: instantiating an AppCompatActivity needs
 * includeAndroidResources, and turning that on makes robolectric 4.10.3
 * reject the whole suite over targetSdk 36 (see app/build.gradle). Everything
 * either side of that call is covered here.
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

    /** What really happens after a launch that the system lets through. */
    private fun explainerAppears() {
        AccessibilityPermissionDialog.markPrompted(app)
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
    fun `once the explainer has been seen it declines, so the caller can do something else`() {
        dialog().show()
        drainLaunches()
        explainerAppears()

        assertFalse(dialog().show())
        assertNull(launchedActivity())
    }

    @Test
    fun `a launch the system drops is retried`() {
        if (lite) return
        // Nothing marks the prompt: the activity never ran.
        assertTrue(dialog().show())
        drainLaunches()

        assertTrue("a dropped launch must not spend the showing", dialog().show())
        assertEquals(AccessibilityPermissionActivity::class.java.name, launchedActivity())
    }

    @Test
    fun `retrying a dropped launch gives up instead of trying on every resume`() {
        if (lite) return
        var launches = 0
        repeat(10) {
            if (dialog().show()) launches++
            drainLaunches()
        }
        assertEquals(3, launches)
        assertFalse(dialog().show())
    }

    @Test
    fun `resetting the prompt lets it explain again`() {
        dialog().show()
        drainLaunches()
        explainerAppears()
        dialog().resetAccessibilityPrompt()

        assertEquals(!lite, dialog().show())
    }

}
