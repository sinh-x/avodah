/// Phone-side pairing service for secure sync.
///
/// Implements the client-side of the Anytype-inspired passcode + X25519
/// key exchange:
///
/// ## Pairing Flow
///
/// 1. [checkPairingStatus] — GET /api/sync/status → {needsPairing, serverFingerprint?}
/// 2. [startPairing] — POST /api/sync/pair/start → {serverPubKey, expiresIn}
/// 3. [confirmPairing] — POST /api/sync/pair/confirm → {success, error?}
///    - Generates X25519 keypair
///    - Computes HMAC-SHA256(passcode, phonePubKey)
///    - Derives shared secret via X25519
///    - Derives pairing key via HMAC-SHA256(sharedSecret, "avodah-pair-v1")
///    - Persists pairing key and server pubkey
///
/// ## Subsequent Sync
///
/// [CryptoSyncService] uses the stored pairing token for all /api/sync/*
/// requests. Token = HMAC-SHA256(pairingKey, "avodah-sync-v1") (computed
/// server-side; phone just stores and sends it).
library;

import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:avodah_core/avodah_core.dart';
import 'crypto_sync_service.dart';

/// Storage keys for pairing data.
const _kPairingTokenKey = 'avodah_pairing_token';
const _kServerPubKeyKey = 'avodah_server_pub_key';

/// Result of a pairing status check.
class PairingStatus {
  final bool needsPairing;
  final String? serverFingerprint;

  PairingStatus({required this.needsPairing, this.serverFingerprint});

  factory PairingStatus.fromJson(Map<String, dynamic> json) {
    return PairingStatus(
      needsPairing: json['needsPairing'] as bool? ?? true,
      serverFingerprint: json['serverFingerprint'] as String?,
    );
  }
}

/// Result of a pairing confirmation attempt.
class PairingResult {
  final bool success;
  final String? error;

  PairingResult({required this.success, this.error});
}

/// Phone-side pairing service.
///
/// Coordinates with [CryptoSyncService] to establish and persist a
/// pairing with the sync server.
class PhonePairingService {
  final CryptoSyncService _cryptoClient;
  final FlutterSecureStorage _secureStorage;

  /// The node ID for this phone (used as the pairing ID on the server).
  final String nodeId;

  /// The derived pairing token (HMAC of pairing key, stored persistently).
  String? _pairingToken;

  PhonePairingService({
    required CryptoSyncService cryptoClient,
    required this.nodeId,
    FlutterSecureStorage? secureStorage,
  })  : _cryptoClient = cryptoClient,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Returns true if a pairing token is persisted.
  bool get isPaired => _pairingToken != null && _pairingToken!.isNotEmpty;

  /// Returns the current pairing token, or null if not paired.
  String? get pairingToken => _pairingToken;

  /// Loads persisted pairing state from secure storage.
  Future<void> loadPersistedState() async {
    _pairingToken = await _secureStorage.read(key: _kPairingTokenKey);
    debugPrint('[PhonePairing] Loaded — isPaired: $isPaired');
  }

  /// Checks the pairing status with the sync server.
  ///
  /// GET /api/sync/status
  /// Returns {needsPairing: bool, serverFingerprint?: string}
  Future<PairingStatus> checkPairingStatus() async {
    try {
      final response = await _cryptoClient.get('api/sync/status');
      final body = await _readResponseBody(response);
      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return PairingStatus.fromJson(json);
      } else {
        debugPrint('[PhonePairing] Status check failed: HTTP ${response.statusCode} — $body');
        // Treat non-200 as needs pairing (server might not have pairing endpoints yet)
        return PairingStatus(needsPairing: true);
      }
    } catch (e) {
      debugPrint('[PhonePairing] Status check error: $e');
      // Network error — assume needs pairing
      return PairingStatus(needsPairing: true);
    }
  }

  /// Starts the pairing handshake with the sync server.
  ///
  /// POST /api/sync/pair/start
  /// Body: {nodeId: string}
  /// Returns {serverPubKey: string, expiresIn: int}
  ///
  /// The passcode is displayed ONLY on the server console. The user must
  /// manually enter it on the phone to complete pairing.
  Future<Map<String, dynamic>> startPairing() async {
    final body = jsonEncode({'nodeId': nodeId});
    final response = await _cryptoClient.post(
      'api/sync/pair/start',
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    final responseBody = await _readResponseBody(response);
    if (response.statusCode != 200) {
      throw Exception('Pairing start failed: HTTP ${response.statusCode} — $responseBody');
    }
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  /// Completes the pairing handshake.
  ///
  /// POST /api/sync/pair/confirm
  /// Body: {nodeId, phonePubKey, hmacProof}
  /// Returns {success: bool, error?: string}
  ///
  /// 1. Generates X25519 keypair
  /// 2. Computes HMAC-SHA256(passcode, phonePubKey)
  /// 3. Derives shared secret via X25519(phonePrivKey, serverPubKey)
  /// 4. Derives pairing key via HMAC-SHA256(sharedSecret, "avodah-pair-v1")
  /// 5. Persists pairing token and server pubkey
  Future<PairingResult> confirmPairing({
    required String passcode,
    required List<int> serverPubKeyBytes,
  }) async {
    // Generate X25519 keypair for this pairing session
    final keyPair = await generateKeyPair();
    final phonePubKeyBytes = keyPair.publicKey;

    // Compute HMAC proof: HMAC-SHA256(passcode, phonePubKey)
    final hmacProof = await _computePasscodeProof(passcode, phonePubKeyBytes);

    // Build confirm request body
    final body = jsonEncode({
      'nodeId': nodeId,
      'phonePubKey': base64Encode(phonePubKeyBytes),
      'hmacProof': base64Encode(hmacProof),
    });

    final response = await _cryptoClient.post(
      'api/sync/pair/confirm',
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    final responseBody = await _readResponseBody(response);

    if (response.statusCode != 200) {
      return PairingResult(success: false, error: 'HTTP ${response.statusCode}');
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final success = json['success'] as bool? ?? false;
    if (!success) {
      return PairingResult(
        success: false,
        error: json['error'] as String? ?? 'Unknown error',
      );
    }

    // Derive shared secret and pairing key
    final sharedSecret = await deriveSharedSecret(keyPair, serverPubKeyBytes);
    final pairingKey = await derivePairingKey(sharedSecret);

    // Generate and store the pairing token: HMAC-SHA256(pairingKey, "avodah-sync-v1")
    final syncToken = await generateSyncVerifyCode(pairingKey);

    // Store the pairing token and server pubkey
    await _secureStorage.write(key: _kPairingTokenKey, value: syncToken);
    await _secureStorage.write(
      key: _kServerPubKeyKey,
      value: base64Encode(serverPubKeyBytes),
    );
    _pairingToken = syncToken;
    _cryptoClient.setPairingToken(syncToken);

    // Also store the server pubkey in CryptoSyncService for replay protection
    await _cryptoClient.storeServerPubKey(serverPubKeyBytes);

    debugPrint('[PhonePairing] Pairing confirmed and persisted. Token stored.');
    return PairingResult(success: true);
  }

  /// Revokes the current pairing.
  ///
  /// DELETE /api/sync/pair
  /// Clears local pairing state and notifies the server.
  Future<void> revokePairing() async {
    try {
      await _cryptoClient.delete('api/sync/pair');
    } catch (e) {
      debugPrint('[PhonePairing] Revoke request failed (non-fatal): $e');
    }
    _pairingToken = null;
    _cryptoClient.setPairingToken(null);
    await _secureStorage.delete(key: _kPairingTokenKey);
    await _secureStorage.delete(key: _kServerPubKeyKey);
    debugPrint('[PhonePairing] Pairing revoked locally.');
  }

  /// Computes HMAC-SHA256(passcode, phonePubKey) for pairing proof.
  ///
  /// Uses passcode as the HMAC secret key and phonePubKey as the message.
  Future<Uint8List> _computePasscodeProof(
      String passcode, List<int> phonePubKey) async {
    final hmac = Hmac.sha256();
    final secretKey = SecretKey(utf8.encode(passcode));
    final mac = await hmac.calculateMac(
      Uint8List.fromList(phonePubKey),
      secretKey: secretKey,
    );
    return Uint8List.fromList(mac.bytes);
  }

  Future<String> _readResponseBody(HttpClientResponse response) async {
    return utf8.decoder.bind(response).join();
  }
}
