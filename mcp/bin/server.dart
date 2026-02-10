#!/usr/bin/env dart

/// Avodah MCP Server - Model Context Protocol server for Claude Code.
///
/// Exposes worklog tracking tools via MCP over stdio.
///
/// Tools:
///   timer(action, task?, taskId?)  - Start/stop/status timer
///   tasks(action, title?)          - List/add tasks
///   today()                        - Today's summary
///   jira(action)                   - Sync with Jira
library;

import 'dart:io';

import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:avodah_mcp/tools/mcp_server.dart';

Future<void> main(List<String> args) async {
  // Initialize paths and database
  final paths = AvodahPaths();
  await paths.ensureDirectories();

  final db = openDatabase(paths.databasePath);

  try {
    // Start MCP server over stdio
    final server = McpServer(db: db, paths: paths);
    await server.serve(stdin, stdout);
  } finally {
    await db.close();
  }
}
