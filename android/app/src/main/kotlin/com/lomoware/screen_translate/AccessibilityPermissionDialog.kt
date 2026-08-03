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
                                   (!isAccessibilityServiceEnabled() && !isAccessibilityPrompted())

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
        } catch (e: Exception) {
            Log.e(TAG, "Error showing accessibility dialog", e)
        }
    }

    // Check if Accessibility Service is enabled
    fun isAccessibilityServiceEnabled(): Boolean {
        return try {
            // Check if the service is running and permission is granted
            val accessibilityManager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
            
            // Get all accessibility services
            val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            
            // Check if our specific service is in the list of enabled services
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
