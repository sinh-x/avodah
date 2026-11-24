package com.sinh_x.avodah_viewer

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors

/** User-started, visible specialUse FGS for private notification reception.
 * No credential persistence, boot receiver, wake lock, polling or battery bypass.
 * Android/OEM idle delivery is a trial outcome, not a guarantee of this service.
 */
class NotificationListenerService : Service() {
    companion object {
        const val STOP = "com.sinh_x.avodah_viewer.STOP_NOTIFICATION_LISTENER"
        const val ITEM_ID = "avodah_notification_id"
        const val ITEM_SCOPE = "avodah_notification_scope"
        private const val STATUS_ID = 7001
        private const val STATUS_CHANNEL = "avodah_listener_status"
        private const val ALERT_CHANNEL = "avodah_inbox_alerts"
        @Volatile var running = false
            private set
        @Volatile var status = "Stopped. Enable while Avodah is open."
            private set
    }
    private val executor = Executors.newSingleThreadExecutor()
    @Volatile private var active = false
    @Volatile private var connection: HttpURLConnection? = null
    private val manager get() = getSystemService(NotificationManager::class.java)

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == STOP) {
            stopListening("Stopped by user. Open Avodah to enable again.")
            return START_NOT_STICKY
        }
        if (active) return START_NOT_STICKY
        try {
            val origin = NotificationStreamProtocol.validateOrigin(intent.getStringExtra("origin") ?: "")
            val node = intent.getStringExtra("node") ?: ""
            val token = intent.getStringExtra("token") ?: ""
            require(node.isNotBlank() && node.length <= 256 && !node.contains(Regex("[\\r\\n]")))
            require(token.isNotBlank() && token.length <= 4096 && !token.contains(Regex("[\\r\\n]")))
            require(notificationsAllowed())
            createChannels()
            status = "Connecting to private Avodah server…"
            val notification = statusNotification()
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(STATUS_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(STATUS_ID, notification)
            }
            active = true; running = true
            executor.submit { listen(origin, node, token) }
        } catch (_: Exception) {
            stopListening("Listener could not start. Check HTTPS pairing and notification permission.")
        }
        // A killed process/force-stop/reboot needs an explicit foreground opt-in.
        return START_NOT_STICKY
    }

    private fun createChannels() {
        manager.createNotificationChannel(NotificationChannel(STATUS_CHANNEL, "Avodah listener status", NotificationManager.IMPORTANCE_LOW))
        manager.createNotificationChannel(NotificationChannel(ALERT_CHANNEL, "Avodah inbox alerts", NotificationManager.IMPORTANCE_HIGH))
    }

    private fun statusNotification(): Notification {
        val stop = PendingIntent.getService(this, 1, Intent(this, NotificationListenerService::class.java).setAction(STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, STATUS_CHANNEL)
            .setSmallIcon(R.drawable.ic_notification).setContentTitle("Avodah notification listener")
            .setContentText(status).setOngoing(true).setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE).setContentIntent(open)
            .addAction(Notification.Action.Builder(null, "Stop", stop).build()).build()
    }

    private fun updateStatus(text: String) {
        if (!active) return
        status = text
        manager.notify(STATUS_ID, statusNotification())
    }

    private fun notificationsAllowed(): Boolean = manager.areNotificationsEnabled() &&
        manager.getNotificationChannel(ALERT_CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE &&
        manager.getNotificationChannel(STATUS_CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE &&
        (Build.VERSION.SDK_INT < 33 || checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)

    private fun alert(id: String, scope: String) {
        // Use ID only, never a remote URL. Flutter fetches via configured origin/auth.
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .setAction("avodah.notification.$scope.$id").putExtra(ITEM_ID, id).putExtra(ITEM_SCOPE, scope)
        val open = PendingIntent.getActivity(this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        manager.notify("avodah-inbox-$id", 0, Notification.Builder(this, ALERT_CHANNEL)
            .setSmallIcon(R.drawable.ic_notification).setContentTitle("Avodah")
            .setContentText("New notification in your Avodah inbox.")
            .setVisibility(Notification.VISIBILITY_PRIVATE).setAutoCancel(true)
            .setOnlyAlertOnce(true).setContentIntent(open).build())
    }

    private fun listen(origin: String, node: String, token: String) {
        // Bind replay state to the configured origin, node AND pairing identity.
        val scope = MessageDigest.getInstance("SHA-256").digest("$origin\n$node\n$token".toByteArray())
            .joinToString("") { "%02x".format(it.toInt() and 0xff) }
        val prefs = getSharedPreferences("avodah_native_listener", MODE_PRIVATE)
        var cursor: Long? = if (prefs.contains(scope)) prefs.getLong(scope, 0) else null
        var delay = 2000L
        while (active && !Thread.currentThread().isInterrupted) {
            var caughtUp = false
            try {
                if (!notificationsAllowed()) {
                    stopListening("Notifications denied. Allow them and enable again."); return
                }
                val query = cursor?.let { "?after=$it" } ?: ""
                val conn = URL("$origin/api/notifications/events/stream$query").openConnection() as HttpURLConnection
                connection = conn
                conn.instanceFollowRedirects = false
                conn.connectTimeout = 10000; conn.readTimeout = 25000
                conn.setRequestProperty("Accept", "text/event-stream")
                conn.setRequestProperty("X-Av-Node-Id", node)
                conn.setRequestProperty("X-Av-Pair-Token", token)
                val code = conn.responseCode
                if (code == 401 || code == 403) throw NotificationStreamProtocol.AuthorizationRequired()
                if (code == 409) {
                    stopListening("Server history changed. Review server recovery before enabling again."); return
                }
                require(code == 200 && conn.contentType?.startsWith("text/event-stream") == true)
                updateStatus("Listening on private connection. Tailscale must stay connected.")
                conn.inputStream.bufferedReader(Charsets.UTF_8).use { reader ->
                    while (active) {
                        val line = NotificationStreamProtocol.readLine(reader) ?: break
                        if (!active) break
                        when (val frame = NotificationStreamProtocol.parse(line, cursor ?: 0)) {
                            is NotificationStreamProtocol.Frame.Checkpoint -> {
                                cursor = frame.cursor
                                check(prefs.edit().putLong(scope, frame.cursor).commit())
                            }
                            is NotificationStreamProtocol.Frame.Notification -> {
                                if (!notificationsAllowed()) throw SecurityException()
                                alert(frame.id, scope)
                                // Persist after presentation request; a crash can replace an
                                // existing tagged alert, never create another inbox record.
                                cursor = frame.cursor
                                check(prefs.edit().putLong(scope, frame.cursor).commit())
                            }
                            null -> Unit
                        }
                    }
                }
                caughtUp = true; delay = 2000L
            } catch (_: NotificationStreamProtocol.AuthorizationRequired) {
                stopListening("Pairing revoked or expired. Pair and enable again."); return
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt(); return
            } catch (_: Exception) {
                updateStatus("Disconnected. Waiting to reconnect; saved inbox records remain.")
            } finally {
                connection?.disconnect(); connection = null
            }
            if (active) {
                try { Thread.sleep(if (caughtUp) 500L else delay) }
                catch (_: InterruptedException) { Thread.currentThread().interrupt(); return }
                if (!caughtUp) delay = (delay * 2).coerceAtMost(60000L)
            }
        }
    }

    private fun stopListening(reason: String) {
        status = reason; active = false; running = false
        connection?.disconnect()
        stopForeground(STOP_FOREGROUND_REMOVE); stopSelf()
    }

    override fun onTimeout(startId: Int, fgsType: Int) {
        stopListening("Stopped by Android. Open Avodah to enable again.")
    }

    override fun onDestroy() {
        if (running) status = "Stopped. Open Avodah to enable again."
        active = false; running = false
        connection?.disconnect(); executor.shutdownNow()
        super.onDestroy()
    }
}
