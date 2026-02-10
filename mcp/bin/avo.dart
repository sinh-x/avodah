#!/usr/bin/env dart

/// Avodah CLI - Worklog tracking from the command line.
///
/// Usage:
///   avo start [task]         Start timer
///   avo stop                  Stop timer and log time
///   avo status                Show timer status
///   avo pause                 Pause timer
///   avo resume                Resume timer
///   avo cancel                Cancel timer without logging
///
///   avo task add <title>      Create a task
///   avo task list             List tasks
///   avo task done <id>        Mark task done
///
///   avo today                 Today's summary
///   avo week                  This week's summary
///
///   avo jira sync             Sync with Jira
///   avo jira status           Show Jira sync status
///   avo jira setup            Configure Jira
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/cli/commands.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/project_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';

Future<void> main(List<String> args) async {
  // Initialize paths and database
  final paths = AvodahPaths();
  await paths.ensureDirectories();

  final db = openDatabase(paths.databasePath);

  // Initialize CRDT clock with persistent node ID
  final nodeId = paths.getNodeIdSync();
  final clock = HybridLogicalClock(nodeId: nodeId);

  // Create services
  final timerService = TimerService(db: db, clock: clock);
  final taskService = TaskService(db: db, clock: clock);
  final worklogService = WorklogService(db: db, clock: clock);
  final projectService = ProjectService(db: db, clock: clock);

  try {
    final runner = CommandRunner<void>(
      'avo',
      'Avodah - Worklog tracking from the command line',
    )
      ..addCommand(StartCommand(timerService))
      ..addCommand(StopCommand(timerService))
      ..addCommand(StatusCommand(timerService))
      ..addCommand(PauseCommand(timerService))
      ..addCommand(ResumeCommand(timerService))
      ..addCommand(CancelCommand(timerService))
      ..addCommand(TaskCommand(taskService))
      ..addCommand(ProjectCommand(projectService))
      ..addCommand(TodayCommand(
          worklogService: worklogService, taskService: taskService))
      ..addCommand(WeekCommand(worklogService: worklogService))
      ..addCommand(JiraCommand(db));

    await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(64);
  } finally {
    await db.close();
  }
}
