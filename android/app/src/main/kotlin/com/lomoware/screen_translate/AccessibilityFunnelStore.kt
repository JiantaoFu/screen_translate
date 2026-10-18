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
        fun putBoolean(key: String, value: Boolean)
        fun putString(key: String, value: String?)
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
                // commit(), not apply(): Dart may ask right after the
                // explainer closes, from another thread.
                override fun putBoolean(key: String, value: Boolean) {
                    prefs.edit().putBoolean(key, value).commit()
                }
                override fun putString(key: String, value: String?) {
                    prefs.edit().putString(key, value).commit()
                }
            })
        }
    }

    /** The explainer was launched. A new showing restarts the result. */
    fun markPromptShown() {
        kv.putBoolean(KEY_PROMPT_SHOWN, true)
        kv.putBoolean(KEY_RESULT_PENDING, false)
        kv.putString(KEY_ACTION, null)
    }

    /** The explainer is closing; [action] is one of the ACTION_ codes. */
    fun markPromptClosed(action: String) {
        kv.putBoolean(KEY_RESULT_PENDING, true)
        kv.putString(KEY_ACTION, action)
    }

    /**
     * Everything not yet handed to Dart, then cleared:
     * `promptShown` (Boolean) and, once the explainer has closed,
     * `result` = {enabled: Boolean, action: String}. [isEnabled] is only
     * asked when there is a result to report.
     */
    fun take(isEnabled: () -> Boolean): Map<String, Any> {
        val out = mutableMapOf<String, Any>()
        val promptShown = kv.getBoolean(KEY_PROMPT_SHOWN)
        out["promptShown"] = promptShown
        if (promptShown) kv.putBoolean(KEY_PROMPT_SHOWN, false)
        if (kv.getBoolean(KEY_RESULT_PENDING)) {
            out["result"] = mapOf(
                "enabled" to isEnabled(),
                "action" to (kv.getString(KEY_ACTION) ?: "unknown"),
            )
            kv.putBoolean(KEY_RESULT_PENDING, false)
            kv.putString(KEY_ACTION, null)
        }
        return out
    }
}
