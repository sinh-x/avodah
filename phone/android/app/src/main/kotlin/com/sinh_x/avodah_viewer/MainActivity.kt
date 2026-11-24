package com.sinh_x.avodah_viewer

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var foreground = false
    private var pendingTap: Map<String, String>? = null
    private var pendingStart: Pair<Map<*, *>, MethodChannel.Result>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        captureTap(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onResume() { super.onResume(); foreground = true }
    override fun onPause() { foreground = false; super.onPause() }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent); setIntent(intent); captureTap(intent)
        channel?.invokeMethod("notificationTapAvailable", null)
    }

    private fun captureTap(intent: Intent?) {
        val id = intent?.getStringExtra(NotificationListenerService.ITEM_ID)
        val scope = intent?.getStringExtra(NotificationListenerService.ITEM_SCOPE)
        if (id != null && scope != null && Regex("[a-zA-Z0-9_-]{1,100}").matches(id) && Regex("[a-f0-9]{64}").matches(scope)) {
            pendingTap = mapOf("id" to id, "scope" to scope)
        }
        intent?.removeExtra(NotificationListenerService.ITEM_ID)
        intent?.removeExtra(NotificationListenerService.ITEM_SCOPE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avodah/native_notifications")
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "isTrial" -> result.success(packageName.endsWith(".notification_trial"))
                "status" -> result.success(mapOf("enabled" to NotificationListenerService.running,
                    "status" to NotificationListenerService.status))
                "takeTap" -> { val id = pendingTap; pendingTap = null; result.success(id) }
                "stop" -> {
                    stopService(Intent(this, NotificationListenerService::class.java))
                    result.success(null)
                }
                "start" -> {
                    val args = call.arguments as? Map<*, *>
                    if (!foreground || Build.VERSION.SDK_INT < 26 || args == null || pendingStart != null) {
                        result.error("unavailable", "Start from the visible Android app (Android 8+).", null)
                    } else if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        pendingStart = Pair(args, result)
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 126)
                    } else startListener(args, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startListener(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val origin = NotificationStreamProtocol.validateOrigin(args["origin"] as String)
            val node = args["node"] as String
            val token = args["token"] as String
            require(node.isNotBlank() && token.isNotBlank())
            val intent = Intent(this, NotificationListenerService::class.java)
                .putExtra("origin", origin).putExtra("node", node).putExtra("token", token)
            startForegroundService(intent)
            result.success(null) // Start requested, not a delivery or active-state claim.
        } catch (_: Exception) {
            result.error("start_failed", "Could not start; verify HTTPS, pairing and Android permission.", null)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 126) {
            val pending = pendingStart ?: return
            pendingStart = null
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startListener(pending.first, pending.second)
            } else pending.second.error("permission_denied", "Notification permission is required for visible alerts.", null)
        }
    }

    override fun onDestroy() {
        pendingStart?.second?.error("cancelled", "Activity closed before listener start.", null)
        pendingStart = null
        channel?.setMethodCallHandler(null); channel = null
        super.onDestroy()
    }
}
