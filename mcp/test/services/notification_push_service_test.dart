import 'dart:convert';

import 'package:avodah_mcp/services/notification_push_service.dart';
import 'package:avodah_mcp/services/notification_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('FCM sends generic envelope to one device; never leaks inbox content',
      () async {
    final sender = FcmNotificationSender(
        projectId: 'test-project',
        createClient: () async => MockClient((request) async {
              expect(request.url.toString(),
                  'https://fcm.googleapis.com/v1/projects/test-project/messages:send');
              final message = jsonDecode(request.body)['message'];
              expect(message['token'], 'device-token');
              expect(message['data'], {'notificationId': 'opaque-id'});
              expect(message['notification'], {
                'title': 'Avodah',
                'body': 'New notification in your Avodah inbox.'
              });
              expect(message['android']['notification']['tag'], 'opaque-id');
              expect(message.containsKey('topic'), false);
              return http.Response('{"name":"accepted"}', 200);
            }));
    expect(await sender.send('device-token', 'opaque-id'), PushResult.accepted);
    sender.close();
  });

  test('classifies typed invalid token, retry and permanent failures',
      () async {
    for (final entry in [
      (
        404,
        '{"error":{"details":[{"@type":"type.googleapis.com/google.firebase.fcm.v1.FcmError","errorCode":"UNREGISTERED"}]}}',
        PushResult.invalidToken
      ),
      (404, '{"error":{"message":"unknown project"}}', PushResult.failed),
      (429, '{}', PushResult.retry),
      (503, '{}', PushResult.retry),
      (403, '{}', PushResult.failed),
    ]) {
      final sender = FcmNotificationSender(
          projectId: 'test-project',
          createClient: () async =>
              MockClient((_) async => http.Response(entry.$2, entry.$1)));
      expect(await sender.send('token', 'id'), entry.$3);
      sender.close();
    }
  });

  late NotificationStore store;
  setUp(() => store = NotificationStore(':memory:'));
  tearDown(() => store.close());

  test('single device ownership, rotation and owner-only removal', () {
    store.registerDevice('phone', 'token-1');
    expect(() => store.registerDevice('other-phone', 'token-2'),
        throwsA(isA<NotificationProblem>()));
    store.registerDevice('phone', 'token-2');
    store.removeDevice('other-phone');
    expect(store.device!['token'], 'token-2');
    store.removeDevice('phone', token: 'token-1');
    expect(store.device, isNotNull);
    store.removeDevice('phone');
    expect(store.device, isNull);
  });

  test('deduped sends queue once, retry is bounded, inbox always retained',
      () async {
    store.registerDevice('phone', 'token');
    store.send('id', 'Secret', 'Private', queuePush: true);
    store.send('id', 'Secret', 'Private', queuePush: true);
    var calls = 0;
    final worker = NotificationPushService(
        store: store,
        send: (token, id) async {
          calls++;
          return PushResult.retry;
        },
        isPaired: (_) async => true);
    for (var i = 0; i < 6; i++) {
      await worker.flush(now: i * 1000000);
    }
    expect(calls, 5);
    expect(store.delivery('id'), 'failed');
    expect(store.get('id')['body'], 'Private');
    worker.close();
  });

  test('revoked pairing suppresses push and clears registration', () async {
    store.registerDevice('phone', 'token');
    store.send('id', 'title', 'body', queuePush: true);
    final worker = NotificationPushService(
        store: store,
        send: (token, id) async {
          fail('Must not send');
        },
        isPaired: (_) async => false);
    await worker.flush(now: 0);
    expect(store.delivery('id'), 'cancelled');
    expect(store.device, isNull);
    expect(store.list(), hasLength(1));
    worker.close();
  });

  test(
      'accepted push is not delivered/read/handled; deleted records do not push',
      () async {
    store.registerDevice('phone', 'token');
    store.send('id', 'title', 'body', queuePush: true);
    store.send('deleted', 'title', 'body', queuePush: true);
    store.update('deleted', 1, delete: true);
    var calls = 0;
    final worker = NotificationPushService(
        store: store,
        send: (token, id) async {
          calls++;
          return PushResult.accepted;
        },
        isPaired: (_) async => true);
    await worker.flush(now: 0);
    await worker.flush(now: 10000);
    expect(calls, 1);
    expect(store.delivery('id'), 'accepted-by-fcm');
    expect(store.get('id')['read'], false);
    expect(store.get('id')['handled'], false);
    worker.close();
  });

  test('invalid token clears registration but never deletes inbox', () async {
    store.registerDevice('phone', 'token');
    store.send('id', 'title', 'body', queuePush: true);
    final worker = NotificationPushService(
        store: store,
        send: (token, id) async => PushResult.invalidToken,
        isPaired: (_) async => true);
    await worker.flush(now: 0);
    expect(store.device, isNull);
    expect(store.list(), hasLength(1));
    worker.close();
  });
}
