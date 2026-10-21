package com.lomoware.screen_translate

import android.content.Context

/**
 * What happened to the one-time accessibility explainer, kept until Dart
 * picks it up for analytics (lib/services/accessibility_funnel_reporter.dart).
 *
 * The explainer is shown natively, often before Dart is in front, so native
 * only records two facts: the prompt was shown, and how the user left it.
 * [take] hands both over once and clears them, so each analytics event is
 * sent once. The enabled/disabled result is read when Dart asks, i.e. when
 * the user is back in the app (after Settings, if they went there).
 * No screen content is involved: only flags and a fixed action code.
 */
class AccessibilityFunnelStore(private val kv: KeyValue) {

    /** The bits of SharedPreferences this needs; a map in unit tests. */
    interface KeyValue {
        fun getBoolean(key: String): Boolean
        fun getString(key: String): String?

        /**
         * Stores every entry as a single write. Values are Boolean or
         * String; null removes the key. One write per call matters: these
         * are synchronous commits (see [forContext]) on the main thread,
         * during app start and in the explainer's onPause.
         */
        fun write(values: Map<String, Any?>)
    }

    companion object {
        const val PREFS_NAME = "AccessibilityFunnel"
        const val KEY_PROMPT_SHOWN = "prompt_shown_pending"
        const val KEY_RESULT_PENDING = "result_pending"
        const val KEY_ACTION = "close_action"

        const val ACTION_SETTINGS_OPENED = "settings_opened"
        const val ACTION_DISMISSED = "dismissed"
        const val ACTION_ALREADY_ENABLED = "already_enabled"

        fun forContext(context: Context): AccessibilityFunnelStore {
            val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return AccessibilityFunnelStore(object : KeyValue {
                override fun getBoolean(key: String) = prefs.getBoolean(key, false)
                override fun getString(key: String) = prefs.getString(key, null)
                override fun write(values: Map<String, Any?>) {
                    val editor = prefs.edit()
                    for ((key, value) in values) {
                        when (value) {
                            is Boolean -> editor.putBoolean(key, value)
                            is String -> editor.putString(key, value)
                            null -> editor.remove(key)
                            else -> throw IllegalArgumentException("Unsupported value for $key")
                        }
                    }
                    // commit(), not apply(): Dart may ask right after the
                    // explainer closes, from another thread, and the result
                    // has to survive the process being killed while the user
                    // is away in Settings.
                    editor.commit()
                }
            })
        }
    }

    /** The explainer was launched. A new showing restarts the result. */
    fun markPromptShown() {
        kv.write(
            mapOf(
                KEY_PROMPT_SHOWN to true,
                KEY_RESULT_PENDING to false,
                KEY_ACTION to null,
            )
        )
    }

    /** The explainer is closing; [action] is one of the ACTION_ codes. */
    fun markPromptClosed(action: String) {
        kv.write(
            mapOf(
                KEY_RESULT_PENDING to true,
                KEY_ACTION to action,
            )
        )
    }

    /**
     * Everything not yet handed to Dart, then cleared:
     * `promptShown` (Boolean) and, once the explainer has closed,
     * `result` = {enabled: Boolean, action: String}. [isEnabled] is only
     * asked when there is a result to report. Nothing pending means no
     * write at all — this runs on every app start and resume.
     */
    fun take(isEnabled: () -> Boolean): Map<String, Any> {
        val out = mutableMapOf<String, Any>()
        val cleared = mutableMapOf<String, Any?>()
        val promptShown = kv.getBoolean(KEY_PROMPT_SHOWN)
        out["promptShown"] = promptShown
        if (promptShown) cleared[KEY_PROMPT_SHOWN] = false
        if (kv.getBoolean(KEY_RESULT_PENDING)) {
            out["result"] = mapOf(
                "enabled" to isEnabled(),
                "action" to (kv.getString(KEY_ACTION) ?: "unknown"),
            )
            cleared[KEY_RESULT_PENDING] = false
            cleared[KEY_ACTION] = null
        }
        if (cleared.isNotEmpty()) kv.write(cleared)
        return out
    }
}
