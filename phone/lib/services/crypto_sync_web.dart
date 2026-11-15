import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../utils/server_scope.dart';

/// Browser credentials are origin storage, not HttpOnly or XSS-isolated.
/// Every request re-reads storage so other tabs' Forget/Revoke takes effect.
class CryptoSyncService {
  final String baseUrl;
  final String nodeId;
  late final String _key;
  String? _transientToken;
  String get serverScope => normalizeServerScope(baseUrl);
  bool get hasLegacyPairing => false;
  bool get hasPendingPairing =>
      web.window.localStorage.getItem('$_key.pending') != null;
  Future<void> stagePairing(String token, List<int> serverPubKey) async {
    final value = jsonEncode({
      'token': token,
      'server': base64Encode(serverPubKey),
      'node': nodeId,
    });
    web.window.localStorage.setItem('$_key.pending', value);
    if (web.window.localStorage.getItem('$_key.pending') != value)
      throw StateError('Credential storage failed');
  }

  Future<void> clearPendingPairing() async =>
      web.window.localStorage.removeItem('$_key.pending');
  Future<bool> recoverPendingPairing() async {
    final value = web.window.localStorage.getItem('$_key.pending');
    if (value == null) throw StateError('No pending pairing');
    final record = jsonDecode(value) as Map;
    if (record['node'] != nodeId)
      throw StateError('Pending device identity differs');
    final token = record['token'] as String;
    final response = await _send(
      'GET',
      'api/sync/pair',
      tokenOverride: token,
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 403) {
      await clearPendingPairing();
      return false;
    }
    final body = jsonDecode(utf8.decode(response.bytes)) as Map;
    if (response.statusCode != 200 || body['paired'] != true)
      throw StateError('Pairing verification unavailable');
    web.window.localStorage.setItem('$_key.server', record['server'] as String);
    await persistPairingToken(token);
    await clearPendingPairing();
    return true;
  }

  Future<void> migrateLegacyPairing() async =>
      throw UnsupportedError('Legacy migration is native-only');

  CryptoSyncService({required this.baseUrl, required this.nodeId}) {
    final uri = Uri.parse(serverScope);
    final page = Uri.parse(web.window.location.href);
    if (uri.origin != page.origin ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError('Browser sync requires same-origin trusted HTTPS');
    }
    _key =
        'avodah.pair.${uri.origin}${uri.path.replaceFirst(RegExp(r'/+$'), '')}';
  }

  String? get pairingToken =>
      _transientToken ?? web.window.localStorage.getItem('$_key.token');
  bool get isPaired => pairingToken?.isNotEmpty ?? false;
  void setPairingToken(String? token) => _transientToken = token;

  Future<void> loadPersistedState() async {
    pairingToken;
  }

  Future<void> persistPairingToken(String token) async {
    web.window.localStorage.setItem('$_key.token', token);
    if (web.window.localStorage.getItem('$_key.token') != token) {
      throw StateError('Credential storage failed');
    }
    _transientToken = null;
  }

  Future<void> clearPairingToken() async {
    _transientToken = null;
    await clearPendingPairing();
    web.window.localStorage.removeItem('$_key.token');
  }

  Future<void> storeServerPubKey(List<int> key) async =>
      web.window.localStorage.setItem('$_key.server', base64Encode(key));
  Future<List<int>?> getStoredServerPubKey() async {
    final value = web.window.localStorage.getItem('$_key.server');
    return value == null ? null : base64Decode(value);
  }

  String? checkPendingCertFingerprint() => null;
  Future<void> approveCert(String fingerprint) async => throw UnsupportedError(
    'Browser trust must be configured by the operator',
  );
  void rejectCert() {}
  void dispose() {}

  Future<WebSyncResponse> get(
    String path, {
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 10),
  }) => _send('GET', path, queryParams: queryParams).timeout(timeout);
  Future<WebSyncResponse> post(
    String path, {
    Map<String, String>? headers,
    String? body,
    Duration timeout = const Duration(seconds: 10),
  }) => _send('POST', path, headers: headers, body: body).timeout(timeout);
  Future<WebSyncResponse> delete(
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) => _send('DELETE', path, headers: headers).timeout(timeout);

  Future<WebSyncResponse> _send(
    String method,
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? body,
    String? tokenOverride,
  }) async {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/$path').replace(queryParameters: queryParams);
    if (uri.origin != Uri.parse(baseUrl).origin ||
        !uri.path.startsWith(
          '${Uri.parse(baseUrl).path.replaceFirst(RegExp(r'/+$'), '')}/api/',
        )) {
      throw StateError('Unsafe credential destination');
    }
    final h = web.Headers();
    headers?.forEach((name, value) => h.set(name, value));
    h.set('X-Av-Node-Id', nodeId);
    final token = tokenOverride ?? pairingToken;
    if (token != null) h.set('X-Av-Pair-Token', token);
    final response = await web.window
        .fetch(
          uri.toString().toJS,
          web.RequestInit(
            method: method,
            headers: h,
            redirect: 'error',
            credentials: 'omit',
            cache: 'no-store',
            body: body?.toJS,
          ),
        )
        .toDart;
    final buffer = await response.arrayBuffer().toDart;
    return WebSyncResponse(response.status, buffer.toDart.asUint8List());
  }
}

class WebSyncResponse extends Stream<List<int>> {
  final int statusCode;
  final List<int> bytes;
  WebSyncResponse(this.statusCode, this.bytes);
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}
