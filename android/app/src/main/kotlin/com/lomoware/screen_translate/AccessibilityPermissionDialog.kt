package com.lomoware.screen_translate

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityManager

class AccessibilityPermissionDialog(private val context: Context) {

    companion object {
        private const val TAG = "AccessibilityPermissionDialog"
        private const val PREFS_NAME = "AccessibilityPrefs"
        private const val PREF_FIRST_LAUNCH = "first_launch"
        private const val PREF_ACCESSIBILITY_PROMPTED = "accessibility_prompted"
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun show(forceShow: Boolean = false) {
        try {
            // Check if we should show the dialog
            val shouldShowDialog = forceShow || 
                                   isFirstLaunch() || 
                                   !isAccessibilityServiceEnabled() || 
                                   isAccessibilityPermissionDenied()
            
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

    // Determine if we should show the dialog
    private fun shouldShowDialog(): Boolean {
        // Always show on first launch
        if (isFirstLaunch()) {
            Log.d(TAG, "First launch detected")
            markFirstLaunchComplete()
            return true
        }

        // Check if accessibility service is not enabled
        val shouldShow = !isAccessibilityServiceEnabled()
        
        Log.d(TAG, "Should show dialog: $shouldShow")
        return shouldShow
    }

    // Method to check if accessibility permission is explicitly denied
    fun isAccessibilityPermissionDenied(): Boolean {
        return try {
            val accessibilityManager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
            
            // Get all accessibility services
            val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            
            // If no services are enabled, it might mean the user explicitly denied the permission
            val isDenied = enabledServices.isEmpty()
            
            Log.d(TAG, "Accessibility permission explicitly denied: $isDenied")
            isDenied
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility permission status", e)
            false
        }
    }

    // Check if this is the first launch of the app
    private fun isFirstLaunch(): Boolean {
        return prefs.getBoolean(PREF_FIRST_LAUNCH, true)
    }

    // Mark first launch as complete
    private fun markFirstLaunchComplete() {
        prefs.edit().putBoolean(PREF_FIRST_LAUNCH, false).apply()
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
