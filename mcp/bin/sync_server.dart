#!/usr/bin/env dart

/// HTTP backend. TLS/prefix routing belongs to DFC-004, not this process.
library;

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/pairing_service.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/services/sync_http_handler.dart';
import 'package:avodah_mcp/storage/database_opener.dart';

Future<void> main(List<String> args) async {
  final paths = AvodahPaths();
  final config = await AvoConfig.load(paths);
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: config.syncPort.toString())
    ..addOption('host',
        abbr: 'h', defaultsTo: Platform.environment['SYNC_HOST'] ?? '127.0.0.1')
    ..addFlag('allow-nonloopback',
        defaultsTo: false,
        negatable: false,
        help: 'Explicit isolated-development network exposure opt-in');
  final parsed = parser.parse(args);
  final port = int.parse(parsed['port'] as String);
  final host = InternetAddress(parsed['host'] as String);
  if (port < 1 ||
      port > 65535 ||
      (!host.isLoopback && !(parsed['allow-nonloopback'] as bool))) {
    stderr.writeln(
        'Invalid listener: port 1..65535; loopback unless explicitly opted in');
    exitCode = 64;
    return;
  }
  await paths.ensureDirectories();
  final db = openDatabase(paths.databasePath);
  final clock = HybridLogicalClock(nodeId: paths.getNodeIdSync());
  final jiraEnabled = Platform.environment['JIRA_ENABLED'] == 'true';
  final jira = jiraEnabled && File(paths.jiraCredentialsPath).existsSync()
      ? JiraService(db: db, clock: clock, paths: paths)
      : null;
  final pairing = PairingService(db: db);
  final sync = SyncApiService(
      db: db,
      clock: clock,
      config: config,
      paths: paths,
      pairingService: pairing,
      jiraService: jira);
  // Preserve previous migrations; stable IDs make new migrations idempotent.
  final previousChips = await db.select(db.categoryChips).get();
  final chipsToMigrate = previousChips.any((r) => r.id.startsWith('migrated-'))
      ? <MapEntry<String, List<String>>>[]
      : config.categoryChips.entries;
  for (final entry in chipsToMigrate) {
    for (var i = 0; i < entry.value.length; i++) {
      final id = 'migrated-${entry.key}-${entry.value[i]}';
      if (await (db.select(db.categoryChips)..where((t) => t.id.equals(id)))
              .getSingleOrNull() !=
          null) continue;
      final doc = CategoryChipDocument(id: id, clock: clock)
        ..category = entry.key
        ..label = entry.value[i]
        ..sortOrder = i;
      await db
          .into(db.categoryChips)
          .insertOnConflictUpdate(doc.toDriftCompanion());
    }
  }
  final handler = SyncHttpHandler(
      sync: sync,
      pairing: pairing,
      agentApiUrl:
          Platform.environment['AGENT_API_URL'] ?? 'http://127.0.0.1:9848');
  final server = await HttpServer.bind(host, port,
      v6Only: host.type == InternetAddressType.IPv6);
  stderr.writeln('Avodah sync listening on ${host.address}:$port');
  if (jiraEnabled && jira == null)
    stderr.writeln('Jira configured but unavailable');
  sync.pullFromPhone().catchError((Object _) {
    stderr
        .writeln('Startup phone pull unavailable; core sync remains available');
  });
  Future<void> shutdown() async {
    await server.close(force: true);
    await db.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => shutdown());
  ProcessSignal.sigterm.watch().listen((_) => shutdown());
  server.listen(handler.call, onError: (Object _) {
    stderr.writeln('Sync listener error');
  }, cancelOnError: false);
}
