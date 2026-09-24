package com.lomoware.screen_translate

import android.graphics.Rect
import android.os.SystemClock
import android.view.View
import android.view.ViewTreeObserver

/**
 * Screen-space rects currently covered by this app's own floating windows
 * (translated text boxes, control buttons, tooltips, dialogs).
 *
 * MediaProjection captures every window on screen, including ours, so
 * without this the capture pipeline sees its own overlays as screen
 * changes: drawing a translation changed the frame, which triggered
 * "motion detected" → hideAll → retranslate → draw → ..., and no
 * translation ever stayed on screen. FrameStabilizer ignores these regions
 * when deciding whether the underlying content changed.
 *
 * Written on the main thread (view callbacks), read from the ImageReader
 * thread via [snapshot].
 */
object OverlayRegions {
    // Covers elevation shadows drawn outside the view bounds.
    private const val MARGIN_PX = 12
    // A removed/moved window's old rect stays masked this long, so frames
    // rendered before the change but delivered after it still ignore it.
    private const val GHOST_MS = 200L
    // Keeps the edges of a box (antialiasing, shadow) out of textBoxRects.
    private const val INNER_INSET_PX = 6

    private val lock = Any()
    private val live = HashMap<View, Rect>()
    private val ghosts = ArrayList<Pair<Rect, Long>>()
    // Weak: a control stays a control across detach/re-attach (buttons are
    // re-added to stay on top) and is dropped once the view is gone.
    private val controls: MutableSet<View> = java.util.Collections.newSetFromMap(java.util.WeakHashMap())
    // Bumped whenever a window is added, moved or removed.
    @Volatile private var version = 0L

    /**
     * Call once per view, before it is first added to the WindowManager.
     * [isControl] marks our buttons/tooltips: unlike translated text boxes,
     * they're blanked out of frames before OCR (see [controlRects]).
     */
    fun track(view: View, isControl: Boolean = false) {
        if (isControl) synchronized(lock) { controls.add(view) }
        view.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            // Pre-draw runs after layout but before the window's first draw,
            // so the rect is registered before any frame containing it can
            // be captured.
            private val preDraw = ViewTreeObserver.OnPreDrawListener {
                update(view)
                true
            }

            override fun onViewAttachedToWindow(v: View) {
                v.viewTreeObserver.addOnPreDrawListener(preDraw)
            }

            override fun onViewDetachedFromWindow(v: View) {
                v.viewTreeObserver.removeOnPreDrawListener(preDraw)
                remove(v)
            }
        })
    }

    private fun update(view: View) {
        if (view.width == 0 || view.height == 0) return
        val loc = IntArray(2)
        view.getLocationOnScreen(loc)
        val rect = Rect(
            loc[0] - MARGIN_PX, loc[1] - MARGIN_PX,
            loc[0] + view.width + MARGIN_PX, loc[1] + view.height + MARGIN_PX
        )
        synchronized(lock) {
            val old = live.put(view, rect)
            if (old != rect) version++
            if (old != null && old != rect) {
                ghosts.add(old to SystemClock.uptimeMillis() + GHOST_MS)
            }
        }
    }

    private fun remove(view: View) {
        synchronized(lock) {
            live.remove(view)?.let {
                ghosts.add(it to SystemClock.uptimeMillis() + GHOST_MS)
                version++
            }
        }
    }

    /**
     * Whether the status bar is currently shown (false while a game or
     * video runs immersive and draws its own content there). Updated from
     * our control button's window insets.
     */
    @Volatile var statusBarVisible = true

    /** Changes whenever the set or position of our windows changes. */
    fun version(): Long = version

    /**
     * Inner rects of our translated text boxes (not controls), inset past
     * the margin and shadow so only the box's own face is covered.
     */
    fun textBoxRects(): List<Rect> = synchronized(lock) {
        live.filterKeys { it !in controls }.values.map {
            Rect(it).apply { inset(MARGIN_PX + INNER_INSET_PX, MARGIN_PX + INNER_INSET_PX) }
        }.filter { !it.isEmpty }
    }

    /**
     * Rects of our on-screen control windows. OCR read the translate
     * button's glyph icon as text ("xa") and put a translated box under it.
     */
    fun controlRects(): List<Rect> = synchronized(lock) {
        controls.mapNotNull { live[it]?.let(::Rect) }
    }

    fun snapshot(): List<Rect> {
        val now = SystemClock.uptimeMillis()
        synchronized(lock) {
            ghosts.removeAll { it.second <= now }
            return live.values.map { Rect(it) } + ghosts.map { Rect(it.first) }
        }
    }
}
