/// TLS-capable HTTP client for secure sync communication.
///
/// Wraps dart:io HttpClient with SecurityContext for TLS,
/// badCertificateCallback that shows certificate fingerprint for user
/// approval, and X-Av-Pair-Token / X-Av-Node-Id header injection
/// on all /api/sync/* requests.
///
/// ## Certificate Approval Flow
///
/// When badCertificateCallback fires:
/// 1. Extract SHA-256 fingerprint from the server's certificate
/// 2. Check if fingerprint is already approved (in-memory or secure storage)
/// 3. If not approved, reject the connection and emit a certificate challenge
/// 4. Caller should invoke [triggerCertApproval] to show UI, then retry
///
/// Dart HttpClient defaults to TLS 1.2+ on modern Dart versions.
library;

import 'dart:async';
import 'dart:convert' as dart_convert;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kPairingTokenKey = 'avodah_pairing_token';
const _kApprovedCertFingerprintKey = 'avodah_approved_cert_fingerprint';
const _kServerPubKeyKey = 'avodah_server_pub_key';

/// TLS-capable HTTP client for secure sync.
///
/// Uses dart:io HttpClient with SecurityContext.
/// Adds X-Av-Pair-Token and X-Av-Node-Id headers to all /api/sync/*
/// requests when paired.
///
/// ## Certificate Approval
///
/// The [badCertificateCallback] on HttpClient is synchronous and cannot
/// show a dialog. Instead, when a cert is rejected, the connection will
/// fail and the caller should call [triggerCertApproval] to show the
/// approval UI. The fingerprint is then stored and subsequent requests
/// will pass the callback.
class CryptoSyncService {
  final String baseUrl;

  HttpClient? _client;
  final FlutterSecureStorage _secureStorage;

  /// The approved certificate fingerprint (loaded from secure storage).
  String? _approvedFingerprint;

  /// Pending fingerprint that needs approval (set when cert is rejected).
  String? _pendingFingerprint;

  /// Completer for the cert approval future.
  Completer<bool>? _certApprovalCompleter;

  /// Current pairing token (loaded from secure storage when paired).
  String? _pairingToken;

  /// Node ID for this phone (for X-Av-Node-Id header).
  final String nodeId;

  CryptoSyncService({
    required this.baseUrl,
    required this.nodeId,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _client = _createHttpClient();
  }

  HttpClient _createHttpClient() {
    final context = SecurityContext(withTrustedRoots: true);
    final client = HttpClient(context: context);

    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      final fingerprint = _computeFingerprint(cert);
      debugPrint('[CryptoSync] Cert not trusted from $host:$port — fingerprint: $fingerprint');

      // If already approved, allow
      if (_approvedFingerprint == fingerprint) {
        debugPrint('[CryptoSync] Fingerprint already approved, allowing');
        return true;
      }

      // Store pending fingerprint and trigger approval
      _pendingFingerprint = fingerprint;
      _certApprovalCompleter = Completer<bool>();

      // Attempt to show approval UI (caller must handle this via checkPendingCert)
      // Return false to reject the connection for now
      return false;
    };

    return client;
  }

  /// Checks if there is a pending certificate approval request.
  ///
  /// Returns the pending fingerprint, or null if none.
  String? checkPendingCertFingerprint() => _pendingFingerprint;

  /// Triggers the certificate approval flow.
  ///
  /// Caller should show the fingerprint to the user and then call
  /// [approveCert] or [rejectCert] to resolve.
  Completer<bool> get certApprovalCompleter {
    if (_certApprovalCompleter == null) {
      _certApprovalCompleter = Completer<bool>();
    }
    return _certApprovalCompleter!;
  }

  /// Approves the pending certificate fingerprint.
  ///
  /// Persists to secure storage so it survives app restart.
  Future<void> approveCert(String fingerprint) async {
    _approvedFingerprint = fingerprint;
    await _secureStorage.write(key: _kApprovedCertFingerprintKey, value: fingerprint);
    _pendingFingerprint = null;
    _certApprovalCompleter?.complete(true);
    _certApprovalCompleter = null;
    debugPrint('[CryptoSync] Certificate fingerprint approved and stored: $fingerprint');
  }

  /// Rejects the pending certificate fingerprint.
  void rejectCert() {
    _pendingFingerprint = null;
    _certApprovalCompleter?.complete(false);
    _certApprovalCompleter = null;
    debugPrint('[CryptoSync] Certificate fingerprint rejected');
  }

  /// Computes SHA-256 fingerprint of an X509Certificate.
  ///
  /// Returns the fingerprint as a lowercase hex string with colon separators.
  String _computeFingerprint(X509Certificate cert) {
    final derBytes = cert.der;
    final hash = _sha256Sync(derBytes);
    return hash
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toLowerCase();
  }

  /// Computes SHA-256 of [data] synchronously.
  ///
  /// Uses a simple implementation for certificate fingerprint display.
  /// Not for cryptographic security — only for visual verification.
  List<int> _sha256Sync(List<int> data) {
    // Rotate right
    int rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xFFFFFFFF;
    int ch(int x, int y, int z) => (x & y) ^ (~x & z);
    int maj(int x, int y, int z) => (x & y) ^ (x & z) ^ (y & z);
    int sigma0(int x) => rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
    int sigma1(int x) => rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
    int gamma0(int x) => rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
    int gamma1(int x) => rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);

    // Initial hash values (first 32 bits of fractional parts of square roots of first 8 primes)
    final h = [
      0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
      0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ];

    // Round constants (first 32 bits of fractional parts of cube roots of first 64 primes)
    final k = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];

    // Pre-processing: pad the message
    final message = Uint8List.fromList(data);
    final originalLength = message.length;
    final bitLength = originalLength * 8;

    // Pad to 64 bytes (512 bits) boundary
    final padded = Uint8List(((originalLength + 9) ~/ 64 + 1) * 64);
    padded.setAll(0, message);
    padded[originalLength] = 0x80;

    // Write bit length as big-endian 64-bit integer at the end
    final view = ByteData.sublistView(padded);
    view.setUint32(padded.length - 4, (bitLength ~/ 0x100000000) & 0xFFFFFFFF);
    view.setUint32(padded.length - 8, bitLength & 0xFFFFFFFF);

    // Process each 64-byte chunk
    for (var chunkStart = 0; chunkStart < padded.length; chunkStart += 64) {
      final w = List<int>.filled(64, 0);

      // Copy chunk into first 16 words
      for (var i = 0; i < 16; i++) {
        w[i] = view.getUint32(chunkStart + i * 4);
      }

      // Extend to remaining words
      for (var i = 16; i < 64; i++) {
        w[i] = (gamma1(w[i - 2]) + w[i - 7] + gamma0(w[i - 15]) + w[i - 16]) & 0xFFFFFFFF;
      }

      var a = h[0], b = h[1], c = h[2], d = h[3];
      var e = h[4], f = h[5], g = h[6], hh = h[7];

      for (var i = 0; i < 64; i++) {
        final t1 = (hh + sigma1(e) + ch(e, f, g) + k[i] + w[i]) & 0xFFFFFFFF;
        final t2 = (sigma0(a) + maj(a, b, c)) & 0xFFFFFFFF;
        hh = g;
        g = f;
        f = e;
        e = (d + t1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & 0xFFFFFFFF;
      }

      h[0] = (h[0] + a) & 0xFFFFFFFF;
      h[1] = (h[1] + b) & 0xFFFFFFFF;
      h[2] = (h[2] + c) & 0xFFFFFFFF;
      h[3] = (h[3] + d) & 0xFFFFFFFF;
      h[4] = (h[4] + e) & 0xFFFFFFFF;
      h[5] = (h[5] + f) & 0xFFFFFFFF;
      h[6] = (h[6] + g) & 0xFFFFFFFF;
      h[7] = (h[7] + hh) & 0xFFFFFFFF;
    }

    return h.map((v) => [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF]).expand((x) => x).toList();
  }

  /// Returns true if a pairing token is stored.
  bool get isPaired => _pairingToken != null && _pairingToken!.isNotEmpty;

  /// Returns the current pairing token, or null if not paired.
  String? get pairingToken => _pairingToken;

  /// Sets the pairing token to use for authenticated requests.
  void setPairingToken(String? token) {
    _pairingToken = token;
  }

  /// Loads persisted pairing state from secure storage.
  Future<void> loadPersistedState() async {
    _pairingToken = await _secureStorage.read(key: _kPairingTokenKey);
    _approvedFingerprint =
        await _secureStorage.read(key: _kApprovedCertFingerprintKey);
    debugPrint('[CryptoSync] Loaded state — isPaired: $isPaired, '
        'fingerprint stored: ${_approvedFingerprint != null}');
  }

  /// Persists the pairing token to secure storage.
  Future<void> persistPairingToken(String token) async {
    _pairingToken = token;
    await _secureStorage.write(key: _kPairingTokenKey, value: token);
  }

  /// Clears the persisted pairing token (on unpair).
  Future<void> clearPairingToken() async {
    _pairingToken = null;
    await _secureStorage.delete(key: _kPairingTokenKey);
  }

  /// Stores the server's X25519 public key for replay protection.
  Future<void> storeServerPubKey(List<int> pubKeyBytes) async {
    final encoded = dart_convert.base64Encode(pubKeyBytes);
    await _secureStorage.write(key: _kServerPubKeyKey, value: encoded);
  }

  /// Returns the stored server public key, or null if not stored.
  Future<List<int>?> getStoredServerPubKey() async {
    final encoded = await _secureStorage.read(key: _kServerPubKeyKey);
    if (encoded == null) return null;
    return dart_convert.base64Decode(encoded);
  }

  // ============================================================
  // HTTP Methods with auth header injection
  // ============================================================

  /// Makes a GET request to [path] with optional auth headers for sync endpoints.
  Future<HttpClientResponse> get(
    String path, {
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = _buildUri(path, queryParams);
    final request = await _client!.getUrl(uri);
    _applySyncHeaders(request);
    return request.close().timeout(timeout);
  }

  /// Makes a POST request to [path] with optional auth headers for sync endpoints.
  Future<HttpClientResponse> post(
    String path, {
    Map<String, String>? headers,
    String? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = _buildUri(path);
    final request = await _client!.postUrl(uri);
    if (headers != null) {
      headers.forEach(request.headers.set);
    }
    _applySyncHeaders(request);
    if (body != null) {
      request.write(body);
    }
    return request.close().timeout(timeout);
  }

  /// Makes a DELETE request to [path] with optional auth headers for sync endpoints.
  Future<HttpClientResponse> delete(
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = _buildUri(path);
    final request = await _client!.deleteUrl(uri);
    if (headers != null) {
      headers.forEach(request.headers.set);
    }
    _applySyncHeaders(request);
    return request.close().timeout(timeout);
  }

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    var uriString = baseUrl;
    if (!uriString.endsWith('/')) uriString += '/';
    uriString += path;
    return Uri.parse(uriString).replace(queryParameters: queryParams);
  }

  /// Adds X-Av-Pair-Token and X-Av-Node-Id headers for /api/sync/* requests.
  void _applySyncHeaders(HttpClientRequest request) {
    if (_pairingToken != null && _pairingToken!.isNotEmpty) {
      request.headers.set('X-Av-Pair-Token', _pairingToken!);
    }
    request.headers.set('X-Av-Node-Id', nodeId);
  }

  /// Closes the HTTP client.
  void dispose() {
    _client?.close(force: true);
    _client = null;
  }
}
