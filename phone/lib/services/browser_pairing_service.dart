import 'dart:convert';

import 'package:avodah_core/avodah_core.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'agent_api_client.dart';

/// Browser transport for the existing passcode/X25519 enrollment protocol.
/// Uses the same secure-storage keys as Android; no send/PA credential required.
class BrowserPairingService {
  final AgentApiClient api;
  final FlutterSecureStorage storage;
  BrowserPairingService(
    this.api, {
    this.storage = const FlutterSecureStorage(),
  });

  Future<void> restore() async {
    api.pairingToken = await storage.read(key: 'avodah_pairing_token');
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('${api.baseUrl}$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw AgentApiException(response.statusCode, 'Device pairing failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<int>> start() async {
    final result = await _post('/api/sync/pair/start', {'nodeId': api.nodeId});
    return base64Decode(result['serverPubKey'] as String);
  }

  Future<void> confirm(String code, List<int> serverPublicKey) async {
    final keys = await generateKeyPair();
    final proof = await Hmac.sha256().calculateMac(
      keys.publicKey,
      secretKey: SecretKey(utf8.encode(code)),
    );
    final result = await _post('/api/sync/pair/confirm', {
      'nodeId': api.nodeId,
      'phonePubKey': base64Encode(keys.publicKey),
      'hmacProof': base64Encode(proof.bytes),
    });
    if (result['success'] != true) {
      throw AgentApiException(403, 'Incorrect or expired pairing code');
    }
    final shared = await deriveSharedSecret(keys, serverPublicKey);
    final token = await generateSyncVerifyCode(await derivePairingKey(shared));
    await storage.write(key: 'avodah_pairing_token', value: token);
    api.pairingToken = token;
  }
}
