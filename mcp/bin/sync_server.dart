#!/usr/bin/env dart

/// Avodah Sync Server — WebSocket + HTTP API server.
///
/// WebSocket: Sends periodic snapshots of today's plan data to connected clients.
/// HTTP API: Agent workflow endpoints (inbox review, deployments, team browsing).
///
/// Usage:
///   dart run mcp/bin/sync_server.dart [--port 9847] [--interval 30]
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/agent_api_service.dart';
import 'package:avodah_mcp/services/plan_service.dart';
import 'package:avodah_mcp/services/sync_snapshot_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
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
        help: 'Port to listen on')
    ..addOption('interval',
        abbr: 'i',
        defaultsTo: config.syncInterval.toString(),
        help: 'Snapshot push interval in seconds');

  final parsed = parser.parse(args);
  final port = int.parse(parsed['port'] as String);
  final interval = int.parse(parsed['interval'] as String);

  // Initialize database and services (same pattern as server.dart)
  final db = openDatabase(paths.databasePath);
  final nodeId = paths.getNodeIdSync();
  final clock = HybridLogicalClock(nodeId: nodeId);

  final timerService = TimerService(db: db, clock: clock);
  final taskService = TaskService(db: db, clock: clock);
  final worklogService = WorklogService(db: db, clock: clock);
  final planService = PlanService(db: db, clock: clock);

  final snapshotService = SyncSnapshotService(
    timerService: timerService,
    taskService: taskService,
    worklogService: worklogService,
    planService: planService,
  );

  // Agent workflow API service
  final agentApi = AgentApiService();

  // Track connected clients
  final clients = <WebSocket>[];

  // Start HTTP server with WebSocket upgrade
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stderr.writeln('Avodah Sync Server listening on 0.0.0.0:$port');
  stderr.writeln('Push interval: ${interval}s');
  stderr.writeln('Agent API: http://0.0.0.0:$port/api/');

  // Periodic snapshot push
  String? lastSnapshot;
  final timer = Timer.periodic(Duration(seconds: interval), (_) async {
    if (clients.isEmpty) return;
    try {
      final snapshot = await snapshotService.buildSnapshot();
      final json = jsonEncode(snapshot);
      if (json == lastSnapshot) return; // No change, skip
      lastSnapshot = json;
      _broadcast(clients, json);
    } catch (e) {
      stderr.writeln('Error building snapshot: $e');
    }
  });

  // Handle shutdown
  late StreamSubscription<ProcessSignal> sigint;
  sigint = ProcessSignal.sigint.watch().listen((_) async {
    stderr.writeln('\nShutting down...');
    timer.cancel();
    for (final ws in clients) {
      await ws.close();
    }
    await server.close();
    await db.close();
    sigint.cancel();
    exit(0);
  });

  // Accept connections
  await for (final request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final ws = await WebSocketTransformer.upgrade(request);
      clients.add(ws);
      stderr.writeln(
          'Client connected (${clients.length} active)');

      // Send immediate snapshot on connect
      try {
        final snapshot = await snapshotService.buildSnapshot();
        final json = jsonEncode(snapshot);
        ws.add(json);
        lastSnapshot = json;
      } catch (e) {
        stderr.writeln('Error sending initial snapshot: $e');
      }

      // Handle client disconnect
      ws.listen(
        (_) {}, // Ignore incoming messages (read-only)
        onDone: () {
          clients.remove(ws);
          stderr.writeln(
              'Client disconnected (${clients.length} active)');
        },
        onError: (e) {
          clients.remove(ws);
          stderr.writeln('Client error: $e');
        },
      );
    } else {
      // Non-WebSocket request — try Agent API, fall back to health check
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
}

void _broadcast(List<WebSocket> clients, String data) {
  final stale = <WebSocket>[];
  for (final ws in clients) {
    try {
      ws.add(data);
    } catch (_) {
      stale.add(ws);
    }
  }
  for (final ws in stale) {
    clients.remove(ws);
  }
}
