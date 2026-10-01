package com.lomoware.screen_translate

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class OverlayTextFitTest {
    // Monospace stand-in for Paint.measureText: 10px per character at size 100.
    private val measure: (String) -> Float = { it.length * 10f }

    @Test
    fun capsSizeSoTheLongestWordFits() {
        // Widest word "destroyed." is 100px at size 100, so a 45px box fits it at 45.
        val cap = OverlayTextFit.maxSizeKeepingWordsWhole(
            "It is destroyed. Take the robot", 45f, 100f, measure)
        assertEquals(45f, cap!!, 0.001f)
    }

    @Test
    fun usesTheWidestWordIncludingPunctuation() {
        val cap = OverlayTextFit.maxSizeKeepingWordsWhole("Help! destroyed.", 50f, 100f, measure)
        // "destroyed." = 10 chars = 100px at size 100 -> fits 50px at size 50.
        assertEquals(50f, cap!!, 0.001f)
    }

    @Test
    fun ignoresCjkTextWhichMayBreakAnywhere() {
        assertNull(OverlayTextFit.maxSizeKeepingWordsWhole("助けて！あのロボットが街を壊している", 40f, 100f, measure))
        // Mixed: only the Latin word counts.
        assertEquals(100f, OverlayTextFit.maxSizeKeepingWordsWhole("ロボットが街を OK", 20f, 100f, measure)!!, 0.001f)
    }

    @Test
    fun noCapWithoutAKnownWidth() {
        assertNull(OverlayTextFit.maxSizeKeepingWordsWhole("Hello", 0f, 100f, measure))
        assertNull(OverlayTextFit.maxSizeKeepingWordsWhole("   ", 100f, 100f, measure))
    }
}
