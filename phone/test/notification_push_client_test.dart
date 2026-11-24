import 'package:avodah_viewer/services/agent_api_client.dart';
import 'package:avodah_viewer/services/notification_push_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AgentApiClient api;
  late NotificationPushClient push;
  late List<http.Request> requests;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    requests = [];
    api =
        AgentApiClient(
            baseUrl: 'https://example.test',
            client: MockClient((request) async {
              requests.add(request);
              return http.Response('{"configured":false,"enabled":false}', 200);
            }),
          )
          ..nodeId = 'phone'
          ..pairingToken = 'paired';
    push = NotificationPushClient(api: api, openInbox: () {});
  });
  tearDown(() {
    push.dispose();
    api.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'fresh installs do not contact Firebase or enroll without opt-in',
    () async {
      await push.restore();
      expect(requests, isEmpty);
      expect(push.enabled, false);
      expect(push.error, isNull);
    },
  );

  test(
    'unconfigured server leaves alerts disabled with actionable error',
    () async {
      await push.enable();
      expect(push.enabled, false);
      expect(push.busy, false);
      expect(push.error, isNotNull);
      expect(requests, hasLength(1));
      expect(requests.single.headers['X-Av-Pair-Token'], 'paired');
      expect(requests.single.url.path, '/api/notifications/push/device');
    },
  );

  test(
    'disable uses paired API and can remove enrollment without Firebase setup',
    () async {
      await push.disable();
      expect(requests.single.method, 'DELETE');
      expect(push.enabled, false);
      expect(push.error, isNull);
    },
  );

  test('web/desktop does not initialize Android push', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await push.restore();
    await push.enable();
    expect(requests, isEmpty);
  });
}
