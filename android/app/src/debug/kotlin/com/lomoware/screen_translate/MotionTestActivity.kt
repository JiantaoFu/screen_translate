package com.lomoware.screen_translate

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Debug-only harness for verifying live translation on screens that mix
 * static text with continuous motion — the X/Twitter "feed with an
 * autoplaying video" case and the game "animated background behind a
 * dialogue box" case. Not part of release builds (src/debug).
 *
 *   adb shell am start -n com.lomoware.screen_translate/.MotionTestActivity \
 *       --es mode video|feed|game|typewriter|static [--ei page N] [--ez landscape true]
 *
 * Re-sending the intent with a different `page` swaps the text, simulating
 * navigation to new content (which must still clear and re-translate).
 */
class MotionTestActivity : Activity() {

    private val handler = Handler(Looper.getMainLooper())
    private var typewriter: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        render(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        render(intent)
    }

    override fun onDestroy() {
        typewriter?.let { handler.removeCallbacks(it) }
        super.onDestroy()
    }

    private fun render(intent: Intent) {
        typewriter?.let { handler.removeCallbacks(it) }
        val mode = intent.getStringExtra("mode") ?: "video"
        val page = intent.getIntExtra("page", 0)
        requestedOrientation = if (intent.getBooleanExtra("landscape", false))
            ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE else ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        setContentView(
            when (mode) {
                "game" -> gameLayout(PAGES[page % PAGES.size][0], typeOut = false)
                "typewriter" -> gameLayout(PAGES[page % PAGES.size][0], typeOut = true)
                "static" -> feedLayout(page, withVideo = false)
                "feed" -> longFeedLayout()
                else -> feedLayout(page, withVideo = true)
            }
        )
    }

    // A social-feed-like page: posts above and below a playing "video".
    private fun feedLayout(page: Int, withVideo: Boolean): View {
        val posts = PAGES[page % PAGES.size]
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(16), dp(48), dp(16), dp(16))
            addView(post(posts[0]))
            if (withVideo) {
                addView(AnimatedView(context, fullScreen = false), LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, dp(220)
                ).apply { setMargins(0, dp(12), 0, dp(12)) })
            }
            addView(post(posts[1]))
            addView(post(posts[2]))
        }
    }

    // A long scrollable feed with a video between every few posts.
    private fun longFeedLayout(): View {
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(16), dp(48), dp(16), dp(16))
        }
        PAGES.flatten().plus(PAGES.flatten()).forEachIndexed { i, text ->
            column.addView(post(text))
            if (i % 3 == 1) {
                column.addView(AnimatedView(this, fullScreen = false), LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, dp(200)
                ).apply { setMargins(0, dp(12), 0, dp(12)) })
            }
        }
        return android.widget.ScrollView(this).apply { addView(column) }
    }

    // A visual-novel-like screen: animated scene with a dialogue box.
    private fun gameLayout(line: String, typeOut: Boolean): View {
        val dialogue = TextView(this).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setBackgroundColor(Color.argb(235, 20, 20, 40))
            setPadding(dp(20), dp(16), dp(20), dp(16))
            text = if (typeOut) "" else line
        }
        if (typeOut) {
            var shown = 0
            typewriter = object : Runnable {
                override fun run() {
                    shown++
                    dialogue.text = line.substring(0, shown.coerceAtMost(line.length))
                    if (shown < line.length) handler.postDelayed(this, 45)
                }
            }.also { handler.postDelayed(it, 1500) }
        }
        return FrameLayout(this).apply {
            addView(AnimatedView(context, fullScreen = true))
            addView(dialogue, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM
            ).apply { setMargins(dp(16), 0, dp(16), dp(32)) })
        }
    }

    private fun post(text: String) = TextView(this).apply {
        this.text = text
        setTextColor(Color.BLACK)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
        setPadding(0, dp(12), 0, dp(12))
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    /** Redraws every vsync with large luma swings, like video or particle effects. */
    private class AnimatedView(context: Context, private val fullScreen: Boolean) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val start = System.nanoTime()

        override fun onDraw(canvas: Canvas) {
            val t = (System.nanoTime() - start) / 1_000_000_000f
            val bands = 12
            val bandH = height / bands.toFloat()
            for (i in 0 until bands) {
                val phase = (t * 1.7f + i * 0.37f) % 1f
                val v = (40 + 200 * phase).toInt()
                paint.color = Color.rgb(v, (v + 80) % 256, 255 - v)
                canvas.drawRect(0f, i * bandH, width.toFloat(), (i + 1) * bandH, paint)
            }
            // Moving blobs so motion isn't purely per-band flicker.
            paint.color = Color.WHITE
            for (k in 0 until if (fullScreen) 6 else 3) {
                val x = (width * ((t * (0.21f + k * 0.07f) + k * 0.17f) % 1f))
                val y = height * (0.2f + 0.6f * ((k * 0.29f + t * 0.05f) % 1f))
                canvas.drawCircle(x, y, height * 0.08f, paint)
            }
            postInvalidateOnAnimation()
        }
    }

    private companion object {
        val PAGES = arrayOf(
            arrayOf(
                "The weather is beautiful today, so we decided to walk to the old market by the river.",
                "My brother bought a new camera last week and he takes pictures of everything he sees.",
                "Please remember to close the windows before you leave the house this evening."
            ),
            arrayOf(
                "The train to the mountains leaves at seven in the morning from the central station.",
                "Our teacher told us that the library will be closed for repairs until next month.",
                "She cooked a delicious dinner for her friends and everyone asked for the recipe."
            ),
        )
    }
}
