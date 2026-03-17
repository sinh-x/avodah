#!/usr/bin/env dart

/// Avodah Sync Server — HTTP API server.
///
/// HTTP API: CRDT delta sync endpoints + agent workflow endpoints.
///
/// Usage:
///   dart run mcp/bin/sync_server.dart [--port 9847]
library;

import 'dart:async';
import 'dart:io';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/agent_api_service.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:args/args.dart';

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

  // Initialize database and services (same pattern as server.dart)
  final db = openDatabase(paths.databasePath);
  final nodeId = paths.getNodeIdSync();
  final clock = HybridLogicalClock(nodeId: nodeId);

  // CRDT delta sync API service
  final syncApi = SyncApiService(
    db: db,
    clock: clock,
  );

  // Agent workflow API service
  final agentApi = AgentApiService();

  // Start HTTP server
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stderr.writeln('Avodah Sync Server listening on 0.0.0.0:$port');
  stderr.writeln('Agent API: http://0.0.0.0:$port/api/');

  // Handle shutdown
  late StreamSubscription<ProcessSignal> sigint;
  sigint = ProcessSignal.sigint.watch().listen((_) async {
    stderr.writeln('\nShutting down...');
    await server.close();
    await db.close();
    sigint.cancel();
    exit(0);
  });

  // Accept connections — try Sync API, Agent API, fall back to health check
  await for (final request in server) {
    final syncHandled = await syncApi.handleRequest(request);
    if (syncHandled) continue;
    final handled = await agentApi.handleRequest(request);
    if (!handled) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"status":"ok","service":"avodah-sync"}')
        ..close();
    }
  }
}
