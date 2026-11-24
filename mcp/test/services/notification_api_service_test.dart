import 'dart:convert';
import 'dart:io';

import 'package:avodah_mcp/services/notification_api_service.dart';
import 'package:avodah_mcp/services/notification_store.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  late NotificationStore store;
  late HttpServer server;
  late http.Client client;
  late String base;
  final sendToken = List.filled(40, 'x').join();
  final paired = {'X-Av-Node-Id': 'phone', 'X-Av-Pair-Token': 'paired'};
  late Map<String, String> producer;

  Future<http.Response> call(String method, String path,
      {Object? body, Map<String, String>? headers}) async {
    final request = http.Request(method, Uri.parse('$base$path'))
      ..headers.addAll({'Content-Type': 'application/json', ...?headers});
    if (body != null) request.body = jsonEncode(body);
    return http.Response.fromStream(await client.send(request));
  }

  Future<http.Response> send({String title = 'Hello'}) =>
      call('POST', '/api/notifications',
          body: {'id': 'test-1', 'title': title, 'body': 'Private content'},
          headers: producer);

  setUp(() async {
    store = NotificationStore(':memory:');
    final api = NotificationApiService(
        store: store,
        sendToken: sendToken,
        verifyDevice: (node, token) async =>
            node == 'phone' && token == 'paired');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (!await api.handleRequest(request)) {
        request.response.statusCode = 404;
        await request.response.close();
      }
    });
    base = 'http://127.0.0.1:${server.port}';
    client = http.Client();
    producer = {'Authorization': 'Bearer $sendToken'};
  });
  tearDown(() async {
    client.close();
    await server.close(force: true);
    store.close();
  });

  test('auth separates send-only producers from paired consumers', () async {
    expect((await call('GET', '/api/notifications')).statusCode, 403);
    expect(
        (await call('GET', '/api/notifications', headers: producer)).statusCode,
        403);
    expect(
        (await call('POST', '/api/notifications',
                headers: paired, body: {'id': 'a', 'title': 'a', 'body': 'a'}))
            .statusCode,
        403);
    expect((await send()).statusCode, 201);
    expect(
        (await call('GET', '/api/notifications', headers: paired)).statusCode,
        200);
  });

  test(
      'retry deduplicates, differing payload conflicts, listing retains record',
      () async {
    expect((await send()).statusCode, 201);
    expect((await send()).statusCode, 200);
    expect((await send(title: 'different')).statusCode, 409);
    expect(store.list(), hasLength(1));
    expect(store.get('test-1')['read'], false);
  });

  test(
      'independent read/handled/remarks, stale conflicts, explicit delete tombstone',
      () async {
    await send();
    final path = '/api/notifications/test-1';
    expect(
        (await call('PATCH', path,
                headers: paired, body: {'revision': 1, 'read': true}))
            .statusCode,
        200);
    expect(store.get('test-1')['handled'], false);
    expect(
        (await call('PATCH', path,
                headers: paired, body: {'revision': 1, 'remarks': 'stale'}))
            .statusCode,
        409);
    expect(
        (await call('PATCH', path,
                headers: paired,
                body: {'revision': 2, 'handled': true, 'remarks': 'Done'}))
            .statusCode,
        200);
    expect(store.get('test-1')['read'], true);
    expect(store.get('test-1')['remarks'], 'Done');
    expect(
        (await call('DELETE', path, headers: paired, body: {'revision': 3}))
            .statusCode,
        200);
    expect(store.list(), isEmpty);
    expect((await send()).statusCode, 410);
  });

  test(
      'rejects invalid edits, unknown fields, malformed and oversized requests',
      () async {
    await send();
    for (final body in [
      {'revision': 1, 'read': 'yes'},
      {'read': true},
      {'revision': 1, 'approval': true},
      {'revision': 1},
      {'revision': 1, 'remarks': List.filled(16001, 'a').join()},
    ]) {
      expect(
          (await call('PATCH', '/api/notifications/test-1',
                  headers: paired, body: body))
              .statusCode,
          400);
    }
    expect(
        (await call('POST', '/api/notifications',
                headers: producer,
                body: {'id': '../bad', 'title': 'x', 'body': 'x'}))
            .statusCode,
        400);
    expect(
        (await call('POST', '/api/notifications',
                headers: producer, body: List.filled(70001, 'x').join()))
            .statusCode,
        413);
    expect(
        (await call('POST', '/api/notifications', headers: producer, body: []))
            .statusCode,
        400);
  });

  test('bounded pagination and preflight', () async {
    for (var i = 0; i < 101; i++) {
      store.send('n-$i', 'title', 'body');
    }
    final result = jsonDecode(
        (await call('GET', '/api/notifications', headers: paired)).body);
    expect(result['items'], hasLength(100));
    expect(result['nextOffset'], 100);
    expect((await call('OPTIONS', '/api/notifications')).statusCode, 204);
    expect(
        (await call('GET', '/api/notifications?offset=-1', headers: paired))
            .statusCode,
        400);
  });

  test('file store survives restart with states and idempotency', () async {
    final dir = await Directory.systemTemp.createTemp('avodah-inbox-test-');
    final path = '${dir.path}/inbox.sqlite3';
    try {
      var disk = NotificationStore(path);
      disk.send('persist', 'Title', 'Body');
      disk.update('persist', 1, read: true, remarks: 'Saved');
      disk.close();
      disk = NotificationStore(path);
      expect(disk.get('persist')['read'], true);
      expect(disk.get('persist')['remarks'], 'Saved');
      expect(disk.send('persist', 'Title', 'Body').created, false);
      disk.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
