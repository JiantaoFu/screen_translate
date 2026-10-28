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

    fun show(forceShow: Boolean = false) {
        try {
            // Show once: on first launch, or any time the service isn't
            // enabled and we haven't already asked. Most users have zero
            // accessibility services enabled by default, so treating "none
            // enabled" as "denied" (as this used to) made the dialog pop up
            // on every cold start even after the user dismissed it.
            val shouldShowDialog = forceShow ||
                                   (!isServiceEnabled(context) && !isAccessibilityPrompted())

            if (!shouldShowDialog) {
                Log.d(TAG, "Dialog should not be shown")
                return
            }

            // Launch the dedicated accessibility permission activity
            val intent = Intent(context, AccessibilityPermissionActivity::class.java).apply {
                // Ensure the activity is launched from a valid context
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                         Intent.FLAG_ACTIVITY_CLEAR_TOP or 
                         Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }

            // Use context.startActivity to ensure proper context handling
            context.startActivity(intent)

            // Mark that we've prompted the user
            markAccessibilityPrompted()
            AccessibilityFunnelStore.forContext(context).markPromptShown()
        } catch (e: Exception) {
            Log.e(TAG, "Error showing accessibility dialog", e)
        }
    }

    // Check if user has been prompted about accessibility before
    private fun isAccessibilityPrompted(): Boolean {
        return prefs.getBoolean(PREF_ACCESSIBILITY_PROMPTED, false)
    }

    // Mark that user has been prompted about accessibility
    private fun markAccessibilityPrompted() {
        prefs.edit().putBoolean(PREF_ACCESSIBILITY_PROMPTED, true).apply()
    }

    // Method to reset accessibility prompts (for settings)
    fun resetAccessibilityPrompt() {
        prefs.edit().remove(PREF_ACCESSIBILITY_PROMPTED).apply()
        Log.d(TAG, "Accessibility prompt reset")
    }
}
