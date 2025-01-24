package com.lomoware.screen_translate

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lomoware.screen_translate/screen_capture"
    private val PERMISSION_CODE = 1000
    private var screenCaptureService: ScreenCaptureService? = null
    private var pendingResult: MethodChannel.Result? = null
    private val TAG = "MainActivity"
    private var permissionData: Intent? = null
    private val OVERLAY_CHANNEL = "com.lomoware.screen_translate/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        screenCaptureService = ScreenCaptureService(context, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestScreenCapture" -> {
                    Log.d(TAG, "Requesting screen capture permission")
                    pendingResult = result
                    startScreenCapture()
                }
                "startScreenCapture" -> {
                    try {
                        val resultCode = call.argument<Int>("resultCode") ?: Activity.RESULT_CANCELED
                        Log.d(TAG, "Starting screen capture with result code: $resultCode")
                        Log.d(TAG, "Permission data available: ${permissionData != null}")
                        
                        if (resultCode != Activity.RESULT_OK) {
                            result.error("PERMISSION_DENIED", "Screen capture permission denied", null)
                            return@setMethodCallHandler
                        }

                        if (permissionData == null) {
                            result.error("NO_PERMISSION_DATA", "No screen capture permission data available", null)
                            return@setMethodCallHandler
                        }
                        
                        // Log the permission data before starting projection
                        Log.d(TAG, "Permission Intent: $permissionData")
                        Log.d(TAG, "Permission Intent extras: ${permissionData?.extras}")
                        Log.d(TAG, "Permission Intent flags: ${permissionData?.flags}")
                        
                        // Create a fresh copy of the permission data
                        val permissionIntent = Intent(permissionData).apply {
                            flags = permissionData!!.flags
                            action = permissionData!!.action
                            data = permissionData!!.data
                            permissionData!!.extras?.let { putExtras(it) }
                        }
                        
                        Log.d(TAG, "Copied Permission Intent: $permissionIntent")
                        Log.d(TAG, "Copied Permission Intent extras: ${permissionIntent.extras}")
                        Log.d(TAG, "Copied Permission Intent flags: ${permissionIntent.flags}")
                        
                        screenCaptureService?.startProjection(resultCode, permissionIntent, result)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting screen capture", e)
                        result.error("START_ERROR", "Failed to start screen capture: ${e.message}", null)
                    }
                }
                "stopScreenCapture" -> {
                    screenCaptureService?.stopProjection()
                    result.success(null)
                }
                "captureScreen" -> {
                    screenCaptureService?.captureScreen(result)
                }
                else -> result.notImplemented()
            }
        }

        // Set up overlay channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(OverlayService.hasOverlayPermission(this))
                }
                "requestOverlayPermission" -> {
                    OverlayService.requestOverlayPermission(this)
                    result.success(true)
                }
                "showTranslationOverlay" -> {
                    val text = call.argument<String>("text")
                    val x = call.argument<Double>("x")?.toFloat()
                    val y = call.argument<Double>("y")?.toFloat()
                    val width = call.argument<Double>("width")?.toFloat()
                    val height = call.argument<Double>("height")?.toFloat()
                    val id = call.argument<Int>("id")
                    if (text != null && id != null) {
                        val intent = Intent(this, OverlayService::class.java)
                        intent.action = "show"
                        intent.putExtra("text", text)
                        intent.putExtra("id", id)
                        if (x != null && y != null) {
                            intent.putExtra("x", x)
                            intent.putExtra("y", y)
                        }
                        if (width != null) {
                            intent.putExtra("width", width)
                        }
                        if (height != null) {
                            intent.putExtra("height", height)
                        }
                        startService(intent)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Text and id arguments are required", null)
                    }
                }
                "hideTranslationOverlay" -> {
                    val intent = Intent(this, OverlayService::class.java)
                    intent.action = "hideAll"
                    startService(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startScreenCapture() {
        try {
            val mpManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            startActivityForResult(mpManager.createScreenCaptureIntent(), PERMISSION_CODE)
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting screen capture", e)
            pendingResult?.error("REQUEST_ERROR", "Failed to request screen capture: ${e.message}", null)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == PERMISSION_CODE) {
            Log.d(TAG, "Received activity result: code=$resultCode")
            Log.d(TAG, "Received Intent data: $data")
            Log.d(TAG, "Received Intent extras: ${data?.extras}")
            
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Store a copy of the permission data
                permissionData = Intent(data).apply {
                    flags = data.flags
                    action = data.action
                    this.data = data.data
                    data.extras?.let { putExtras(it) }
                }
                
                Log.d(TAG, "Stored permission Intent: $permissionData")
                Log.d(TAG, "Stored permission Intent extras: ${permissionData?.extras}")
                
                val intentData = mapOf(
                    "resultCode" to resultCode,
                    "intentAction" to (data.action ?: ""),
                    "intentFlags" to data.flags,
                    "intentDataString" to (data.dataString ?: "")
                )
                Log.d(TAG, "Screen capture permission granted, sending result")
                pendingResult?.success(intentData)
            } else {
                Log.e(TAG, "Screen capture permission denied")
                pendingResult?.error("PERMISSION_DENIED", "Screen capture permission denied", null)
            }
            pendingResult = null
        }
    }
}
