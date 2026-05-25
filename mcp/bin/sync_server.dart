#!/usr/bin/env dart

/// Avodah Sync Server — HTTP API server.
///
/// HTTP API: CRDT delta sync endpoints + reverse proxy for agent API.
/// Plain HTTP only — TLS is terminated by an upstream reverse proxy
/// (e.g. drgnfly-caddy at https://drgnfly/avodah).
///
/// Usage:
///   dart run mcp/bin/sync_server.dart [--port 9847] [--host 127.0.0.1]
///
/// Environment variables:
///   JIRA_ENABLED    Enable Jira sync (default: false)
///   AGENT_API_URL   Upstream agent API URL for /api/* and /ws proxy
///                   (default: http://localhost:9848)
///   SYNC_HOST       Default bind host (default: 0.0.0.0; use 127.0.0.1
///                   when behind an upstream reverse proxy)
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avodah_core/avodah_core.dart';
import 'package:uuid/uuid.dart';
import 'package:avodah_core/version.dart' as version;
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/pairing_service.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

/// Server start time for uptime calculation.
DateTime? startTime;

/// Last uncaught error message from runZonedGuarded.
String? lastError;

/// Migrates category chips from config.json to the category_chips table.
///
/// This is idempotent — it only runs if no migrated-* entries exist in the
/// table and config.categoryChips is non-empty.
Future<void> _migrateCategoryChipsFromConfig(
  AppDatabase db,
  HybridLogicalClock clock,
  AvoConfig config,
) async {
  // Idempotency check: skip if already migrated
  final allChips = await db.select(db.categoryChips).get();
  final migratedRows = allChips.where((c) => c.id.startsWith('migrated-')).toList();

  if (migratedRows.isNotEmpty) {
    stderr.writeln(
        'CategoryChip migration: skipped (${migratedRows.length} migrated entries exist)');
    return;
  }

  // Nothing to migrate?
  if (config.categoryChips.isEmpty) {
    stderr.writeln('CategoryChip migration: no chips in config, skipping');
    return;
  }

  // Migrate each chip from config.json
  int totalMigrated = 0;
  for (final MapEntry<String, List<String>> categoryEntry
      in config.categoryChips.entries) {
    final category = categoryEntry.key;
    final chips = categoryEntry.value;

    for (int i = 0; i < chips.length; i++) {
      final chipLabel = chips[i];

      // Create document with migrated-* ID for idempotency tracking
      final doc = CategoryChipDocument(
        id: 'migrated-${const Uuid().v4()}',
        clock: clock,
      );
      doc.category = category;
      doc.label = chipLabel;
      doc.sortOrder = i;

      await db
          .into(db.categoryChips)
          .insertOnConflictUpdate(doc.toDriftCompanion());
      totalMigrated++;
    }
  }

  stderr.writeln(
      'CategoryChip migration: migrated $totalMigrated chips from config.json');
}

Future<void> main(List<String> args) async {
  runZonedGuarded(() async {
    // Track server start time for uptime calculation
    startTime = DateTime.now();

    final paths = AvodahPaths();
    await paths.ensureDirectories();

  // Load config for defaults
  final config = await AvoConfig.load(paths);

  // Parse CLI args
  final parser = ArgParser()
    ..addOption('port',
        abbr: 'p',
        defaultsTo: config.syncPort.toString(),
        help: 'Port to listen on')
    ..addOption('host',
        abbr: 'h',
        defaultsTo: Platform.environment['SYNC_HOST'] ?? '0.0.0.0',
        help: 'Host to bind to (default: 0.0.0.0, use 127.0.0.1 for localhost-only)');

  final parsed = parser.parse(args);
  final port = int.parse(parsed['port'] as String);
  final bindHost = InternetAddress(parsed['host'] as String);

  // JIRA_ENABLED toggle (default false)
  final jiraEnabled =
      (Platform.environment['JIRA_ENABLED'] ?? 'false').toLowerCase() == 'true';

  // Agent API proxy URL
  final agentApiUrl =
      Platform.environment['AGENT_API_URL'] ?? 'http://localhost:9848';

  // Validate Jira credentials if JIRA is enabled
  if (jiraEnabled) {
    final jiraCredPath = paths.jiraCredentialsPath;
    if (!File(jiraCredPath).existsSync()) {
      stderr.writeln('WARNING: Jira credentials not found: $jiraCredPath');
      stderr.writeln('WARNING: Jira sync disabled — credentials required');
    }
  }

  stderr.writeln(
      'Config: port=$port, host=${bindHost.address}, Jira=${jiraEnabled ? "yes" : "no"}');

  // Initialize database and services (same pattern as server.dart)
  final db = openDatabase(paths.databasePath);
  final nodeId = paths.getNodeIdSync();
  final clock = HybridLogicalClock(nodeId: nodeId);

  // Phase 6: Migrate category chips from config.json to DB on first startup
  await _migrateCategoryChipsFromConfig(db, clock, config);

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

  // Pull deltas from paired phone devices on startup (non-blocking).
  syncApi.pullFromPhone().then((_) {
    final recon = syncApi.consumeReconciliationNotification();
    if (recon != null) {
      final stoppedAt =
          DateTime.fromMillisecondsSinceEpoch(recon.stoppedAtMs).toIso8601String();
      final worklogInfo = recon.worklogId != null
          ? ' — worklog ${recon.worklogId} created.'
          : '.';
      stdout.writeln(
          'Timer reconciled: stopped at $stoppedAt$worklogInfo');
    }
    syncApi.checkStaleTimer();
  }, onError: (Object e) {
    stderr.writeln('Phone pull on startup failed: $e');
    syncApi.checkStaleTimer();
  });

  // HTTP-only bind. TLS is terminated upstream by drgnfly-caddy.
  final server = await HttpServer.bind(bindHost, port);
  stderr.writeln(
      'Avodah Sync Server (HTTP) listening on ${bindHost.address}:$port');
  stderr.writeln(
      'Agent API proxy → $agentApiUrl (Jira: ${jiraEnabled ? "enabled" : "disabled"})');

  // Handle SIGINT and SIGTERM for graceful shutdown
  Future<void> shutdown() async {
    stderr.writeln('\nShutting down...');
    await server.close();
    await db.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => shutdown());
  ProcessSignal.sigterm.watch().listen((_) => shutdown());

  // Accept connections — handle each request concurrently.
  // Use listen() with cancelOnError:false so a single SocketException
  // doesn't kill the entire server loop.
  server.listen(
    (request) => _handleRequest(
        request, syncApi, pairingService, agentApiUrl, paths, port, jiraEnabled),
    onError: (Object error, StackTrace stack) {
      lastError = error.toString();
      stderr.writeln('Server socket error (continuing): $error');
    },
    cancelOnError: false,
  );
  }, (error, stack) {
    lastError = error.toString();
    stderr.writeln('Uncaught error (server continues): $error\n$stack');
  });
}

Future<void> _handleRequest(
  HttpRequest request,
  SyncApiService syncApi,
  PairingService pairingService,
  String agentApiUrl,
  AvodahPaths paths,
  int port,
  bool jiraEnabled,
) async {
  try {
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

    // Enhanced health check
    if (path == '/') {
      final uptime = startTime != null
          ? (DateTime.now().difference(startTime!).inSeconds)
          : 0;
      final jiraFileFound = File(paths.jiraCredentialsPath).existsSync();
      _jsonResponse(request, HttpStatus.ok, {
        'status': 'ok',
        'service': 'avodah-sync',
        'tls': false,
        'uptime': uptime,
        'port': port,
        'jira': {
          'enabled': jiraEnabled,
          'fileFound': jiraFileFound,
        },
        'lastError': lastError,
        'version': version.avodahVersion,
      });
      return;
    }
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
    // Capture origin for CORS restriction (e.g. "https://drgnfly.tail10c2c6.ts.net")
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
  try {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    request.response.close(); // Separate call so errors can be caught
  } catch (e) {
    stderr.writeln('Response write error (client likely disconnected): $e');
  }
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
