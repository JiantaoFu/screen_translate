package com.lomoware.screen_translate

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MotionClassifierTest {

    private val cols = 20
    private val rows = 20
    private val n = cols * rows
    private val frameMs = 33L

    private fun flags(indices: Iterable<Int>) = BooleanArray(n).also { a -> indices.forEach { a[it] = true } }
    private fun rect(r0: Int, r1: Int, c0: Int, c1: Int) =
        (r0..r1).flatMap { r -> (c0..c1).map { c -> r * cols + c } }

    /** Frames where [indices] change by a lot (changed and moved). */
    private fun run(c: MotionClassifier, startMs: Long, frames: Int, indices: Iterable<Int>): List<FrameChange> =
        (0 until frames).map { c.classify(flags(indices), flags(indices), startMs + it * frameMs) }

    private val video = rect(6, 11, 0, 19) // a full-width band, 30% of the screen

    @Test
    fun `a playing video region settles into animation after the first frames`() {
        val c = MotionClassifier(cols, rows)
        val result = run(c, 0, 60, video)
        assertEquals(FrameChange.CONTENT, result.first())
        assertTrue(result.drop(MotionClassifier.ANIMATION_STREAK).all { it == FrameChange.ANIMATION })
    }

    @Test
    fun `new static text next to a playing video is still a content change`() {
        val c = MotionClassifier(cols, rows)
        run(c, 0, 30, video)
        val text = rect(16, 17, 0, 19) // not adjacent to the video band
        assertEquals(FrameChange.CONTENT, c.classify(flags(video + text), flags(video + text), 30 * frameMs))
    }

    @Test
    fun `a slow fade is learned as animation before it adds up to a big change`() {
        val c = MotionClassifier(cols, rows)
        val scene = rect(0, 7, 0, 19) // 40% of the screen
        // Each frame moves luma a little (moved, not changed)...
        repeat(30) { c.classify(flags(emptyList()), flags(scene), it * frameMs) }
        // ...so once a sample does cross the change threshold, it's animation.
        assertEquals(FrameChange.ANIMATION, c.classify(flags(scene), flags(scene), 30 * frameMs))
        assertTrue(scene.all { c.isAnimated(it, 30 * frameMs) })
    }

    @Test
    fun `a moving sprite marks its surroundings as animated`() {
        val c = MotionClassifier(cols, rows)
        // A sprite crossing row 4 left to right, one sample every 100ms.
        var t = 0L
        for (col in 0 until cols) {
            val here = listOf(4 * cols + col)
            c.classify(flags(here), flags(here), t)
            t += 100
        }
        // Samples it passed, and their neighbours, count as animated.
        assertTrue(c.isAnimated(4 * cols + 15, t))
        assertTrue(c.isAnimated(5 * cols + 15, t))
        assertFalse(c.isAnimated(12 * cols + 15, t))
    }

    @Test
    fun `a scroll stays a content change for the grace period`() {
        val c = MotionClassifier(cols, rows)
        val scrollFrames = (MotionClassifier.GLOBAL_MOTION_GRACE_MS / frameMs).toInt() - 5
        assertTrue(run(c, 0, scrollFrames, 0 until n).all { it == FrameChange.CONTENT })
    }

    @Test
    fun `full-screen motion that outlasts the grace period is animation`() {
        val c = MotionClassifier(cols, rows)
        assertEquals(FrameChange.ANIMATION, run(c, 0, 120, 0 until n).last())
    }

    @Test
    fun `a blinking cursor is noise`() {
        val c = MotionClassifier(cols, rows)
        val cursor = listOf(7, 8)
        val result = (0 until 20).map { c.classify(flags(cursor), flags(cursor), it * 500L) }
        assertTrue(result.all { it == FrameChange.NONE })
    }

    @Test
    fun `a region that stops animating counts as content again`() {
        val c = MotionClassifier(cols, rows)
        run(c, 0, 30, video)
        val t = 30 * frameMs + MotionClassifier.STREAK_GAP_MS + 100
        assertFalse(c.isAnimated(video.first(), t))
        assertEquals(FrameChange.CONTENT, c.classify(flags(video), flags(video), t))
    }
}
