import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avodah_mcp/services/notification_event_service.dart';
import 'package:avodah_mcp/services/notification_store.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late NotificationStore store;
  late HttpServer server;
  late http.Client client;
  late Uri uri;
  late bool paired;
  final headers = {'X-Av-Node-Id': 'phone', 'X-Av-Pair-Token': 'paired'};
  setUp(() async {
    store = NotificationStore(':memory:');
    paired = true;
    final service = NotificationEventService(
        store: store,
        verifyDevice: (node, token) async =>
            paired && node == 'phone' && token == 'paired',
        heartbeat: const Duration(milliseconds: 40),
        lifetime: const Duration(milliseconds: 500));
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(service.handleRequest);
    client = http.Client();
    uri = Uri.parse(
        'http://127.0.0.1:${server.port}/api/notifications/events/stream');
  });
  tearDown(() async {
    client.close();
    await server.close(force: true);
    store.close();
  });

  Future<http.StreamedResponse> connect({int? after}) {
    final request = http.Request('GET',
        after == null ? uri : uri.replace(queryParameters: {'after': '$after'}))
      ..headers.addAll(headers);
    return client.send(request);
  }

  Future<Map<String, dynamic>> nextData(StreamIterator<String> lines) async {
    while (await lines.moveNext().timeout(const Duration(seconds: 3))) {
      if (lines.current.startsWith('data: '))
        return jsonDecode(lines.current.substring(6)) as Map<String, dynamic>;
    }
    throw StateError('Stream ended');
  }

  test('requires device pairing; no producer or URL-token authorization',
      () async {
    expect((await client.get(uri)).statusCode, 403);
    expect(
        (await client.get(uri, headers: {'Authorization': 'Bearer producer'}))
            .statusCode,
        403);
    expect(
        (await client.get(uri.replace(queryParameters: {'token': 'paired'})))
            .statusCode,
        403);
    expect(
        (await client.get(uri.replace(queryParameters: {'after': '-1'}),
                headers: headers))
            .statusCode,
        400);
    expect(
        (await client.get(uri.replace(queryParameters: {'after': '1'}),
                headers: headers))
            .statusCode,
        409);
  });

  test(
      'starts at current checkpoint, sends committed references only and deduplicates retries',
      () async {
    store.send('old', 'Private old title', 'Private old body');
    final response = await connect();
    expect(response.headers['content-type'], contains('text/event-stream'));
    final lines = StreamIterator(response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter()));
    expect(await nextData(lines), {'type': 'checkpoint', 'cursor': 1});
    store.send('new', 'Secret title', 'Secret body');
    store.send('new', 'Secret title', 'Secret body');
    expect(await nextData(lines),
        {'type': 'notification', 'cursor': 2, 'id': 'new'});
    expect(store.eventsAfter(0), hasLength(2));
    await lines.cancel();
  });

  test(
      'bounded replay reconnects without duplicate records, skips deleted items',
      () async {
    for (var i = 0; i < 70; i++) {
      store.send('id-$i', 'Title', 'Body');
    }
    store.update('id-1', 1, delete: true);
    final first = await connect(after: 0);
    final text = await first.stream.transform(utf8.decoder).join();
    final events = const LineSplitter()
        .convert(text)
        .where((line) => line.startsWith('data: '))
        .map((line) => jsonDecode(line.substring(6)) as Map<String, dynamic>)
        .where((event) => event['type'] == 'notification')
        .toList();
    expect(events, hasLength(64));
    expect(events.any((event) => event['id'] == 'id-1'), false);
    final second = await connect(after: events.last['cursor'] as int);
    final rest = await second.stream.transform(utf8.decoder).join();
    expect(rest, isNot(contains('"id":"id-0"')));
    expect(rest, contains('"id":"id-69"'));
    expect(text, isNot(contains('Title')));
    expect(text, isNot(contains('Body')));
  });

  test('revalidates and closes after pairing is revoked', () async {
    final response = await connect(after: 0);
    final lines = StreamIterator(response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter()));
    await nextData(lines);
    paired = false;
    expect(await nextData(lines),
        {'type': 'error', 'reason': 'authorization-required'});
    await lines.cancel();
  });

  test('limits simultaneous streams per device and expires connections',
      () async {
    final first = await connect();
    expect((await client.get(uri, headers: headers)).statusCode, 429);
    final content = await first.stream.transform(utf8.decoder).join();
    expect(content, contains('heartbeat'));
  });

  test(
      'version 2 migration preserves inbox and FCM outbox with a restorable backup',
      () async {
    final dir =
        await Directory.systemTemp.createTemp('avo-v2-stream-migration-');
    try {
      final path = '${dir.path}/notifications.sqlite3';
      final old = sqlite3.open(path);
      old.execute('''
        CREATE TABLE notifications (id TEXT PRIMARY KEY, title TEXT NOT NULL,
          body TEXT NOT NULL, created_at TEXT NOT NULL, revision INTEGER DEFAULT 1,
          is_read INTEGER DEFAULT 0, handled INTEGER DEFAULT 0,
          remarks TEXT DEFAULT '', deleted INTEGER DEFAULT 0);
        CREATE TABLE push_device (slot INTEGER PRIMARY KEY, node TEXT, token TEXT);
        CREATE TABLE push_jobs (id TEXT PRIMARY KEY, node TEXT, state TEXT DEFAULT 'queued',
          attempts INTEGER DEFAULT 0, next_attempt INTEGER DEFAULT 0);
        INSERT INTO notifications (id, title, body, created_at) VALUES ('old', 'Title', 'Body', '2026');
        INSERT INTO push_device VALUES (1, 'phone', 'synthetic');
        INSERT INTO push_jobs (id, node) VALUES ('old', 'phone');
        PRAGMA user_version = 2;
      ''');
      old.dispose();
      final migrated = NotificationStore(path);
      expect(migrated.get('old')['body'], 'Body');
      expect(migrated.device!['node'], 'phone');
      expect(migrated.delivery('old'), 'queued');
      expect(migrated.latestEventSequence, 0); // No historical alert flood.
      migrated.send('new', 'Title', 'Body');
      expect(migrated.eventsAfter(0), [
        {'cursor': 1, 'id': 'new'}
      ]);
      migrated.close();
      final backupPath = dir
          .listSync()
          .whereType<File>()
          .singleWhere((file) => file.path.contains('before-v3'))
          .path;
      final backup = sqlite3.open(backupPath, mode: OpenMode.readOnly);
      expect(backup.select('PRAGMA user_version').first.values.first, 2);
      expect(backup.select('SELECT id FROM notifications').first['id'], 'old');
      backup.dispose();
      final restoredPath = '${dir.path}/restored.sqlite3';
      await File(backupPath).copy(restoredPath);
      final restored = NotificationStore(restoredPath);
      expect(restored.get('old')['body'], 'Body');
      expect(restored.delivery('old'), 'queued');
      expect(restored.list().any((item) => item['id'] == 'new'), false);
      restored.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('reference log survives restart independently of Firebase configuration',
      () async {
    final dir = await Directory.systemTemp.createTemp('avo-reference-replay-');
    try {
      final path = '${dir.path}/notifications.sqlite3';
      var disk = NotificationStore(path);
      disk.send('stable', 'private', 'private');
      disk.close();
      disk = NotificationStore(path);
      expect(disk.eventsAfter(0), [
        {'cursor': 1, 'id': 'stable'}
      ]);
      expect(disk.send('stable', 'private', 'private').created, false);
      expect(disk.latestEventSequence, 1);
      disk.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
