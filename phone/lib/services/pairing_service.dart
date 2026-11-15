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

import 'package:avodah_core/avodah_core.dart';
import 'crypto_sync_service.dart';

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

  /// The node ID for this phone (used as the pairing ID on the server).
  final String nodeId;

  /// The derived pairing token (HMAC of pairing key, stored persistently).
  String? _pairingToken;

  PhonePairingService({
    required CryptoSyncService cryptoClient,
    required this.nodeId,
  }) : _cryptoClient = cryptoClient;

  /// Returns true if a pairing token is persisted.
  bool get isPaired => _pairingToken != null && _pairingToken!.isNotEmpty;

  /// Returns the current pairing token, or null if not paired.
  String? get pairingToken => _pairingToken;

  /// Loads persisted pairing state from secure storage.
  Future<void> loadPersistedState() async {
    await _cryptoClient.loadPersistedState();
    _pairingToken = _cryptoClient.pairingToken;
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
        throw StateError(
          'Pairing status unavailable (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      // Network/TLS/status failure is not evidence of pairing loss. Propagate
      // so the pairing screen can handle a native certificate challenge and
      // background sync reports offline instead of opening an enrollment modal.
      rethrow;
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
      throw Exception(
        'Pairing start failed: HTTP ${response.statusCode} — $responseBody',
      );
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

    final sharedSecret = await deriveSharedSecret(keyPair, serverPubKeyBytes);
    final pairingKey = await derivePairingKey(sharedSecret);
    final syncToken = await generateSyncVerifyCode(pairingKey);
    // Stage one durable, server-scoped recovery record BEFORE the server can
    // accept confirmation. It is not an active credential until verified.
    try {
      await _cryptoClient.stagePairing(syncToken, serverPubKeyBytes);
    } catch (_) {
      return PairingResult(
        success: false,
        error:
            'Credential storage unavailable. Pairing was not confirmed; local records are preserved.',
      );
    }
    try {
      final response = await _cryptoClient.post(
        'api/sync/pair/confirm',
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final responseBody = await _readResponseBody(response);
      if (response.statusCode == 403 || response.statusCode == 400) {
        await _cryptoClient.clearPendingPairing();
        return PairingResult(
          success: false,
          error: 'Code or challenge rejected. Restart pairing.',
        );
      }
      if (response.statusCode != 200 ||
          (jsonDecode(responseBody) as Map)['success'] != true) {
        return PairingResult(
          success: false,
          error: 'Verification needed; retry saved pairing verification.',
        );
      }
      if (!await _cryptoClient.recoverPendingPairing()) {
        return PairingResult(
          success: false,
          error: 'Pairing could not be verified. Restart pairing.',
        );
      }
      _pairingToken = _cryptoClient.pairingToken;
      return PairingResult(success: true);
    } catch (_) {
      // The server might have accepted a lost response. Keep the exact derived
      // credential privately so reload/retry can verify instead of orphaning it.
      return PairingResult(
        success: false,
        error:
            'Verification needed. Saved pairing recovery is available; local records are preserved.',
      );
    }
  }

  /// Revokes the current pairing.
  ///
  /// DELETE /api/sync/pair
  /// Clears local pairing state and notifies the server.
  Future<void> revokePairing() async {
    final response = await _cryptoClient.delete('api/sync/pair');
    await _readResponseBody(response);
    if (response.statusCode != 200) {
      throw StateError(
        'Remote revoke not confirmed (HTTP ${response.statusCode})',
      );
    }
    await forgetLocally();
  }

  Future<void> forgetLocally() async {
    await _cryptoClient.clearPairingToken();
    _pairingToken = null;
  }

  /// Computes HMAC-SHA256(passcode, phonePubKey) for pairing proof.
  ///
  /// Uses passcode as the HMAC secret key and phonePubKey as the message.
  Future<Uint8List> _computePasscodeProof(
    String passcode,
    List<int> phonePubKey,
  ) async {
    final hmac = Hmac.sha256();
    final secretKey = SecretKey(utf8.encode(passcode));
    final mac = await hmac.calculateMac(
      Uint8List.fromList(phonePubKey),
      secretKey: secretKey,
    );
    return Uint8List.fromList(mac.bytes);
  }

  Future<String> _readResponseBody(Stream<List<int>> response) async {
    return utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 10));
  }
}
