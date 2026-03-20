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
import 'dart:io';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

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

  // Initialize database and services (same pattern as server.dart)
  final db = openDatabase(paths.databasePath);
  final nodeId = paths.getNodeIdSync();
  final clock = HybridLogicalClock(nodeId: nodeId);

  // Jira service — only when JIRA_ENABLED=true
  JiraService? jiraService;
  if (jiraEnabled) {
    jiraService = JiraService(db: db, clock: clock, paths: paths);
  }

  // CRDT delta sync API service
  final syncApi = SyncApiService(
    db: db,
    clock: clock,
    jiraService: jiraService,
    config: config,
  );

  // Start HTTP server
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stderr.writeln('Avodah Sync Server listening on 0.0.0.0:$port');
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

  // Accept connections — handle each request concurrently
  await for (final request in server) {
    unawaited(_handleRequest(request, syncApi, agentApiUrl));
  }
}

Future<void> _handleRequest(
  HttpRequest request,
  SyncApiService syncApi,
  String agentApiUrl,
) async {
  try {
    // WebSocket upgrade requests → proxy to AGENT_API_URL
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      await _proxyWebSocket(request, agentApiUrl);
      return;
    }

    // Sync API handles its own paths (e.g. /sync/*)
    final syncHandled = await syncApi.handleRequest(request);
    if (syncHandled) return;

    // /api/* → proxy to AGENT_API_URL
    if (request.uri.path.startsWith('/api/')) {
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
