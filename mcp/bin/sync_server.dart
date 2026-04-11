#!/usr/bin/env dart

/// Avodah Sync Server — HTTP API server.
///
/// HTTP API: CRDT delta sync endpoints + reverse proxy for agent API.
///
/// Usage:
///   dart run mcp/bin/sync_server.dart [--port 9847]
///
/// Environment variables:
///   JIRA_ENABLED    Enable Jira sync (default: false)
///   AGENT_API_URL   Upstream agent API URL for /api/* and /ws proxy
///                   (default: http://localhost:9848)
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avodah_core/avodah_core.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/pairing_service.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

/// Server fingerprint computed from the TLS certificate (SHA-256, base64).
/// Set during TLS binding and used in the /api/sync/status response.
String? serverFingerprint;

Future<void> main(List<String> args) async {
  final paths = AvodahPaths();
  await paths.ensureDirectories();

  // Load config for defaults
  final config = await AvoConfig.load(paths);

  // Parse CLI args
  final parser = ArgParser()
    ..addOption('port',
        abbr: 'p',
        defaultsTo: config.syncPort.toString(),
        help: 'Port to listen on');

  final parsed = parser.parse(args);
  final port = int.parse(parsed['port'] as String);

  // JIRA_ENABLED toggle (default false)
  final jiraEnabled =
      (Platform.environment['JIRA_ENABLED'] ?? 'false').toLowerCase() == 'true';

  // Agent API proxy URL
  final agentApiUrl =
      Platform.environment['AGENT_API_URL'] ?? 'http://localhost:9848';

  // HTTPS-only mode: when true + TLS configured, reject plain HTTP requests
  final httpsOnly =
      Platform.environment['SYNC_HTTPS_ONLY']?.toLowerCase() == 'true';

  // Initialize database and services (same pattern as server.dart)
  final db = openDatabase(paths.databasePath);
  final nodeId = paths.getNodeIdSync();
  final clock = HybridLogicalClock(nodeId: nodeId);

  // Pairing service for secure sync device authentication
  final pairingService = PairingService(db: db);

  // Jira service — only when JIRA_ENABLED=true
  JiraService? jiraService;
  if (jiraEnabled) {
    jiraService = JiraService(db: db, clock: clock, paths: paths);
  }

  // CRDT delta sync API service (needs pairingService for auth middleware)
  final syncApi = SyncApiService(
    db: db,
    clock: clock,
    jiraService: jiraService,
    config: config,
    paths: paths,
    pairingService: pairingService,
  );

  // Start server(s): HTTPS on all interfaces + HTTP on localhost (when TLS enabled),
  // or HTTP only on localhost (when TLS disabled).
  // Each entry is (server, isSecure): isSecure=true for HTTPS, false for HTTP.
  final serverList = <(HttpServer, bool)>[];
  final tlsCertPath = config.syncTlsCertPath;
  final tlsKeyPath = config.syncTlsKeyPath;

  if (tlsCertPath != null && tlsKeyPath != null) {
    // TLS mode: load certificate and bind securely
    final certFile = File(tlsCertPath);
    final keyFile = File(tlsKeyPath);

    if (!await certFile.exists()) {
      stderr.writeln('ERROR: TLS certificate not found: $tlsCertPath');
      stderr.writeln('Please provide valid TLS cert and key files, or remove syncTls config.');
      exit(1);
    }
    if (!await keyFile.exists()) {
      stderr.writeln('ERROR: TLS key not found: $tlsKeyPath');
      stderr.writeln('Please provide valid TLS cert and key files, or remove syncTls config.');
      exit(1);
    }

    final context = SecurityContext();
    try {
      context.useCertificateChainBytes(await certFile.readAsBytes());
      context.usePrivateKeyBytes(await keyFile.readAsBytes());
    } catch (e) {
      stderr.writeln('ERROR: Failed to load TLS certificate/key: $e');
      exit(1);
    }

    // Compute server fingerprint from the certificate (SHA-256, base64)
    serverFingerprint = await _computeFingerprint(await certFile.readAsBytes());

    // HTTPS on all interfaces (TLS + auth required)
    final httpsServer = await HttpServer.bindSecure(
      InternetAddress.anyIPv4,
      port,
      context,
    );
    serverList.add((httpsServer, true)); // isSecure = true
    stderr.writeln('Avodah Sync Server (HTTPS/TLS) listening on 0.0.0.0:$port');
    stderr.writeln('TLS fingerprint: ${serverFingerprint ?? "unknown"}');

    // HTTP on localhost (for pa-serve proxy, no TLS needed)
    // Skip when HTTPS-only mode is enabled — TLS required, HTTP rejected
    if (!httpsOnly) {
      final localhostHttpServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      serverList.add((localhostHttpServer, false)); // isSecure = false
      stderr.writeln('Avodah Sync Server (HTTP/loopback) listening on 127.0.0.1:$port');
    } else {
      stderr.writeln('HTTPS-only mode: localhost HTTP binding skipped — HTTPS required');
    }
  } else {
    // Plain HTTP mode (no TLS — for development or local-only networks)
    final httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
    serverList.add((httpServer, false)); // isSecure = false
    stderr.writeln('Avodah Sync Server (HTTP) listening on 0.0.0.0:$port');
    stderr.writeln('WARNING: HTTP mode — sync traffic is NOT encrypted. Use TLS for production.');
  }

  stderr.writeln(
      'Agent API proxy → $agentApiUrl (Jira: ${jiraEnabled ? "enabled" : "disabled"})');

  // Handle SIGINT and SIGTERM for graceful shutdown
  Future<void> shutdown() async {
    stderr.writeln('\nShutting down...');
    for (final (s, _) in serverList) {
      await s.close();
    }
    await db.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => shutdown());
  ProcessSignal.sigterm.watch().listen((_) => shutdown());

  // Accept connections — handle each request concurrently across all servers
  for (final (server, isSecure) in serverList) {
    unawaited(server.forEach((request) =>
        _handleRequest(request, syncApi, pairingService, agentApiUrl, httpsOnly, isSecure)));
  }
}

/// Computes a SHA-256 fingerprint from a PEM-encoded certificate.
Future<String?> _computeFingerprint(List<int> certBytes) async {
  try {
    // Extract the certificate der bytes from PEM if needed
    String pem = String.fromCharCodes(certBytes);
    List<int> derBytes;

    if (pem.contains('-----BEGIN CERTIFICATE-----')) {
      // PEM format — extract first certificate only (chain may have multiple)
      final beginMarker = '-----BEGIN CERTIFICATE-----';
      final endMarker = '-----END CERTIFICATE-----';
      final start = pem.indexOf(beginMarker) + beginMarker.length;
      final end = pem.indexOf(endMarker);
      final base64Content = pem.substring(start, end).replaceAll(RegExp(r'\s'), '');
      derBytes = base64.decode(base64Content);
    } else {
      // Assume DER format
      derBytes = certBytes;
    }

    // SHA-256 hash and base64 encode
    final fingerprint = await _sha256(Uint8List.fromList(derBytes));
    return base64.encode(fingerprint);
  } catch (e) {
    stderr.writeln('Warning: could not compute TLS fingerprint: $e');
    return null;
  }
}

/// SHA-256 digest helper.
Future<Uint8List> _sha256(Uint8List data) async {
  final sha256 = crypto.Sha256();
  final digest = await sha256.hash(data);
  return Uint8List.fromList(digest.bytes);
}

Future<void> _handleRequest(
  HttpRequest request,
  SyncApiService syncApi,
  PairingService pairingService,
  String agentApiUrl,
  bool httpsOnly,
  bool isSecure,
) async {
  try {
    // HTTPS-only mode: reject plain HTTP requests when TLS is configured
    if (httpsOnly && !isSecure) {
      _jsonResponse(request, HttpStatus.forbidden, {
        'error': 'HTTP not allowed when TLS is configured. Use HTTPS.',
        'code': 'HTTPS_ONLY',
      });
      return;
    }

    // WebSocket upgrade requests → proxy to AGENT_API_URL (requires auth)
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final nodeId = request.headers.value('X-Av-Node-Id');
      final token = request.headers.value('X-Av-Pair-Token');
      if (nodeId == null || token == null ||
          !await pairingService.verifyPairToken(nodeId, token)) {
        _jsonResponse(request, HttpStatus.forbidden,
            {'error': 'Invalid or expired pairing token'});
        return;
      }
      await _proxyWebSocket(request, agentApiUrl);
      return;
    }

    final path = request.uri.path;

    // Pairing endpoints (before auth check — pairing doesn't require auth)
    if (path == '/api/sync/status') {
      await _handleSyncStatus(request, pairingService);
      return;
    }
    if (path == '/api/sync/pair/start' && request.method == 'POST') {
      await _handlePairStart(request, pairingService);
      return;
    }
    if (path == '/api/sync/pair/confirm' && request.method == 'POST') {
      await _handlePairConfirm(request, pairingService);
      return;
    }
    if (path == '/api/sync/pair' && request.method == 'DELETE') {
      await _handlePairRevoke(request, pairingService);
      return;
    }

    // Sync API handles its own paths (e.g. /api/sync/deltas)
    final syncHandled = await syncApi.handleRequest(request);
    if (syncHandled) return;

    // /api/* → proxy to AGENT_API_URL (requires valid pairing token)
    if (path.startsWith('/api/')) {
      // CORS preflight passes through without auth
      if (request.method == 'OPTIONS') {
        _setSyncCors(request);
        request.response
          ..statusCode = HttpStatus.ok
          ..close();
        return;
      }

      final nodeId = request.headers.value('X-Av-Node-Id');
      final token = request.headers.value('X-Av-Pair-Token');
      if (nodeId == null || token == null) {
        _jsonResponse(request, HttpStatus.forbidden,
            {'error': 'Missing X-Av-Node-Id or X-Av-Pair-Token header'});
        return;
      }
      final valid = await pairingService.verifyPairToken(nodeId, token);
      if (!valid) {
        _jsonResponse(request, HttpStatus.forbidden,
            {'error': 'Invalid or expired pairing token'});
        return;
      }

      await _proxyHttp(request, agentApiUrl);
      return;
    }

    // Health check fallback
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write('{"status":"ok","service":"avodah-sync"}')
      ..close();
  } catch (e, stack) {
    stderr.writeln('Unhandled request error: $e\n$stack');
  }
}

// ============================================================
// Pairing handlers
// ============================================================

/// GET /api/sync/status — Returns pairing status.
Future<void> _handleSyncStatus(
    HttpRequest request, PairingService pairingService) async {
  final paired = await pairingService.listPairedDevices();
  final pairedOrigin = paired.isNotEmpty ? paired.first.origin : null;
  _setSyncCors(request, pairedOrigin: pairedOrigin);
  if (request.method == 'OPTIONS') {
    request.response
      ..statusCode = HttpStatus.ok
      ..close();
    return;
  }

  final status = await pairingService.getStatus();
  // Include serverFingerprint if TLS is configured
  if (serverFingerprint != null) {
    status['serverFingerprint'] = serverFingerprint;
  }
  _jsonResponse(request, HttpStatus.ok, status);
}

/// POST /api/sync/pair/start — Initiates pairing handshake.
Future<void> _handlePairStart(
    HttpRequest request, PairingService pairingService) async {
  _setSyncCors(request);
  if (request.method == 'OPTIONS') {
    request.response
      ..statusCode = HttpStatus.ok
      ..close();
    return;
  }

  if (request.method != 'POST') {
    _jsonResponse(request, HttpStatus.methodNotAllowed,
        {'error': 'Method not allowed'});
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final nodeId = json['nodeId'] as String? ?? 'phone';

    final result = await pairingService.startPairing(nodeId);
    _jsonResponse(request, HttpStatus.ok, result);
  } catch (e) {
    stderr.writeln('Pair start error: $e');
    _jsonResponse(request, HttpStatus.internalServerError,
        {'error': 'Pairing start failed: $e'});
  }
}

/// POST /api/sync/pair/confirm — Completes pairing handshake.
Future<void> _handlePairConfirm(
    HttpRequest request, PairingService pairingService) async {
  _setSyncCors(request);
  if (request.method == 'OPTIONS') {
    request.response
      ..statusCode = HttpStatus.ok
      ..close();
    return;
  }

  if (request.method != 'POST') {
    _jsonResponse(request, HttpStatus.methodNotAllowed,
        {'error': 'Method not allowed'});
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final nodeId = json['nodeId'] as String? ?? 'phone';
    final phonePubKey = json['phonePubKey'] as String?;
    final hmacProof = json['hmacProof'] as String?;
    // Capture origin for CORS restriction (e.g. "https://100.64.0.1:9847")
    final origin = request.headers.value('origin');

    if (phonePubKey == null || hmacProof == null) {
      _jsonResponse(request, HttpStatus.badRequest,
          {'error': 'Missing phonePubKey or hmacProof'});
      return;
    }

    final result = await pairingService.confirmPairing(
      nodeId: nodeId,
      phonePubKeyBase64: phonePubKey,
      hmacProofBase64: hmacProof,
      origin: origin,
    );

    if (result['success'] == true) {
      _jsonResponse(request, HttpStatus.ok, result);
    } else {
      _jsonResponse(request, HttpStatus.forbidden, result);
    }
  } catch (e) {
    stderr.writeln('Pair confirm error: $e');
    _jsonResponse(request, HttpStatus.internalServerError,
        {'error': 'Pairing confirm failed: $e'});
  }
}

/// DELETE /api/sync/pair — Revokes pairing (authenticated via headers).
///
/// Requires X-Av-Pair-Token and X-Av-Node-Id headers.
/// Returns success even if already unpaired (idempotent).
Future<void> _handlePairRevoke(
    HttpRequest request, PairingService pairingService) async {
  _setSyncCors(request);
  if (request.method == 'OPTIONS') {
    request.response
      ..statusCode = HttpStatus.ok
      ..close();
    return;
  }

  if (request.method != 'DELETE') {
    _jsonResponse(request, HttpStatus.methodNotAllowed,
        {'error': 'Method not allowed'});
    return;
  }

  // Auth via headers
  final nodeId = request.headers.value('X-Av-Node-Id');
  final token = request.headers.value('X-Av-Pair-Token');

  if (nodeId == null || token == null) {
    _jsonResponse(request, HttpStatus.forbidden,
        {'error': 'Missing X-Av-Node-Id or X-Av-Pair-Token header'});
    return;
  }

  // Verify token before revoking (authenticated revocation)
  final valid = await pairingService.verifyPairToken(nodeId, token);
  if (!valid) {
    _jsonResponse(request, HttpStatus.forbidden,
        {'error': 'Invalid pairing token'});
    return;
  }

  try {
    await pairingService.revokePairing(nodeId);
    _jsonResponse(request, HttpStatus.ok, {'success': true});
  } catch (e) {
    stderr.writeln('Pair revoke error: $e');
    _jsonResponse(request, HttpStatus.internalServerError,
        {'error': 'Pairing revoke failed: $e'});
  }
}

/// Sets CORS headers for sync endpoints.
///
/// After pairing is established, restricts CORS to the paired device's origin.
void _setSyncCors(HttpRequest request, {String? pairedOrigin}) {
  final origin = request.headers.value('origin');
  final allowedOrigin = pairedOrigin ?? origin ?? '*';
  request.response.headers.add(
      'Access-Control-Allow-Origin', allowedOrigin == '*' ? '*' : allowedOrigin);
  request.response.headers
      .add('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  request.response.headers.add('Access-Control-Allow-Headers',
      'Content-Type, X-Av-Pair-Token, X-Av-Node-Id');
}

/// Sends a JSON response.
void _jsonResponse(
    HttpRequest request, int statusCode, Map<String, dynamic> body) {
  request.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}

/// Proxies an HTTP request to the upstream agent API.
Future<void> _proxyHttp(HttpRequest request, String agentApiUrl) async {
  final targetUri = Uri.parse('$agentApiUrl${request.uri}');
  final client = http.Client();
  try {
    final body = await request
        .fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
    final proxyRequest = http.Request(request.method, targetUri);
    request.headers.forEach((name, values) {
      if (!['host', 'transfer-encoding'].contains(name.toLowerCase())) {
        proxyRequest.headers[name] = values.join(', ');
      }
    });
    if (body.isNotEmpty) proxyRequest.bodyBytes = body;
    final streamedResponse =
        await client.send(proxyRequest).timeout(const Duration(seconds: 10));
    request.response.statusCode = streamedResponse.statusCode;
    streamedResponse.headers.forEach((name, value) {
      try {
        request.response.headers.set(name, value);
      } catch (_) {}
    });
    await streamedResponse.stream.pipe(request.response);
  } on Exception catch (e) {
    stderr.writeln('Agent API proxy error: $e');
    request.response
      ..statusCode = HttpStatus.badGateway
      ..headers.contentType = ContentType.json
      ..write('{"error":"Agent API unavailable","code":"BAD_GATEWAY"}');
    await request.response.close();
  } finally {
    client.close();
  }
}

/// Proxies a WebSocket upgrade request to the upstream agent API.
Future<void> _proxyWebSocket(HttpRequest request, String agentApiUrl) async {
  final wsUpstreamUrl = agentApiUrl
      .replaceFirst('http://', 'ws://')
      .replaceFirst('https://', 'wss://');
  final targetUri = Uri.parse('$wsUpstreamUrl${request.uri}');
  try {
    final clientWs = await WebSocket.connect(targetUri.toString());
    final serverWs = await WebSocketTransformer.upgrade(request);

    // Bidirectional pipe
    clientWs.listen(
      (data) {
        if (serverWs.readyState == WebSocket.open) serverWs.add(data);
      },
      onDone: () => serverWs.close(),
      onError: (e) => stderr.writeln('WS upstream error: $e'),
    );
    serverWs.listen(
      (data) {
        if (clientWs.readyState == WebSocket.open) clientWs.add(data);
      },
      onDone: () => clientWs.close(),
      onError: (e) => stderr.writeln('WS client error: $e'),
    );
  } catch (e) {
    stderr.writeln('WebSocket proxy error: $e');
    request.response.statusCode = HttpStatus.badGateway;
    await request.response.close();
  }
}
