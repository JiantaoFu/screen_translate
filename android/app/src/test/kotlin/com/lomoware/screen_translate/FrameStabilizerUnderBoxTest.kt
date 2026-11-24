package com.lomoware.screen_translate

import android.graphics.Rect
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * A change under one of our translated boxes when no further frames come.
 * Sharing one app (Android 14+'s default), neither the status bar's
 * screen-sharing timer nor our boxes are captured, so a static page sends
 * one frame for a new dialogue line and then nothing. That line used to be
 * seen once as "moving" and never confirmed, and the old translation stayed
 * over the new text.
 */
@RunWith(RobolectricTestRunner::class)
class FrameStabilizerUnderBoxTest {
    private val w = 200
    private val h = 400
    private val box = Rect(20, 100, 180, 160)
    private val window = Rect(8, 88, 192, 172) // the box's window, with margin

    private class Task(val at: Long, val block: () -> Unit) { var cancelled = false }

    private var now = 0L
    private val tasks = mutableListOf<Task>()
    private var motions = 0
    private lateinit var stabilizer: FrameStabilizer
    // Whether our box is on screen; drawing it bumps the windows' version.
    private var boxShown = true
    private val windowListeners = mutableListOf<() -> Unit>()

    private fun drawBox() {
        boxShown = true
        windowListeners.toList().forEach { it() }
    }

    @Before
    fun setUp() = makeStabilizer(withBox = true)

    private fun makeStabilizer(withBox: Boolean) {
        stabilizer = FrameStabilizer(
            w, h, 0,
            ownWindows = { if (withBox && boxShown) listOf(Rect(window)) else emptyList() },
            textBoxes = { if (withBox && boxShown) listOf(Rect(box)) else emptyList() },
            windowsVersion = { if (boxShown) 2L else 1L },
            windowsChanged = { listener ->
                windowListeners += listener
                ({ windowListeners -= listener })
            },
            clock = { now },
            schedule = { delay, block ->
                val task = Task(now + delay, block)
                tasks += task
                ({ task.cancelled = true })
            },
        ) { motions++ }
    }

    /**
     * A white screen with "text" strokes inside the box; [line] 0-2 picks
     * which. 10/11 are two frames of a scene animating over the whole
     * screen, 20 a different still page.
     */
    private fun frame(line: Int, bleed: Int = 0): ByteArray {
        val bytes = ByteArray(w * h * 3 / 2) { 0xFF.toByte() }
        when {
            // [bleed]: an animated scene showing faintly through the box.
            line < 10 -> for (y in box.top until box.bottom) for (x in box.left until box.right) {
                val glyph = (x / 4 + y / 4) % 3 == line
                bytes[y * w + x] = (if (glyph) bleed else 255 - bleed).toByte()
            }
            line < 20 -> for (y in 0 until h) for (x in 0 until w) {
                bytes[y * w + x] = (((x + y) / 7 + line) % 2 * 200).toByte()
            }
            else -> for (y in 0 until h) for (x in 0 until w) {
                if ((x / 9) % 2 == 0) bytes[y * w + x] = 60
            }
        }
        return bytes
    }

    private fun feed(line: Int, at: Long, bleed: Int = 0) {
        now = at
        stabilizer.onNewFrame(frame(line, bleed), at) {}
    }

    @Test
    fun aNewLineInASemiTransparentDialogueBoxOverAnAnimatedScene() {
        var t = 1_000L
        fun play(line: Int, frames: Int) = repeat(frames) {
            feed(line, t, bleed = (t / 33 % 3 * 8).toInt()); t += 33
        }
        play(0, 60)             // the scene flickers faintly behind the line
        assertEquals(0, motions)
        play(1, 30)             // the next line, the scene still playing
        assertEquals(1, motions)
        play(1, 60)
        assertEquals(1, motions)
    }

    @Test
    fun videoUnderASubtitleStaysIgnoredWhenOurBoxIsNotCaptured() {
        var t = 1_000L
        repeat(150) { feed(it % 3, t); t += 33 }  // full-contrast motion every frame
        assertEquals(0, motions)
    }

    /** Lets time pass with no new frame, running whatever was scheduled. */
    private fun idle(until: Long) {
        while (true) {
            val next = tasks.filter { !it.cancelled && it.at <= until }.minByOrNull { it.at } ?: break
            tasks.remove(next)
            now = next.at
            next.block()
        }
        now = until
    }

    @Test
    fun aNewLineUnderABoxIsSeenWithoutAnotherFrame() {
        feed(0, 1_000)          // the page, with its box just drawn
        idle(1_600)             // no frame after the box settled: still recorded
        assertEquals(0, motions)

        feed(1, 2_000)          // the next line; then the screen stays still
        assertEquals("one frame alone can't tell a new line from motion", 0, motions)
        idle(3_000)
        assertEquals(1, motions)

        idle(10_000)            // acknowledged once, not again
        assertEquals(1, motions)
    }

    @Test
    fun aBoxDrawnWithNoFrameIsReadyForTheNextPage() {
        boxShown = false
        makeStabilizer(withBox = true)
        feed(0, 1_000)          // a page, not yet translated
        idle(2_000)
        val before = motions
        drawBox()               // its translation appears; one app shared: no frame
        idle(5_000)
        feed(1, 5_000)          // the next page, then nothing
        idle(8_000)
        assertEquals(before + 1, motions)
    }

    @Test
    fun aRealNextFrameStillDecidesWhenFramesKeepComing() {
        feed(0, 1_000)
        feed(0, 1_500)          // entire screen: the sharing timer's next frame
        feed(1, 2_000)
        feed(1, 2_100)          // settled, seen on the next real frame
        assertEquals(1, motions)
        idle(10_000)            // the pending re-check was replaced, not repeated
        assertEquals(1, motions)
    }

    @Test
    fun videoUnderASubtitleIsIgnoredWhileItPlays() {
        feed(0, 1_000)
        idle(1_600)
        var t = 2_000L
        repeat(10) { feed(it % 2, t); t += 100 }  // keeps moving under the box
        idle(t + 1_000)         // a pause shorter than the animation window
        assertEquals(0, motions)
        // Still for longer: from here it is a still picture that differs from
        // what was translated, as the entire-screen capture's every-second
        // frames would also find.
        idle(t + 5_000)
        assertEquals(1, motions)
    }

    @Test
    fun aStillPageAfterAnAnimatedSceneIsSeenWithoutAnotherFrame() {
        makeStabilizer(withBox = false)
        // A game scene animates across the screen for a while, long enough
        // to count as animation rather than a scroll...
        var t = 1_000L
        repeat(30) { feed(it % 2 + 10, t); t += 100 }
        val before = motions
        // ...then a still page replaces it, and the screen stays still.
        feed(20, t)
        assertEquals("taken for more animation at first", before, motions)
        idle(t + 5_000)
        assertEquals(before + 1, motions)
    }
}
