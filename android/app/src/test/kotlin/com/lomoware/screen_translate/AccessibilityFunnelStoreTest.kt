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

    @Before
    fun setUp() {
        values.clear()
        enabledChecks = 0
        store = AccessibilityFunnelStore(object : AccessibilityFunnelStore.KeyValue {
            override fun getBoolean(key: String) = values[key] as? Boolean ?: false
            override fun getString(key: String) = values[key] as? String
            override fun putBoolean(key: String, value: Boolean) { values[key] = value }
            override fun putString(key: String, value: String?) { values[key] = value }
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
}
