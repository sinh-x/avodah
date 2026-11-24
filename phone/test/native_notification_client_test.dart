import 'dart:convert';

import 'package:avodah_viewer/services/agent_api_client.dart';
import 'package:avodah_viewer/services/native_notification_client.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('avodah/native_notifications');
  late AgentApiClient api;
  late NativeNotificationClient native;
  late List<MethodCall> calls;
  late List<String> opened;
  late bool running, deny;
  Map<String, dynamic>? tap;
  setUp(() {
    calls = [];
    opened = [];
    running = false;
    deny = false;
    tap = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'status':
              return {
                'enabled': running,
                'status': running
                    ? 'Listening on private connection.'
                    : 'Stopped.',
              };
            case 'start':
              if (deny) throw PlatformException(code: 'permission_denied');
              running = true;
              return null;
            case 'stop':
              running = false;
              return null;
            case 'takeTap':
              final result = tap;
              tap = null;
              return result;
            default:
              return false;
          }
        });
    api = AgentApiClient(baseUrl: 'https://private.example/avodah')
      ..nodeId = 'phone'
      ..pairingToken = 'synthetic-pairing';
    native = NativeNotificationClient(api: api, openItem: opened.add);
  });
  tearDown(() {
    native.dispose();
    api.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'restore observes only and never auto-starts or enrolls with Firebase',
    () async {
      await native.restore();
      expect(calls.map((call) => call.method), ['status', 'takeTap']);
      expect(native.enabled, false);
    },
  );
  test(
    'explicit enable uses in-memory pairing; stop works without server access',
    () async {
      await native.enable();
      expect(native.enabled, true);
      expect(native.error, isNull);
      final args =
          calls.firstWhere((call) => call.method == 'start').arguments as Map;
      expect(args, {
        'origin': api.baseUrl,
        'node': 'phone',
        'token': 'synthetic-pairing',
      });
      await native.disable();
      expect(native.enabled, false);
      expect(native.error, isNull);
    },
  );
  test(
    'reconnect stops previous listener before passing a new configuration',
    () async {
      running = true;
      await native.enable();
      final methods = calls.map((call) => call.method).toList();
      expect(methods.indexOf('stop'), lessThan(methods.indexOf('start')));
    },
  );
  test(
    'permission denial remains disabled and does not claim delivery',
    () async {
      deny = true;
      await native.enable();
      expect(native.enabled, false);
      expect(native.error, contains('allow Android notifications'));
    },
  );
  test('unpaired client cannot start', () async {
    api.pairingToken = null;
    await native.enable();
    expect(calls.where((call) => call.method == 'start'), isEmpty);
    expect(native.error, isNotNull);
  });
  test(
    'tap is consumed once and only for the configured origin and pairing',
    () async {
      final digest = await Sha256().hash(
        utf8.encode('${api.baseUrl}\nphone\nsynthetic-pairing'),
      );
      final scope = digest.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      tap = {'id': 'stable-id', 'scope': scope};
      await native.restore();
      await native.restore();
      expect(opened, ['stable-id']);
      tap = {'id': 'other', 'scope': scope};
      api.pairingToken = 'new-pairing';
      await native.restore();
      expect(opened, ['stable-id']);
      expect(native.error, contains('different server or pairing'));
    },
  );
  test('tap cannot navigate to a URL supplied in an event', () async {
    tap = {'id': 'https://untrusted.example', 'scope': 'invalid'};
    await native.restore();
    expect(opened, isEmpty);
  });
}
