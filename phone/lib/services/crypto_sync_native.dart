/// Native TLS transport and server-scoped secure credential storage.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/server_scope.dart';

class CryptoSyncService {
  final String baseUrl;
  final String nodeId;
  final FlutterSecureStorage _storage;
  late final String _scope;
  late final HttpClient _client;
  String? _pairingToken;
  String? _approvedFingerprint;
  String? _pendingFingerprint;
  Completer<bool>? _certApprovalCompleter;
  bool _hasLegacyPairing = false;

  static const legacyTokenKey = 'avodah_pairing_token';
  static const legacyBindingKey = 'avodah_legacy_pairing_bound_to';
  String get _tokenKey => 'avodah_pairing_token:$_scope';
  String get _certKey => 'avodah_approved_cert_fingerprint:$_scope';
  String get _serverKey => 'avodah_server_pub_key:$_scope';

  CryptoSyncService({
    required this.baseUrl,
    required this.nodeId,
    FlutterSecureStorage? secureStorage,
  }) : _storage = secureStorage ?? const FlutterSecureStorage() {
    _scope = normalizeServerScope(baseUrl);
    _client = HttpClient(context: SecurityContext(withTrustedRoots: true));
    _client.badCertificateCallback = (cert, host, port) {
      final fingerprint = sha256
          .convert(cert.der)
          .bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':');
      if (_approvedFingerprint == fingerprint) return true;
      _pendingFingerprint = fingerprint;
      _certApprovalCompleter ??= Completer<bool>();
      return false;
    };
  }

  String? get pairingToken => _pairingToken;
  bool get isPaired => _pairingToken?.isNotEmpty ?? false;
  bool get hasLegacyPairing => _hasLegacyPairing;
  String get serverScope => _scope;
  void setPairingToken(String? token) => _pairingToken = token;

  Future<void> loadPersistedState() async {
    _pairingToken = await _storage.read(key: _tokenKey);
    _approvedFingerprint = await _storage.read(key: _certKey);
    final legacy = await _storage.read(key: legacyTokenKey);
    final boundTo = await _storage.read(key: legacyBindingKey);
    _hasLegacyPairing =
        !isPaired &&
        legacy != null &&
        legacy.isNotEmpty &&
        (boundTo == null || boundTo == _scope);
  }

  /// Only call after the human explicitly confirms the displayed server is
  /// the original trusted server. No automatic legacy token forwarding.
  /// Server-first rollout supplies this side-effect-free authenticated probe.
  Future<void> migrateLegacyPairing() async {
    await loadPersistedState();
    if (!_hasLegacyPairing)
      throw StateError('No saved pairing available for this server');
    final destination = Uri.parse(_scope);
    if (destination.scheme != 'https' &&
        !(InternetAddress.tryParse(destination.host)?.isLoopback ?? false)) {
      throw StateError('Pairing migration requires trusted HTTPS');
    }
    final legacy = (await _storage.read(key: legacyTokenKey))!;
    final request = await _client
        .getUrl(_buildUri('api/sync/pair'))
        .timeout(const Duration(seconds: 10));
    request.followRedirects = false;
    request.headers.set('X-Av-Node-Id', nodeId);
    request.headers.set('X-Av-Pair-Token', legacy);
    final response = await request.close().timeout(const Duration(seconds: 10));
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 10))) {
      if (bytes.length + chunk.length > 8192)
        throw StateError('Invalid pairing verification');
      bytes.addAll(chunk);
    }
    if (response.statusCode != 200 ||
        (jsonDecode(utf8.decode(bytes)) as Map)['paired'] != true) {
      throw StateError(
        'Saved pairing not verified. Update the server first or retry when online.',
      );
    }
    // Binding is durable before activation. On any failure retain the original
    // credential for retry, bound to this explicitly confirmed destination.
    await _storage.write(key: legacyBindingKey, value: _scope);
    final pub = await _storage.read(key: 'avodah_server_pub_key');
    if (pub != null) await _storage.write(key: _serverKey, value: pub);
    await persistPairingToken(legacy);
    // Retain the old secret privately for an old-app rollback. The binding
    // prevents this app importing it into another server or after local Forget.
    _hasLegacyPairing = false;
  }

  Future<void> persistPairingToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    if (await _storage.read(key: _tokenKey) != token)
      throw StateError('Credential storage failed');
    _pairingToken = token;
  }

  Future<void> clearPairingToken() async {
    // Prevent a locally forgotten/revoked migrated token from being re-imported.
    if (await _storage.read(key: legacyBindingKey) == _scope) {
      await _storage.delete(key: legacyTokenKey);
    }
    await _storage.delete(key: _tokenKey);
    _pairingToken = null;
    _hasLegacyPairing = false;
  }

  Future<void> storeServerPubKey(List<int> bytes) =>
      _storage.write(key: _serverKey, value: base64Encode(bytes));
  Future<List<int>?> getStoredServerPubKey() async {
    final value = await _storage.read(key: _serverKey);
    return value == null ? null : base64Decode(value);
  }

  String? checkPendingCertFingerprint() => _pendingFingerprint;
  Completer<bool> get certApprovalCompleter =>
      _certApprovalCompleter ??= Completer<bool>();
  Future<void> approveCert(String fingerprint) async {
    if (fingerprint != _pendingFingerprint)
      throw StateError('No matching certificate challenge');
    await _storage.write(key: _certKey, value: fingerprint);
    _approvedFingerprint = fingerprint;
    _pendingFingerprint = null;
    _certApprovalCompleter?.complete(true);
    _certApprovalCompleter = null;
  }

  void rejectCert() {
    _pendingFingerprint = null;
    _certApprovalCompleter?.complete(false);
    _certApprovalCompleter = null;
  }

  Future<HttpClientResponse> get(
    String path, {
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 10),
  }) => _send('GET', path, queryParams: queryParams).timeout(timeout);
  Future<HttpClientResponse> post(
    String path, {
    Map<String, String>? headers,
    String? body,
    Duration timeout = const Duration(seconds: 10),
  }) => _send('POST', path, headers: headers, body: body).timeout(timeout);
  Future<HttpClientResponse> delete(
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) => _send('DELETE', path, headers: headers).timeout(timeout);

  Future<HttpClientResponse> _send(
    String method,
    String path, {
    Map<String, String>? headers,
    String? body,
    Map<String, String>? queryParams,
  }) async {
    final request = await _client.openUrl(method, _buildUri(path, queryParams));
    request.followRedirects = false;
    headers?.forEach(request.headers.set);
    request.headers.set('X-Av-Node-Id', nodeId);
    if (_pairingToken != null)
      request.headers.set('X-Av-Pair-Token', _pairingToken!);
    if (body != null) request.add(utf8.encode(body));
    return request.close();
  }

  Uri _buildUri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('$_scope/$path').replace(queryParameters: params);
    if (uri.origin != Uri.parse(_scope).origin ||
        !uri.path.startsWith('${Uri.parse(_scope).path}/api/') ||
        uri.pathSegments.any((s) => s == '..' || s == '.')) {
      throw StateError('Unsafe credential destination');
    }
    return uri;
  }

  void dispose() => _client.close(force: true);
}
