package com.lomoware.screen_translate

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.accessibility.AccessibilityManager

class AccessibilityPermissionDialog(private val context: Context) {

    companion object {
        private const val TAG = "AccessibilityPermissionDialog"
        private const val PREFS_NAME = "AccessibilityPrefs"
        private const val PREF_ACCESSIBILITY_PROMPTED = "accessibility_prompted"
        private const val PREF_PROMPT_ATTEMPTS = "accessibility_prompt_attempts"

        /**
         * How many launches to try before giving up on the explainer.
         *
         * Only the activity can confirm it was shown, so a launch the system
         * drops leaves nothing marked and the next resume tries again. Without
         * a cap, a launch that can never succeed would be retried on every
         * single resume, and would take the review prompt's turn every time.
         */
        private const val MAX_PROMPT_ATTEMPTS = 3

        /**
         * Whether our accessibility service is enabled in system settings.
         *
         * The single answer to that question: everything that shows, closes
         * or reports on the explainer asks this, so the prompt's trigger and
         * the `enabled` it reports to analytics can never disagree. Note
         * this is the system setting, not whether the service object has
         * been bound yet — ScrollDetectionAccessibilityService.instance lags
         * behind it by however long the system takes to create the service.
         */
        /**
         * Record that the user has now been shown the explainer.
         *
         * Called by AccessibilityPermissionActivity.onCreate, not by [show]:
         * startActivity does not fail loudly when the system refuses a
         * background launch, so marking it here is the only way the flag
         * means "the user saw it" rather than "we asked for it". Marking on
         * the request burned the single showing this prompt ever gets.
         */
        fun markPrompted(context: Context) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit().putBoolean(PREF_ACCESSIBILITY_PROMPTED, true).apply()
        }

        fun isServiceEnabled(context: Context): Boolean {
            return try {
                val accessibilityManager =
                    context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
                val enabledServices = accessibilityManager
                    .getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                val isEnabled = enabledServices.any { serviceInfo ->
                    serviceInfo.resolveInfo.serviceInfo.packageName == context.packageName &&
                        serviceInfo.resolveInfo.serviceInfo.name.contains("ScrollDetectionAccessibilityService")
                }
                Log.d(TAG, "Accessibility service enabled: $isEnabled")
                isEnabled
            } catch (e: Exception) {
                Log.e(TAG, "Error checking accessibility service", e)
                false
            }
        }
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * True if an explainer launch was issued.
     *
     * "Issued", not "seen": the activity marks itself as shown. The caller
     * uses this only to decide whether to leave this resume alone, so being
     * optimistic here costs at most one skipped review prompt, whereas
     * marking a launch that never happened costs the explainer entirely.
     */
    fun show(forceShow: Boolean = false): Boolean {
        // Lite has no accessibility service, so it must never explain one.
        // The guard lives here rather than at the call site: it used to sit
        // in ScreenCaptureService.checkAccessibilityServiceOnFirstLaunch(),
        // and the moment a second caller appeared it would have been missed.
        if (BuildConfig.FLAVOR == "lite") return false
        try {
            // Show once: on first launch, or any time the service isn't
            // enabled and we haven't already asked. Most users have zero
            // accessibility services enabled by default, so treating "none
            // enabled" as "denied" (as this used to) made the dialog pop up
            // on every cold start even after the user dismissed it.
            val attempts = prefs.getInt(PREF_PROMPT_ATTEMPTS, 0)
            val shouldShowDialog = forceShow ||
                                   (!isServiceEnabled(context) &&
                                    !isAccessibilityPrompted() &&
                                    attempts < MAX_PROMPT_ATTEMPTS)

            if (!shouldShowDialog) {
                Log.d(TAG, "Dialog should not be shown")
                return false
            }

            // Launch the dedicated accessibility permission activity
            val intent = Intent(context, AccessibilityPermissionActivity::class.java).apply {
                // Ensure the activity is launched from a valid context
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                         Intent.FLAG_ACTIVITY_CLEAR_TOP or 
                         Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }

            // Use context.startActivity to ensure proper context handling.
            // The activity records that it was shown; see markPrompted.
            context.startActivity(intent)
            prefs.edit().putInt(PREF_PROMPT_ATTEMPTS, attempts + 1).apply()
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error showing accessibility dialog", e)
            return false
        }
    }

    // Check if user has been prompted about accessibility before
    private fun isAccessibilityPrompted(): Boolean {
        return prefs.getBoolean(PREF_ACCESSIBILITY_PROMPTED, false)
    }

    // Method to reset accessibility prompts (for settings)
    fun resetAccessibilityPrompt() {
        prefs.edit()
            .remove(PREF_ACCESSIBILITY_PROMPTED)
            .remove(PREF_PROMPT_ATTEMPTS)
            .apply()
        Log.d(TAG, "Accessibility prompt reset")
    }
}
