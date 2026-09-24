package com.lomoware.screen_translate

enum class FrameChange {
    /** Nothing meaningful changed (noise, a blinking cursor). */
    NONE,
    /** The screen content changed: new page, scroll, new dialogue line. */
    CONTENT,
    /** Only regions that are continuously animating changed (video, animated game scene). */
    ANIMATION,
}

/**
 * Tells real content changes apart from ongoing animation, per sample point
 * of a [cols] x [rows] grid.
 *
 * Previously any frame-to-frame difference counted as a content change, so a
 * playing video anywhere on screen (an X/Twitter feed, a game's animated
 * background) produced a "change" every frame: the screen never counted as
 * settled, OCR never ran, and existing translations were cleared on every
 * frame. Here a neighbourhood that keeps moving on consecutive frames is
 * treated as animated, and changes confined to animated samples are reported
 * separately so the caller can keep translating the static text around them.
 *
 * Two signals per frame: `moved` (any luma difference, used to learn where
 * things animate — static text on a screen capture is pixel-identical frame to
 * frame, while slow fades/pans change luma by a few levels per frame) and
 * `changed` (a difference big enough to matter as content).
 */
class MotionClassifier(private val cols: Int, private val rows: Int) {

    companion object {
        /** Movement on this many consecutive frames makes a sample "animated". */
        const val ANIMATION_STREAK = 3
        /**
         * Movement later than this after the previous one starts a new
         * streak. Long enough to bridge a sprite/character pausing in place
         * (the flat interior of a moving object doesn't change while it
         * passes over a sample), matching the animation refresh interval.
         */
        const val STREAK_GAP_MS = 2500L
        /** Fewer changed samples than this is noise (e.g. a blinking cursor). */
        const val MIN_CHANGED_SAMPLES = 3
        /**
         * When at least this share of the screen is "animated" it may just be a
         * scroll (everything moves for a few frames) rather than animation...
         */
        const val MAJORITY_ANIMATED = 0.5
        /** ...so it is only accepted as animation once it has lasted this long. */
        const val GLOBAL_MOTION_GRACE_MS = 1500L
    }

    private val sampleCount = cols * rows
    private val lastMove = LongArray(sampleCount) { Long.MIN_VALUE / 2 }
    private val streak = IntArray(sampleCount)
    private var globalMotionSince = -1L

    fun isAnimated(i: Int, now: Long): Boolean =
        streak[i] >= ANIMATION_STREAK && now - lastMove[i] <= STREAK_GAP_MS

    /**
     * @param changed per-sample "differs meaningfully from the previous frame"
     *        flags, with our own overlay windows already masked out.
     * @param moved per-sample "differs at all" flags (a superset of [changed]).
     */
    fun classify(changed: BooleanArray, moved: BooleanArray, now: Long): FrameChange {
        require(changed.size == sampleCount && moved.size == sampleCount)
        // A moving sprite only touches a given sample as its edge passes, so
        // judge motion over each sample's 3x3 neighbourhood.
        val movedNear = BooleanArray(sampleCount)
        for (r in 0 until rows) for (c in 0 until cols) {
            if (!moved[r * cols + c]) continue
            for (dr in -1..1) for (dc in -1..1) {
                val rr = r + dr
                val cc = c + dc
                if (rr in 0 until rows && cc in 0 until cols) movedNear[rr * cols + cc] = true
            }
        }

        var content = 0
        var animated = 0
        var animatedSamples = 0
        for (i in 0 until sampleCount) {
            val wasAnimated = isAnimated(i, now)
            if (changed[i]) {
                if (wasAnimated) animated++ else content++
            }
            if (movedNear[i]) {
                streak[i] = if (now - lastMove[i] <= STREAK_GAP_MS) streak[i] + 1 else 1
                lastMove[i] = now
            }
            if (isAnimated(i, now)) animatedSamples++
        }

        if (animatedSamples >= sampleCount * MAJORITY_ANIMATED) {
            if (globalMotionSince < 0) globalMotionSince = now
            if (now - globalMotionSince < GLOBAL_MOTION_GRACE_MS) {
                content += animated
                animated = 0
            }
        } else {
            globalMotionSince = -1L
        }

        return when {
            content >= MIN_CHANGED_SAMPLES -> FrameChange.CONTENT
            content + animated >= MIN_CHANGED_SAMPLES && animated > 0 -> FrameChange.ANIMATION
            else -> FrameChange.NONE
        }
    }
}
