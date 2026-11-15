import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avodah_viewer/services/crypto_sync_native.dart';
import 'package:avodah_viewer/screens/pairing_screen.dart';

class _FailingStorage extends FlutterSecureStorage {
  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw const FileSystemException('synthetic secure storage failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // These integration tests use only a disposable loopback server.
  HttpOverrides.global = null;
  late HttpServer server;
  late String base;
  late int calls;
  late int status;
  final seen = <Map<String, String?>>[];
  const token = 'synthetic-legacy-pairing';
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      CryptoSyncService.legacyTokenKey: token,
      'avodah_server_pub_key': base64Encode(List.filled(32, 7)),
    });
    calls = 0;
    status = 200;
    seen.clear();
    server = await HttpServer.bind('127.0.0.1', 0);
    base = 'http://127.0.0.1:${server.port}/avodah';
    server.listen((r) async {
      calls++;
      seen.add({
        'path': r.uri.path,
        'node': r.headers.value('X-Av-Node-Id'),
        'token': r.headers.value('X-Av-Pair-Token'),
      });
      r.response.statusCode = status;
      r.response.headers.contentType = ContentType.json;
      if (status == 302)
        r.response.headers.set('location', '$base/redirect-sink');
      r.response.write(jsonEncode({'paired': status == 200}));
      await r.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  test(
    'upgrade never forwards automatically; explicit verified import survives reload',
    () async {
      final client = CryptoSyncService(baseUrl: base, nodeId: 'original-phone');
      await client.loadPersistedState();
      expect(client.hasLegacyPairing, true);
      expect(client.isPaired, false);
      expect(calls, 0);
      await client.migrateLegacyPairing();
      expect(seen.single, {
        'path': '/avodah/api/sync/pair',
        'node': 'original-phone',
        'token': token,
      });
      expect(client.pairingToken, token);
      expect(
        await const FlutterSecureStorage().read(
          key: CryptoSyncService.legacyTokenKey,
        ),
        token,
      );
      final reloaded = CryptoSyncService(
        baseUrl: '$base/',
        nodeId: 'original-phone',
      );
      await reloaded.loadPersistedState();
      expect(reloaded.pairingToken, token);
      final other = CryptoSyncService(
        baseUrl: '$base/other',
        nodeId: 'original-phone',
      );
      await other.loadPersistedState();
      expect(other.isPaired, false);
      expect(other.hasLegacyPairing, false);
      await expectLater(other.migrateLegacyPairing(), throwsStateError);
      expect(calls, 1);
      await reloaded.clearPairingToken();
      await reloaded.loadPersistedState();
      expect(reloaded.hasLegacyPairing, false);
      client.dispose();
      reloaded.dispose();
      other.dispose();
    },
  );

  for (final code in [403, 302, 502]) {
    test('HTTP $code never activates/imports or follows redirects', () async {
      status = code;
      final client = CryptoSyncService(baseUrl: base, nodeId: 'phone');
      await expectLater(client.migrateLegacyPairing(), throwsStateError);
      expect(client.isPaired, false);
      expect(calls, 1);
      expect(
        await const FlutterSecureStorage().read(
          key: CryptoSyncService.legacyTokenKey,
        ),
        token,
      );
      expect(
        await const FlutterSecureStorage().read(
          key: CryptoSyncService.legacyBindingKey,
        ),
        isNull,
      );
      client.dispose();
    });
  }
  test(
    'storage failure does not claim success or lose original credential',
    () async {
      final client = CryptoSyncService(
        baseUrl: base,
        nodeId: 'phone',
        secureStorage: _FailingStorage(),
      );
      await expectLater(
        client.migrateLegacyPairing(),
        throwsA(isA<FileSystemException>()),
      );
      expect(client.isPaired, false);
      expect(
        await const FlutterSecureStorage().read(
          key: CryptoSyncService.legacyTokenKey,
        ),
        token,
      );
      client.dispose();
    },
  );
  test(
    'unsafe plaintext remote migration is rejected before credential transmission',
    () async {
      final client = CryptoSyncService(
        baseUrl: 'http://untrusted.invalid/avodah',
        nodeId: 'phone',
      );
      await expectLater(client.migrateLegacyPairing(), throwsStateError);
      expect(calls, 0);
      client.dispose();
    },
  );
  testWidgets(
    'upgrade UI shows original server consent and Cancel sends nothing',
    (tester) async {
      final client = CryptoSyncService(baseUrl: base, nodeId: 'phone');
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PairingScreen(
                      args: PairingScreenArgs(
                        cryptoClient: client,
                        nodeId: 'phone',
                      ),
                    ),
                  ),
                ),
                child: const Text('Pair'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Pair'));
      await tester.pumpAndSettle();
      expect(find.text('Use existing phone pairing?'), findsOneWidget);
      expect(find.text(base), findsOneWidget);
      expect(calls, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(
        await const FlutterSecureStorage().read(
          key: CryptoSyncService.legacyTokenKey,
        ),
        token,
      );
      client.dispose();
    },
  );
}
