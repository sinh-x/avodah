#!/usr/bin/env dart

/// Avodah MCP Server - Model Context Protocol server for Claude Code.
///
/// Exposes worklog tracking tools via MCP over stdio.
///
/// Tools:
///   timer(action, task?, taskId?)  - Start/stop/pause/resume/status timer
///   tasks(action, title?, id?)     - List/add/show/done tasks
///   today()                        - Today's summary
///   jira(action)                   - Sync with Jira
///
/// Resources:
///   avodah://status                - Current timer + today summary
library;

import 'dart:io';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/project_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:avodah_mcp/tools/mcp_server.dart';

Future<void> main(List<String> args) async {
  // Initialize paths and database
  final paths = AvodahPaths();
  await paths.ensureDirectories();

  final db = openDatabase(paths.databasePath);

  // Initialize CRDT clock with persistent node ID
  final nodeId = paths.getNodeIdSync();
  final clock = HybridLogicalClock(nodeId: nodeId);

  // Create services (same pattern as avo.dart)
  final timerService = TimerService(db: db, clock: clock);
  final taskService = TaskService(db: db, clock: clock);
  final worklogService = WorklogService(db: db, clock: clock);
  final projectService = ProjectService(db: db, clock: clock);
  final jiraService = JiraService(db: db, clock: clock, paths: paths);

  try {
    // Start MCP server over stdio
    final server = McpServer(
      timerService: timerService,
      taskService: taskService,
      worklogService: worklogService,
      projectService: projectService,
      jiraService: jiraService,
      paths: paths,
    );
    await server.serve(stdin, stdout);
  } finally {
    await db.close();
  }
}
