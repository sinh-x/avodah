import 'dart:convert';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_viewer/services/agent_api_client.dart';
import 'package:avodah_viewer/services/browser_pairing_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'browser uses existing X25519 enrollment and restores only for same server/node',
    () async {
      final serverKeys = await generateKeyPair();
      String? expectedToken;
      final client = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['nodeId'], 'browser-node');
        if (request.url.path.endsWith('/start')) {
          return http.Response(
            jsonEncode({'serverPubKey': base64Encode(serverKeys.publicKey)}),
            200,
          );
        }
        final phoneKey = base64Decode(body['phonePubKey'] as String);
        final shared = await deriveSharedSecret(serverKeys, phoneKey);
        expectedToken = await generateSyncVerifyCode(
          await derivePairingKey(shared),
        );
        expect(base64Decode(body['hmacProof'] as String), hasLength(32));
        return http.Response('{"success":true}', 200);
      });
      final api = AgentApiClient(baseUrl: 'https://server.test')
        ..nodeId = 'browser-node';
      final pairing = BrowserPairingService(api, client: client);
      final key = await pairing.start();
      await pairing.confirm('123456', key);
      expect(api.pairingToken, expectedToken);
      api.pairingToken = null;
      await pairing.restore();
      expect(api.pairingToken, expectedToken);
      final other = AgentApiClient(baseUrl: 'https://other.test')
        ..nodeId = 'browser-node';
      await BrowserPairingService(other).restore();
      expect(other.pairingToken, isNull);
      api.dispose();
      other.dispose();
      client.close();
    },
  );

  test('rejected pairing never persists credentials', () async {
    final client = MockClient(
      (_) async => http.Response('{"success":false}', 200),
    );
    final keys = await generateKeyPair();
    final api = AgentApiClient(baseUrl: 'https://server.test')
      ..nodeId = 'browser-node';
    final pairing = BrowserPairingService(api, client: client);
    await expectLater(
      pairing.confirm('wrong', keys.publicKey),
      throwsA(isA<AgentApiException>()),
    );
    await pairing.restore();
    expect(api.pairingToken, isNull);
    client.close();
    api.dispose();
  });
}
