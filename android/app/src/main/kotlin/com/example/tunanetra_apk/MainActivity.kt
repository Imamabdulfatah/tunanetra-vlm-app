package com.example.tunanetra_apk

import android.content.Context
import android.telecom.TelecomManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.whatsapp"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "endCall") {
                try {
                    val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                    if (telecomManager == null) {
                        Log.e(TAG, "TelecomManager is not available")
                        result.error("SERVICE_UNAVAILABLE", "Telecom service not available", null)
                        return@setMethodCallHandler
                    }
                    if (checkSelfPermission(android.Manifest.permission.ANSWER_PHONE_CALLS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        Log.w(TAG, "ANSWER_PHONE_CALLS permission not granted")
                        result.error("PERMISSION_DENIED", "Permission to end calls not granted", null)
                        return@setMethodCallHandler
                    }
                    telecomManager.endCall()
                    Log.i(TAG, "Call ended successfully")
                    result.success("Call ended successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to end call: ${e.message}", e)
                    result.error("END_CALL_FAILED", "Failed to end call: ${e.message}", null)
                }
            } else {
                Log.w(TAG, "Method not implemented: ${call.method}")
                result.notImplemented()
            }
        }
    }
}
