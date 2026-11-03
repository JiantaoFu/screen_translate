package com.lomoware.screen_translate

import android.content.ComponentName
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** Exercise the actual platform boundary, including Android 7 where the
 * Context.startForegroundService method does not exist. Both flavors run this.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [24, 25, 26], manifest = Config.NONE)
class ForegroundServiceCompatibilityTest {
    private class RecordingContext(base: Context) : ContextWrapper(base) {
        val serviceStarts = mutableListOf<Intent>()
        val foregroundStarts = mutableListOf<Intent>()

        override fun startService(service: Intent): ComponentName? {
            serviceStarts += service
            return service.component
        }

        override fun startForegroundService(service: Intent): ComponentName? {
            foregroundStarts += service
            return service.component
        }
    }

    @Test
    fun `starts through the API appropriate for the device`() {
        val context = RecordingContext(RuntimeEnvironment.getApplication())
        var ready = false

        ForegroundService.startAndAwaitForeground(context) { ready = true }

        val expected = ComponentName(context, ForegroundService::class.java)
        if (Build.VERSION.SDK_INT < 26) {
            assertEquals(listOf(expected), context.serviceStarts.map { it.component })
            assertTrue(context.foregroundStarts.isEmpty())
        } else {
            assertTrue(context.serviceStarts.isEmpty())
            assertEquals(listOf(expected), context.foregroundStarts.map { it.component })
        }
        assertFalse("Starting a service must not signal foreground readiness", ready)
    }

    @Test
    fun `signals readiness once and only after entering the foreground`() {
        val context = RecordingContext(RuntimeEnvironment.getApplication())
        val controller = Robolectric.buildService(ForegroundService::class.java).create()
        val service = controller.get()
        var callbacks = 0
        var foregroundAtCallback = false
        try {
            ForegroundService.startAndAwaitForeground(context) {
                callbacks++
                foregroundAtCallback = shadowOf(service).lastForegroundNotification != null
            }
            assertEquals(0, callbacks)

            service.onStartCommand(Intent(), 0, 1)
            assertEquals(1, callbacks)
            assertTrue("MediaProjection callers must wait for startForeground", foregroundAtCallback)

            service.onStartCommand(Intent(), 0, 2)
            assertEquals("A later service start must not repeat the callback", 1, callbacks)
        } finally {
            controller.destroy()
        }
    }
}
