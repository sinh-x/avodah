import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'notification_store.dart';

enum PushResult { accepted, retry, invalidToken, failed }

/// Generic FCM envelope: never put inbox text, remarks, tickets or credentials
/// in the notification/data payload. An FCM acceptance is not device delivery.
class FcmNotificationSender {
  final String projectId;
  final Future<http.Client> Function() createClient;
  http.Client? _client;
  bool _closed = false;
  FcmNotificationSender({required this.projectId, required this.createClient});

  factory FcmNotificationSender.fromEnvironment() {
    final project = Platform.environment['AVODAH_FCM_PROJECT_ID']!;
    final credentialsPath =
        Platform.environment['GOOGLE_APPLICATION_CREDENTIALS']!;
    if (!RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(project)) {
      throw StateError('Invalid AVODAH_FCM_PROJECT_ID');
    }
    return FcmNotificationSender(
        projectId: project,
        createClient: () async {
          final credentials = ServiceAccountCredentials.fromJson(
              jsonDecode(await File(credentialsPath).readAsString()));
          return clientViaServiceAccount(credentials,
              ['https://www.googleapis.com/auth/firebase.messaging']);
        });
  }

  Future<PushResult> send(String token, String id) async {
    try {
      if (_client == null) {
        final pending = createClient();
        // Close late authorization clients after timeout or shutdown.
        var expired = false;
        pending.then((client) {
          if (expired || _closed) client.close();
        }, onError: (Object _) {});
        try {
          _client = await pending.timeout(const Duration(seconds: 10));
        } on TimeoutException {
          expired = true;
          rethrow;
        }
      }
      if (_closed) return PushResult.retry;
      final response = await _client!
          .post(
            Uri.https(
                'fcm.googleapis.com', '/v1/projects/$projectId/messages:send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': {
                'token': token,
                'notification': {
                  'title': 'Avodah',
                  'body': 'New notification in your Avodah inbox.'
                },
                'data': {'notificationId': id},
                'android': {
                  'priority': 'high',
                  'ttl': '86400s',
                  'notification': {
                    'tag': id,
                    'visibility': 'PRIVATE',
                    'icon': 'ic_notification'
                  }
                },
              }
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return PushResult.accepted;
      // Only the typed FCM error proves an invalid registration, not a generic
      // 404 (which could be a project/configuration error).
      final body = jsonDecode(response.body);
      final error = body is Map ? body['error'] : null;
      final details = error is Map ? error['details'] : null;
      if (details is List &&
          details.any((entry) =>
              entry is Map &&
              entry['@type'] ==
                  'type.googleapis.com/google.firebase.fcm.v1.FcmError' &&
              entry['errorCode'] == 'UNREGISTERED'))
        return PushResult.invalidToken;
      if (response.statusCode == 429 || response.statusCode >= 500)
        return PushResult.retry;
      return PushResult.failed;
    } catch (_) {
      return PushResult.retry;
    }
  }

  void close() {
    _closed = true;
    _client?.close();
  }
}

/// Durable, bounded retry worker. Sending never blocks inbox persistence.
class NotificationPushService {
  final NotificationStore store;
  final Future<PushResult> Function(String token, String id) send;
  final Future<bool> Function(String node) isPaired;
  bool _running = false, _closed = false;
  Timer? _timer;
  NotificationPushService(
      {required this.store, required this.send, required this.isPaired});

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => flush());
    unawaited(flush());
  }

  Future<void> flush({int? now}) async {
    if (_running || _closed) return;
    _running = true;
    try {
      final time = now ?? DateTime.now().millisecondsSinceEpoch;
      for (final job in store.dueJobs(time)) {
        if (_closed) break;
        final id = job['id'] as String, node = job['node'] as String;
        final device = store.device;
        if (device == null || device['node'] != node || !await isPaired(node)) {
          if (_closed) break;
          store.removeDevice(node);
          store.finishAttempt(id, 'cancelled', job['attempts'] as int, 0);
          continue;
        }
        final result = await send(device['token'] as String, id);
        if (_closed) break;
        final attempts = (job['attempts'] as int) + 1;
        if (result == PushResult.invalidToken) {
          store.removeDevice(node, token: device['token'] as String);
        }
        store.finishAttempt(
            id,
            switch (result) {
              PushResult.accepted => 'accepted-by-fcm',
              PushResult.retry when attempts < 5 => 'queued',
              _ => 'failed',
            },
            attempts,
            time + (5000 * (1 << attempts)));
      }
    } catch (_) {
      // No payloads/tokens in logs; jobs remain durable for the next tick.
      stderr.writeln(
          'Notification push worker unavailable; inbox records retained.');
    } finally {
      _running = false;
    }
  }

  void close() {
    _closed = true;
    _timer?.cancel();
  }
}
