package com.lomoware.screen_translate

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class AccessibilityFunnelStoreTest {
    private val values = mutableMapOf<String, Any?>()
    private lateinit var store: AccessibilityFunnelStore
    private var enabledChecks = 0
    private var writes = 0

    @Before
    fun setUp() {
        values.clear()
        enabledChecks = 0
        writes = 0
        store = AccessibilityFunnelStore(object : AccessibilityFunnelStore.KeyValue {
            override fun getBoolean(key: String) = values[key] as? Boolean ?: false
            override fun getString(key: String) = values[key] as? String
            override fun write(newValues: Map<String, Any?>) {
                writes++
                newValues.forEach { (key, value) ->
                    if (value == null) values.remove(key) else values[key] = value
                }
            }
        })
    }

    private fun take(enabled: Boolean) = store.take { enabledChecks++; enabled }

    @Test
    fun nothingRecordedReportsNothing() {
        val out = take(true)
        assertEquals(false, out["promptShown"])
        assertNull(out["result"])
        assertEquals(0, enabledChecks)
    }

    @Test
    fun promptShownIsHandedOverOnceAndNoResultWhileItIsOpen() {
        store.markPromptShown()
        val first = take(false)
        assertEquals(true, first["promptShown"])
        assertNull(first["result"])
        assertEquals(0, enabledChecks)
        assertEquals(false, take(false)["promptShown"])
    }

    @Test
    fun resultCarriesTheCloseActionAndTheEnabledStateWhenAsked() {
        store.markPromptShown()
        take(false)
        store.markPromptClosed(AccessibilityFunnelStore.ACTION_SETTINGS_OPENED)

        val out = take(true)
        assertEquals(false, out["promptShown"])
        @Suppress("UNCHECKED_CAST")
        val result = out["result"] as Map<String, Any>
        assertEquals(true, result["enabled"])
        assertEquals("settings_opened", result["action"])
        assertEquals(1, enabledChecks)

        // Sent once.
        assertNull(take(true)["result"])
    }

    @Test
    fun promptAndResultCanArriveTogether() {
        store.markPromptShown()
        store.markPromptClosed(AccessibilityFunnelStore.ACTION_DISMISSED)
        val out = take(false)
        assertEquals(true, out["promptShown"])
        @Suppress("UNCHECKED_CAST")
        val result = out["result"] as Map<String, Any>
        assertFalse(result["enabled"] as Boolean)
        assertEquals("dismissed", result["action"])
    }

    @Test
    fun showingThePromptAgainDropsAnUnreportedOldResult() {
        store.markPromptClosed(AccessibilityFunnelStore.ACTION_DISMISSED)
        store.markPromptShown()
        val out = take(true)
        assertTrue(out["promptShown"] as Boolean)
        assertNull(out["result"])
    }

    /**
     * These writes are synchronous commits on the main thread (app start,
     * and the explainer's onPause, which runs before MainActivity resumes),
     * so each step must cost one disk write and an empty take must cost none.
     */
    @Test
    fun eachStepIsASingleWriteAndAnEmptyTakeWritesNothing() {
        store.markPromptShown()
        assertEquals(1, writes)
        store.markPromptClosed(AccessibilityFunnelStore.ACTION_DISMISSED)
        assertEquals(2, writes)
        take(false)
        assertEquals(3, writes)

        // Nothing left pending: every later start and resume reads only.
        take(false)
        take(false)
        assertEquals(3, writes)
    }
}
