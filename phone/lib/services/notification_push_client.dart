import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agent_api_client.dart';
import 'notification_alerts_client.dart';

/// Android-only, explicit opt-in. Native Firebase options come from the
/// operator's google-services.json, including when Android starts without Dart.
class NotificationPushClient extends NotificationAlertsClient {
  final AgentApiClient api;
  final VoidCallback openInbox;
  NotificationPushClient({required this.api, required this.openInbox});
  @override
  bool enabled = false;
  @override
  bool busy = false;
  @override
  String? error;
  @override
  String get description => enabled
      ? 'Android FCM alerts opted in'
      : 'Android FCM alerts not enabled';
  bool _initialized = false, _disposed = false;
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _opened, _foreground;

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  String get _preference => 'notification-push:${api.baseUrl}:${api.nodeId}';

  Future<void> _initialize() async {
    if (_initialized) return;
    await Firebase.initializeApp();
    _tokens = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (!enabled) return;
      try {
        await api.enrollNotificationPush(token);
      } catch (_) {
        error = 'Push registration failed. Reconnect and enable again.';
        _notify();
      }
    });
    _opened = FirebaseMessaging.onMessageOpenedApp.listen((_) => openInbox());
    _foreground = FirebaseMessaging.onMessage.listen((_) {
      // The in-app inbox polls; foreground messages need no system alert.
      _notify();
    });
    _initialized = true;
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) openInbox();
  }

  /// Restore only a previous explicit opt-in; do not prompt on startup.
  @override
  Future<void> restore() async {
    if (!supported || busy) return;
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_preference) ?? false;
    if (!enabled) return;
    await _enable(requestPermission: false);
  }

  @override
  Future<void> enable() => _enable(requestPermission: true);

  Future<void> _enable({required bool requestPermission}) async {
    if (!supported || busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      final status = await api.notificationPushStatus();
      if (status['configured'] != true) {
        throw StateError('Server push is not configured');
      }
      await _initialize();
      final settings = requestPermission
          ? await FirebaseMessaging.instance.requestPermission()
          : await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        throw StateError('Allow Avodah notifications in Android settings');
      }
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) throw StateError('FCM registration unavailable');
      await api.enrollNotificationPush(token);
      enabled = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preference, true);
    } catch (_) {
      error =
          'Push is not confirmed active. Check server/Firebase setup, pairing, network and Android notification permission, then enable again.';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  Future<void> disable() async {
    if (busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Server first: do not claim disabled while a registration is still live.
      await api.disableNotificationPush();
      enabled = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preference, false);
      if (_initialized) {
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {
      error = 'Disable was not fully confirmed. Reconnect and retry.';
    } finally {
      busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tokens?.cancel();
    _opened?.cancel();
    _foreground?.cancel();
    super.dispose();
  }
}
