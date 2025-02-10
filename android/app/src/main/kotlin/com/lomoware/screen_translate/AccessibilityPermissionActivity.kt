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
            finish()
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
