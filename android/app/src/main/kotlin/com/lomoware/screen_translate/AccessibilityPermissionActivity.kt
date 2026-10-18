package com.lomoware.screen_translate

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat

class AccessibilityPermissionActivity : AppCompatActivity() {

    // How the user leaves this screen, for analytics (AccessibilityFunnelStore).
    // Back / swipe away counts as dismissed.
    private var closeAction = AccessibilityFunnelStore.ACTION_DISMISSED

    companion object {
        private const val TAG = "AccessibilityPermissionActivity"
        private const val ACCESSIBILITY_SETTINGS = android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS

        fun createIntent(context: Context): Intent {
            return Intent(context, AccessibilityPermissionActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_accessibility_permission)

        // Find views
        val tvMessage = findViewById<TextView>(R.id.tvAccessibilityMessage)
        val tvBenefits = findViewById<TextView>(R.id.tvAccessibilityBenefits)
        val tvHowTo = findViewById<TextView>(R.id.tvAccessibilityHowTo)
        val btnEnable = findViewById<Button>(R.id.btnEnableAccessibility)
        val btnCancel = findViewById<Button>(R.id.btnCancelAccessibility)

        // Set text
        tvMessage.text = getString(R.string.accessibility_permission_message)
        tvBenefits.text = getString(R.string.accessibility_permission_benefits)
        tvHowTo.text = getString(R.string.accessibility_permission_how_to)

        // Enable button
        btnEnable.setOnClickListener {
            try {
                // Open Accessibility Settings
                val intent = Intent(ACCESSIBILITY_SETTINGS)
                startActivity(intent)
                closeAction = AccessibilityFunnelStore.ACTION_SETTINGS_OPENED
                finish()
            } catch (e: Exception) {
                Log.e(TAG, "Error opening accessibility settings", e)
            }
        }

        // Cancel button
        btnCancel.setOnClickListener {
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        // Check if accessibility service is already enabled
        if (isAccessibilityServiceEnabled()) {
            closeAction = AccessibilityFunnelStore.ACTION_ALREADY_ENABLED
            finish()
        }
    }

    override fun onPause() {
        super.onPause()
        // onPause, not onDestroy: the activity underneath (MainActivity) is
        // resumed before this one is destroyed, and that resume is when Dart
        // asks for the result.
        if (isFinishing) {
            try {
                AccessibilityFunnelStore.forContext(this).markPromptClosed(closeAction)
            } catch (e: Exception) {
                Log.e(TAG, "Error recording accessibility prompt result", e)
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        return try {
            ScrollDetectionAccessibilityService.instance != null
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility service", e)
            false
        }
    }
}
