import 'dart:convert';
import 'dart:io';
import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_viewer/services/crypto_sync_native.dart';
import 'package:avodah_viewer/services/pairing_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _StorageFailure extends FlutterSecureStorage {
  bool failStaging = false;
  bool failActivation = false;
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
  }) {
    if ((failStaging && key.startsWith('avodah_pending_pairing:')) ||
        (failActivation && key.startsWith('avodah_pairing_token:'))) {
      throw const FileSystemException('synthetic storage failure');
    }
    return super.write(
      key: key,
      value: value,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  late HttpServer server;
  late KeyPair serverKeys;
  late String base;
  String? serverToken;
  var confirmations = 0;
  var dropResponse = false;
  var reject = false;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    serverToken = null;
    confirmations = 0;
    dropResponse = false;
    reject = false;
    serverKeys = await generateKeyPair();
    server = await HttpServer.bind('127.0.0.1', 0);
    base = 'http://127.0.0.1:${server.port}/avodah';
    server.listen((r) async {
      if (r.uri.path.endsWith('/confirm')) {
        confirmations++;
        final body = jsonDecode(await utf8.decoder.bind(r).join()) as Map;
        if (!reject) {
          final shared = await deriveSharedSecret(
            serverKeys,
            base64Decode(body['phonePubKey'] as String),
          );
          serverToken = await generateSyncVerifyCode(
            await derivePairingKey(shared),
          );
        }
        if (dropResponse) {
          (await r.response.detachSocket(writeHeaders: false)).destroy();
          return;
        }
        r.response.statusCode = reject ? 403 : 200;
        r.response.write(jsonEncode({'success': !reject}));
      } else {
        final valid =
            serverToken != null &&
            r.headers.value('X-Av-Pair-Token') == serverToken &&
            r.headers.value('X-Av-Node-Id') == 'phone';
        r.response.statusCode = valid ? 200 : 403;
        r.response.write(jsonEncode({'paired': valid}));
      }
      await r.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  test(
    'lost accepted confirmation is recoverable after client reload',
    () async {
      dropResponse = true;
      final client = CryptoSyncService(baseUrl: base, nodeId: 'phone');
      final result =
          await PhonePairingService(
            cryptoClient: client,
            nodeId: 'phone',
          ).confirmPairing(
            passcode: '123456',
            serverPubKeyBytes: serverKeys.publicKey,
          );
      expect(result.success, false);
      expect(client.isPaired, false);
      expect(client.hasPendingPairing, true);
      client.dispose();
      final reloaded = CryptoSyncService(baseUrl: base, nodeId: 'phone');
      await reloaded.loadPersistedState();
      expect(reloaded.hasPendingPairing, true);
      expect(await reloaded.recoverPendingPairing(), true);
      expect(reloaded.pairingToken, serverToken);
      expect(reloaded.hasPendingPairing, false);
      expect(
        confirmations,
        1,
        reason: 'recovery never creates another server pairing',
      );
      reloaded.dispose();
    },
  );
  test('storage denied before confirmation creates no remote orphan', () async {
    final storage = _StorageFailure()..failStaging = true;
    final client = CryptoSyncService(
      baseUrl: base,
      nodeId: 'phone',
      secureStorage: storage,
    );
    final result =
        await PhonePairingService(
          cryptoClient: client,
          nodeId: 'phone',
        ).confirmPairing(
          passcode: '123456',
          serverPubKeyBytes: serverKeys.publicKey,
        );
    expect(result.success, false);
    expect(confirmations, 0);
    expect(serverToken, isNull);
    client.dispose();
  });
  test(
    'activation failure retains a verified pending credential for exact retry',
    () async {
      final storage = _StorageFailure()..failActivation = true;
      final client = CryptoSyncService(
        baseUrl: base,
        nodeId: 'phone',
        secureStorage: storage,
      );
      final result =
          await PhonePairingService(
            cryptoClient: client,
            nodeId: 'phone',
          ).confirmPairing(
            passcode: '123456',
            serverPubKeyBytes: serverKeys.publicKey,
          );
      expect(result.success, false);
      expect(client.hasPendingPairing, true);
      expect(client.isPaired, false);
      storage.failActivation = false;
      expect(await client.recoverPendingPairing(), true);
      expect(client.pairingToken, serverToken);
      expect(confirmations, 1);
      client.dispose();
    },
  );
  test('rejected proof clears pending state without activating it', () async {
    reject = true;
    final client = CryptoSyncService(baseUrl: base, nodeId: 'phone');
    final result =
        await PhonePairingService(
          cryptoClient: client,
          nodeId: 'phone',
        ).confirmPairing(
          passcode: '000000',
          serverPubKeyBytes: serverKeys.publicKey,
        );
    expect(result.success, false);
    expect(client.hasPendingPairing, false);
    expect(client.isPaired, false);
    client.dispose();
  });
}
