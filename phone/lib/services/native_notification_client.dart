import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'agent_api_client.dart';
import 'notification_alerts_client.dart';

/// The network connection lives in a native Android foreground service,
/// not a Flutter timer/isolate. Credentials are handed over in memory only.
class NativeNotificationClient extends NotificationAlertsClient
    with WidgetsBindingObserver {
  final AgentApiClient api;
  final ValueChanged<String> openItem;
  final MethodChannel channel;
  @override
  bool enabled = false;
  @override
  bool busy = false;
  @override
  String? error;
  @override
  String description =
      'Native alerts. Enable to show a persistent listener and Stop control.';
  bool _disposed = false;

  NativeNotificationClient({
    required this.api,
    required this.openItem,
    this.channel = const MethodChannel('avodah/native_notifications'),
  }) {
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationTapAvailable') await _takeTap();
    });
  }

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The isolated package changes only its default server, not alert delivery.
  static Future<bool> isTrialBuild() async {
    if (!supported) return false;
    return await const MethodChannel(
          'avodah/native_notifications',
        ).invokeMethod<bool>('isTrial') ??
        false;
  }

  Future<void> _takeTap() async {
    final tap = await channel.invokeMapMethod<String, dynamic>('takeTap');
    if (_disposed || tap == null) return;
    final id = tap['id'];
    if (id is! String || !RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(id)) {
      return;
    }
    final origin = api.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final digest = await Sha256().hash(
      utf8.encode('$origin\n${api.nodeId}\n${api.pairingToken}'),
    );
    if (_disposed) return;
    if (tap['scope'] !=
        digest.bytes
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join()) {
      error =
          'This alert belongs to a different server or pairing. Open the original configured inbox.';
      notifyListeners();
      return;
    }
    openItem(id);
  }

  Future<void> _status() async {
    final result = await channel.invokeMapMethod<String, dynamic>('status');
    if (_disposed) return;
    enabled = result?['enabled'] == true;
    description =
        result?['status'] as String? ?? 'Listener status unavailable.';
    notifyListeners();
  }

  @override
  Future<void> restore() async {
    // Observe only. Never auto-start a foreground service on app launch/resume.
    try {
      await _status();
      await _takeTap();
    } catch (_) {
      error =
          'Native listener unavailable. Update the Android app and try again.';
      if (!_disposed) notifyListeners();
    }
  }

  @override
  Future<void> enable() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final origin = Uri.tryParse(api.baseUrl);
      if (origin == null ||
          origin.scheme != 'https' ||
          origin.host.isEmpty ||
          origin.userInfo.isNotEmpty ||
          origin.hasQuery ||
          origin.hasFragment ||
          api.nodeId == null ||
          api.nodeId!.isEmpty ||
          api.pairingToken == null ||
          api.pairingToken!.isEmpty) {
        throw StateError('Trusted HTTPS pairing required');
      }
      await _status();
      if (enabled) {
        await channel.invokeMethod<void>('stop');
        for (var i = 0; i < 10 && enabled; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await _status();
        }
        if (enabled) throw StateError('Previous listener has not stopped');
      }
      await channel.invokeMethod<void>('start', {
        'origin': api.baseUrl,
        'node': api.nodeId,
        'token': api.pairingToken,
      });
      // Local service startup confirmation only, not network polling/delivery.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _status();
      if (!enabled) {
        error =
            'Listener start was not confirmed. Check Android permission and try again while Avodah is visible.';
      }
    } catch (_) {
      error =
          'Cannot enable. Pair over trusted HTTPS, allow Android notifications, and start from the visible app.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  Future<void> disable() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      // Entirely local; stopping works even without Tailscale/server access.
      await channel.invokeMethod<void>('stop');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await _status();
      if (enabled) {
        error =
            'Listener stop was not confirmed. Use Stop in the persistent notification.';
      }
    } catch (_) {
      error =
          'Stop was not confirmed. Use Stop in the persistent notification.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) restore();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    channel.setMethodCallHandler(null);
    // Keep a user-started service alive; its notification always offers Stop.
    super.dispose();
  }
}
