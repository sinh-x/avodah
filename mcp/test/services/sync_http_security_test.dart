import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/services/pairing_service.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/services/sync_http_handler.dart';
import 'package:avodah_mcp/services/sync_request_policy.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:cryptography/cryptography.dart' hide KeyPair;
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _ObservedPolicy extends SyncRequestPolicy {
  void Function()? onAccepted;
  _ObservedPolicy() : super(allowedOrigins: ['https://fixture.test']);
  @override
  Future<bool> authenticate(
      HttpRequest request, PairingService? pairing) async {
    final accepted = await super.authenticate(request, pairing);
    if (accepted) onAccepted?.call();
    return accepted;
  }
}

class _RacingSyncApi extends SyncApiService {
  Future<void> Function()? afterExtract;
  _RacingSyncApi(
      {required super.db,
      required super.clock,
      required super.pairingService,
      required super.config,
      required super.policy});
  @override
  Future<List<Map<String, dynamic>>> extractDeltas(
      HybridTimestamp since) async {
    final result = await super.extractDeltas(since);
    await afterExtract?.call();
    return result;
  }
}

void main() {
  late AppDatabase db;
  late PairingService pairing;
  late SyncApiService sync;
  late HttpServer server, upstream;
  late String base, token, code;
  late int calls;
  var denyWs = 0;
  late DateTime now;
  final client = http.Client();

  setUp(() async {
    db = openMemoryDatabase();
    now = DateTime.now();
    pairing =
        PairingService(db: db, deliverCode: (v) => code = v, now: () => now);
    final key = Uint8List.fromList(List.filled(32, 7));
    token = await generateSyncVerifyCode(key);
    await db.into(db.pairedDevices).insert(PairedDevicesCompanion.insert(
        id: 'device',
        publicKey: key,
        privateKey: Value(key),
        created: 1,
        lastSeen: const Value(1)));
    sync = _RacingSyncApi(
        db: db,
        clock: HybridLogicalClock(nodeId: 'server'),
        pairingService: pairing,
        config: AvoConfig(),
        policy: _ObservedPolicy());
    calls = 0;
    denyWs = 0;
    upstream = await HttpServer.bind('127.0.0.1', 0);
    upstream.listen((r) async {
      calls++;
      if (WebSocketTransformer.isUpgradeRequest(r)) {
        if (denyWs != 0) {
          r.response.statusCode = denyWs;
          await r.response.close();
          return;
        }
        final ws = await WebSocketTransformer.upgrade(r);
        ws.listen(ws.add);
      } else {
        r.response.statusCode =
            403; // PA still independently denies paired users.
        r.response.write('{"error":"PA denied"}');
        await r.response.close();
      }
    });
    server = await HttpServer.bind('127.0.0.1', 0);
    final handler = SyncHttpHandler(
        sync: sync,
        pairing: pairing,
        agentApiUrl: 'http://127.0.0.1:${upstream.port}');
    server.listen(handler.call);
    base = 'http://127.0.0.1:${server.port}';
  });
  tearDown(() async {
    await server.close(force: true);
    await upstream.close(force: true);
    await db.close();
  });
  tearDownAll(client.close);

  Future<http.Response> send(String method, String path,
      {Map<String, String>? headers, String? body}) async {
    final r = http.Request(method, Uri.parse('$base$path'))
      ..headers.addAll(headers ?? {})
      ..body = body ?? '';
    return http.Response.fromStream(await client.send(r));
  }

  Map<String, String> auth() =>
      {'X-Av-Node-Id': 'device', 'X-Av-Pair-Token': token};

  test('protected negative matrix has no DB/clock/upstream effects', () async {
    final routes = {
      '/api/config/categories': ['GET'],
      '/api/config/category-chips': ['GET', 'POST', 'DELETE'],
      '/api/sync/deltas': ['GET', 'POST'],
      '/api/sync/pair': ['GET', 'DELETE'],
      '/api/test': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    };
    final before = sync.clock.lastTimestamp.pack();
    for (final headers in [
      <String, String>{},
      {'X-Av-Node-Id': 'device', 'X-Av-Pair-Token': 'invalid'},
      {'X-Av-Node-Id': 'other', 'X-Av-Pair-Token': token},
      {'X-Av-Node-Id': 'bad identity', 'X-Av-Pair-Token': token}
    ]) {
      for (final route in routes.entries) {
        for (final method in route.value) {
          final r = await send(method, route.key, headers: headers, body: '{}');
          expect(r.statusCode, 403, reason: '$method ${route.key}');
        }
      }
    }
    expect(sync.clock.lastTimestamp.pack(), before);
    expect(await db.select(db.categoryChips).get(), isEmpty);
    expect(await db.select(db.syncWatermarks).get(), isEmpty);
    expect((await pairing.getPairedDevice('device'))!.lastSeen, 1);
    expect(calls, 0);
    final verification = await send('GET', '/api/sync/pair', headers: auth());
    expect(verification.statusCode, 200);
    expect(jsonDecode(verification.body), {'paired': true});
    expect(sync.clock.lastTimestamp.pack(), before);
    expect((await pairing.getPairedDevice('device'))!.lastSeen, 1);
    expect(
        (await send('GET', '/api/config/categories', headers: auth()))
            .statusCode,
        200);
    expect(
        (await send('POST', '/api/config/category-chips',
                headers: auth(),
                body: jsonEncode({
                  'action': 'add',
                  'category': 'Working',
                  'chip': 'standup'
                })))
            .statusCode,
        200);
    expect(await db.select(db.categoryChips).get(), hasLength(1));
    expect((await send('GET', '/api/test', headers: auth())).statusCode, 403);
    expect(calls, 1);
    expect((await send('DELETE', '/api/sync/pair', headers: auth())).statusCode,
        200);
    for (final route in routes.entries) {
      for (final method in route.value) {
        expect(
            (await send(method, route.key, headers: auth(), body: '{}'))
                .statusCode,
            403);
      }
    }
    expect(await db.select(db.categoryChips).get(), hasLength(1));
    expect(calls, 1);
  });

  test('seven-family state remains byte-equivalent after every auth rejection',
      () async {
    final stamp = sync.clock.now().pack();
    final result =
        await sync.mergePushBatch(remoteNode: 'fixture-seed', deltas: [
      for (final type in [
        'task',
        'worklog',
        'timer',
        'project',
        'dailyPlan',
        'dayPlanTask',
        'categoryChip'
      ])
        {
          'type': type,
          'id': type == 'timer' ? 'active-timer' : 'fixture-$type',
          'fields': {
            for (final field in [
              'title',
              'taskTitle',
              'name',
              'date',
              'category',
              'label'
            ])
              field: {'v': 'synthetic', 't': stamp}
          }
        }
    ]);
    expect(result.errors, isEmpty);
    expect(result.merged, 7);
    Future<String> state() async => jsonEncode({
          for (final table in db.allTables)
            table.actualTableName: (await db
                    .customSelect('SELECT * FROM "${table.actualTableName}"')
                    .get())
                .map((row) => row.data)
                .toList()
        });
    final routes = {
      '/api/config/categories': ['GET'],
      '/api/config/category-chips?category=synthetic&chip=synthetic': [
        'GET',
        'POST',
        'DELETE'
      ],
      '/api/sync/deltas': ['GET', 'POST'],
      '/api/sync/pair': ['GET', 'DELETE'],
      '/api/test': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    };
    for (final headers in [
      <String, String>{},
      {'X-Av-Node-Id': 'device', 'X-Av-Pair-Token': 'invalid'},
      {'X-Av-Node-Id': 'wrong-node', 'X-Av-Pair-Token': token}
    ]) {
      final before = await state();
      final clockBefore = sync.clock.lastTimestamp.pack();
      for (final route in routes.entries) {
        for (final method in route.value) {
          final response = await send(method, route.key,
              headers: headers,
              body:
                  '{"action":"remove","category":"synthetic","chip":"synthetic","node":"device","deltas":[]}');
          expect(response.statusCode, 403);
          expect(await state(), before, reason: '$method ${route.key}');
          expect(sync.clock.lastTimestamp.pack(), clockBefore);
          expect(calls, 0);
        }
      }
    }
    await pairing.revokePairing('device');
    final before = await state();
    for (final route in routes.entries) {
      for (final method in route.value) {
        expect(
            (await send(method, route.key, headers: auth(), body: '{}'))
                .statusCode,
            403);
        expect(await state(), before);
        expect(calls, 0);
      }
    }
  });

  for (final path in [
    '/api/sync/deltas',
    '/api/config/category-chips',
    '/api/test'
  ]) {
    test('revocation fences an admitted streamed mutation: $path', () async {
      final admitted = Completer<void>();
      (sync.policy as _ObservedPolicy).onAccepted = () {
        if (!admitted.isCompleted) admitted.complete();
      };
      final io = HttpClient();
      try {
        final request = await io.postUrl(Uri.parse('$base$path'));
        auth().forEach(request.headers.set);
        final body = jsonEncode({
          'node': 'device',
          'deltas': [],
          'action': 'add',
          'category': 'Working',
          'chip': 'must-not-exist'
        });
        request.write(body.substring(0, 1));
        await request.flush();
        await admitted.future.timeout(const Duration(seconds: 2));
        expect(
            (await send('DELETE', '/api/sync/pair', headers: auth()))
                .statusCode,
            200);
        final before = sync.clock.lastTimestamp.pack();
        request.write(body.substring(1));
        final response = await request.close();
        expect(response.statusCode, 403);
        await response.drain<void>();
        expect(sync.clock.lastTimestamp.pack(), before);
        expect(await db.select(db.categoryChips).get(), isEmpty);
        expect(await db.select(db.syncWatermarks).get(), isEmpty);
        expect(calls, 0);
      } finally {
        io.close(force: true);
      }
    });
  }

  test('exact origins, method matrix, preflight and reserved routes', () async {
    for (final origin in [
      'null',
      'https://fixture.test.evil',
      'http://fixture.test'
    ]) {
      expect(
          (await send('GET', '/api/sync/status', headers: {'Origin': origin}))
              .statusCode,
          403);
    }
    final r = await send('OPTIONS', '/api/config/category-chips', headers: {
      'Origin': 'https://fixture.test',
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers':
          'Content-Type,X-Av-Node-Id,X-Av-Pair-Token'
    });
    expect(r.statusCode, 204);
    expect(r.headers['access-control-allow-origin'], 'https://fixture.test');
    expect((await send('HEAD', '/api/sync/status')).statusCode, 405);
    expect(
        (await send('HEAD', '/api/config/categories', headers: auth()))
            .statusCode,
        405);
    expect((await send('GET', '/api/sync/unknown', headers: auth())).statusCode,
        404);
    expect(calls, 0);
  });

  test(
      'enrollment is private, one-use, expired/bounded and additional devices work',
      () async {
    final start =
        await send('POST', '/api/sync/pair/start', body: '{"nodeId":"second"}');
    expect(start.statusCode, 200);
    expect(start.body, isNot(contains(code)));
    final key = await generateKeyPair();
    final mac = await Hmac.sha256()
        .calculateMac(key.publicKey, secretKey: SecretKey(utf8.encode(code)));
    final body = jsonEncode({
      'nodeId': 'second',
      'phonePubKey': base64Encode(key.publicKey),
      'hmacProof': base64Encode(mac.bytes)
    });
    expect(
        (await send('POST', '/api/sync/pair/confirm', body: body)).statusCode,
        200);
    expect(
        (await send('POST', '/api/sync/pair/confirm', body: body)).statusCode,
        403);
    await pairing.startPairing('expire');
    now = now.add(const Duration(seconds: 300));
    expect(
        (await pairing.confirmPairing(
            nodeId: 'expire',
            phonePubKeyBase64: '',
            hmacProofBase64: ''))['success'],
        false);
    await pairing.startPairing('attempts');
    for (var i = 0; i < 5; i++) {
      await pairing.confirmPairing(
          nodeId: 'attempts', phonePubKeyBase64: '', hmacProofBase64: '');
    }
    expect(
        (await pairing.confirmPairing(
            nodeId: 'attempts',
            phonePubKeyBase64: '',
            hmacProofBase64: ''))['error'],
        contains('timeout'));
    expect(
        (await send('POST', '/api/sync/pair/start', body: 'x' * 8193))
            .statusCode,
        413);
    for (var i = 0; i < 11; i++) {
      final response = await send('POST', '/api/sync/pair/start',
          body: '{"nodeId":"node$i"}');
      if (i == 10) expect(response.statusCode, 429);
    }
  });

  test('concurrent write after extraction is not skipped by the next pull',
      () async {
    final service = sync as _RacingSyncApi;
    service.afterExtract = () async {
      service.afterExtract = null;
      final doc =
          TaskDocument.create(clock: sync.clock, title: 'concurrent fixture');
      await db.into(db.tasks).insert(doc.toDriftCompanion());
    };
    final first = jsonDecode(
        (await send('GET', '/api/sync/deltas', headers: auth())).body) as Map;
    expect(first['deltas'], isEmpty);
    final second = jsonDecode((await send('GET',
            '/api/sync/deltas?since=${Uri.encodeQueryComponent(first['watermark'] as String)}',
            headers: auth()))
        .body) as Map;
    expect(second['deltas'], hasLength(1));
  });

  test('health distinguishes core readiness and optional PA denial', () async {
    expect((await send('GET', '/health')).statusCode, 200);
    expect((await send('GET', '/ready')).statusCode, 200);
    final deps = await send('GET', '/dependencies');
    expect(deps.body, contains('auth-unavailable'));
    expect(deps.body, contains('disabled'));
    expect(deps.body, isNot(contains(token)));
    expect((await send('GET', '/ready')).statusCode, 200);
  });

  for (final status in [401, 403]) {
    test('native WS preserves independent PA denial $status', () async {
      denyWs = status;
      await expectLater(
          WebSocket.connect('${base.replaceFirst('http:', 'ws:')}/ws/session',
              headers: auth()),
          throwsA(isA<WebSocketException>().having(
              (e) => e.httpStatusCode, 'upstream denial status', status)));
      expect(calls, 1);
    });
  }

  test('native WS works, invalid never connects, active revoke closes',
      () async {
    final wsBase = base.replaceFirst('http:', 'ws:');
    await expectLater(
        WebSocket.connect('$wsBase/ws/session'), throwsA(anything));
    expect(calls, 0);
    final ws = await WebSocket.connect('$wsBase/ws/session', headers: auth());
    ws.add('echo');
    final messages = ws.asBroadcastStream();
    expect(await messages.first, 'echo');
    await send('DELETE', '/api/sync/pair', headers: auth());
    await messages.drain<void>().timeout(const Duration(seconds: 3));
    await expectLater(WebSocket.connect('$wsBase/ws/session', headers: auth()),
        throwsA(anything));
    expect(calls, 1);
  });
}
