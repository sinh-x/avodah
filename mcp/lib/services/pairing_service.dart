/// Server-side pairing service for secure sync.
///
/// Implements the Anytype-inspired passcode + X25519 key exchange:
///
/// ## Pairing Flow
///
/// ### POST /api/sync/pair/start
/// - Generates a random 6-digit passcode (valid 5 minutes)
/// - Generates an ephemeral X25519 keypair
/// - Returns {serverPubKey, expiresIn}
/// - Passcode is ONLY displayed on the server console (not sent to phone)
/// - User must manually enter the passcode on the phone
///
/// ### POST /api/sync/pair/confirm
/// - Accepts {phonePubKey, hmacProof}
/// - phonePubKey: base64 X25519 public key from phone
/// - hmacProof: base64 HMAC-SHA256(passcode, phonePubKey)
/// - Verifies HMAC proof against stored passcode
/// - Derives shared secret via X25519
/// - Stores pairing key (HMAC of shared secret) in paired_devices table
///
/// ## Subsequent Sync
///
/// All /api/sync/* requests must include:
/// - X-Av-Pair-Token: <base64(HMAC-SHA256(pairingKey, "avodah-sync-v1"))>
///
/// Server verifies token against stored pairing key before accepting requests.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' hide KeyPair;
import 'package:avodah_core/avodah_core.dart';
import 'package:drift/drift.dart' show Value;

/// In-memory state for an in-progress pairing handshake.
class _PairingState {
  final String passcode;
  final List<int> serverPrivateKey; // ephemeral X25519 private key
  final List<int> serverPublicKey; // ephemeral X25519 public key
  final DateTime expiresAt;
  int failures = 0;

  _PairingState({
    required this.passcode,
    required this.serverPrivateKey,
    required this.serverPublicKey,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Manages the pairing handshake for secure sync.
class PairingService {
  final AppDatabase db;

  /// In-memory pairing handshakes keyed by nodeId.
  final Map<String, _PairingState> _handshakes = {};

  /// Private operator code delivery; never write codes to container logs.
  final void Function(String code) deliverCode;
  final DateTime Function() now;
  final Map<String, int> _starts = {};
  DateTime? _window;
  final Map<String, List<WebSocket>> _sockets = {};
  final Set<String> _busy = {};

  PairingService(
      {required this.db,
      void Function(String)? deliverCode,
      DateTime Function()? now})
      : deliverCode = deliverCode ?? _deliverPrivately,
        now = now ?? DateTime.now;

  static void _deliverPrivately(String code) {
    // /dev/tty is the private foreground operator console, not stdout/stderr.
    final tty = File('/dev/tty').openSync(mode: FileMode.writeOnly);
    try {
      tty.writeStringSync('Avodah pairing code (valid 5 minutes): $code\n');
    } finally {
      tty.closeSync();
    }
  }

  void trackSocket(String nodeId, WebSocket socket) {
    _sockets.putIfAbsent(nodeId, () => []).add(socket);
    socket.done.whenComplete(() => _sockets[nodeId]?.remove(socket));
  }

  bool admitStart(String source) {
    if (_window == null || now().difference(_window!).inMinutes >= 1) {
      _window = now();
      _starts.clear();
    }
    final total = _starts.values.fold(0, (a, b) => a + b);
    if (total >= 100 || (_starts[source] ?? 0) >= 10) return false;
    _starts[source] = (_starts[source] ?? 0) + 1;
    return true;
  }

  static bool validNode(String node) =>
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$').hasMatch(node);

  /// GET /api/sync/status
  ///
  /// Returns whether the server needs pairing.
  Future<Map<String, dynamic>> getStatus() async {
    final paired = await db.select(db.pairedDevices).get();
    return {'needsPairing': paired.isEmpty};
  }

  /// POST /api/sync/pair/start
  ///
  /// Generates a 6-digit passcode and ephemeral X25519 keypair.
  /// Returns {serverPubKey, expiresIn}.
  ///
  /// The passcode is only displayed on the server console — it is NOT
  /// sent to the phone. The user must manually key it in on the phone
  /// for multi-level authentication.
  Future<Map<String, dynamic>> startPairing(String nodeId) async {
    _handshakes.removeWhere((_, state) => !now().isBefore(state.expiresAt));
    if (_busy.contains(nodeId) || _handshakes.length + _busy.length >= 32) {
      throw StateError('Enrollment unavailable');
    }
    _busy.add(nodeId);
    try {
      return await _startPairing(nodeId);
    } finally {
      _busy.remove(nodeId);
    }
  }

  Future<Map<String, dynamic>> _startPairing(String nodeId) async {
    // Clean up expired handshakes
    _handshakes.removeWhere((_, state) => !now().isBefore(state.expiresAt));
    if (!validNode(nodeId) ||
        _handshakes.length >= 32 ||
        await getPairedDevice(nodeId) != null) {
      throw StateError('Enrollment unavailable');
    }

    final passcode = generateSixDigitCode();
    final keyPair = await generateKeyPair();

    final state = _PairingState(
      passcode: passcode,
      serverPrivateKey: keyPair.privateKey,
      serverPublicKey: keyPair.publicKey,
      expiresAt: now().add(const Duration(minutes: 5)),
    );
    _handshakes[nodeId] = state;

    try {
      deliverCode(passcode);
    } catch (_) {
      _handshakes.remove(nodeId);
      throw StateError('Private operator console unavailable');
    }

    return {
      'serverPubKey': base64Encode(keyPair.publicKey),
      'expiresIn': 300,
    };
  }

  /// POST /api/sync/pair/confirm
  ///
  /// Accepts {phonePubKey, hmacProof, origin?}.
  /// Derives shared secret, stores pairing key, returns {success, error?}.
  Future<Map<String, dynamic>> confirmPairing({
    required String nodeId,
    required String phonePubKeyBase64,
    required String hmacProofBase64,
    String? origin,
  }) async {
    if (_busy.contains(nodeId)) {
      return {'success': false, 'error': 'Enrollment busy'};
    }
    _busy.add(nodeId);
    try {
      return await _confirmPairing(nodeId: nodeId,
        phonePubKeyBase64: phonePubKeyBase64, hmacProofBase64: hmacProofBase64,
        origin: origin);
    } finally {
      _busy.remove(nodeId);
    }
  }

  Future<Map<String, dynamic>> _confirmPairing({required String nodeId,
    required String phonePubKeyBase64, required String hmacProofBase64,
    String? origin}) async {
    // Remove before the first await: concurrent confirmations cannot replay.
    final state = _handshakes.remove(nodeId);
    if (state == null || !now().isBefore(state.expiresAt)) {
      return {
        'success': false,
        'error': 'Pairing timeout — restart from phone.'
      };
    }

    late List<int> phonePubKey;
    late Uint8List hmacProof;
    try {
      phonePubKey = base64Decode(phonePubKeyBase64);
      hmacProof = base64Decode(hmacProofBase64);
      if (phonePubKey.length != 32 || hmacProof.length != 32) {
        throw const FormatException();
      }
    } catch (_) {
      if (++state.failures < 5) _handshakes[nodeId] = state;
      return {'success': false, 'error': 'Invalid pairing proof.'};
    }

    // Verify HMAC: HMAC-SHA256(passcode, phonePubKey)
    final expectedHmac =
        await _computeHmacPasscode(state.passcode, phonePubKey);
    if (!_constantTimeEquals(hmacProof, expectedHmac)) {
      if (++state.failures < 5) _handshakes[nodeId] = state;
      return {'success': false, 'error': 'Invalid pairing proof.'};
    }

    // Derive shared secret via X25519
    final serverKeyPair = KeyPair(
      publicKey: state.serverPublicKey,
      privateKey: state.serverPrivateKey,
    );
    final sharedSecret = await deriveSharedSecret(serverKeyPair, phonePubKey);

    // Derive pairing key: HMAC-SHA256(sharedSecret, "avodah-pair-v1")
    final pairingKey = await derivePairingKey(sharedSecret);

    // Store pairing: phone's public key + pairing key + origin for CORS
    await db.into(db.pairedDevices).insertOnConflictUpdate(
          PairedDevicesCompanion.insert(
            id: nodeId,
            publicKey: Uint8List.fromList(phonePubKey),
            privateKey: Value(Uint8List.fromList(pairingKey)),
            origin: Value(origin),
            created: DateTime.now().millisecondsSinceEpoch,
            lastSeen: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    _handshakes.remove(nodeId);

    stderr.writeln('Device paired successfully: $nodeId');

    return {'success': true};
  }

  /// Verifies an X-Av-Pair-Token header from a paired device.
  ///
  /// Returns true if the token is valid for this device.
  Future<bool> verifyPairToken(String nodeId, String tokenBase64) async {
    if (!validNode(nodeId) || tokenBase64.length != 44) return false;
    final device = await (db.select(db.pairedDevices)
          ..where((d) => d.id.equals(nodeId)))
        .getSingleOrNull();

    if (device == null) return false;

    // Pairing key stored in privateKey column
    final pairingKey = device.privateKey;
    if (pairingKey == null) return false;

    // Derive expected token: HMAC-SHA256(pairingKey, "avodah-sync-v1")
    final expectedToken = await generateSyncVerifyCode(pairingKey);

    return verifySyncCode(expectedToken, tokenBase64);
  }

  /// Returns the stored pairing for a device, or null if not paired.
  Future<PairedDevice?> getPairedDevice(String nodeId) async {
    return (db.select(db.pairedDevices)..where((d) => d.id.equals(nodeId)))
        .getSingleOrNull();
  }

  /// Revokes pairing for a device.
  Future<void> revokePairing(String nodeId) async {
    for (final socket in _sockets.remove(nodeId) ?? <WebSocket>[]) {
      socket.close(WebSocketStatus.policyViolation, 'Pairing revoked');
    }
    await (db.delete(db.pairedDevices)..where((d) => d.id.equals(nodeId))).go();
    stderr.writeln('Pairing revoked for device: $nodeId');
  }

  /// Returns all paired devices (for admin/status purposes).
  Future<List<PairedDevice>> listPairedDevices() async {
    return db.select(db.pairedDevices).get();
  }

  // ============================================================
  // Internal HMAC helpers
  // ============================================================

  /// Computes HMAC-SHA256(passcode, phonePubKey) for pairing proof verification.
  Future<Uint8List> _computeHmacPasscode(
      String passcode, List<int> phonePubKey) async {
    final hmac = Hmac.sha256();
    final secretKey = SecretKey(utf8.encode(passcode));
    final mac = await hmac.calculateMac(
      Uint8List.fromList(phonePubKey),
      secretKey: secretKey,
    );
    return Uint8List.fromList(mac.bytes);
  }

  /// Constant-time byte comparison to prevent timing attacks.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
