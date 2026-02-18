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
import 'package:avodah_core/avodah_core.dart' show HybridLogicalClock, avodahVersion;
import 'package:avodah_mcp/cli/commands.dart';
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/plan_service.dart';
import 'package:avodah_mcp/services/project_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';

Future<void> main(List<String> args) async {
  // Handle --version / -v before any initialization
  if (args.contains('--version') || args.contains('-v')) {
    print('avodah (עבודה) $avodahVersion');
    return;
  }

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
  final planService = PlanService(db: db, clock: clock);
  final jiraService = JiraService(db: db, clock: clock, paths: paths);
  final avoConfig = await AvoConfig.load(paths);

  try {
    final runner = CommandRunner<void>(
      'avo',
      'Avodah - Worklog tracking from the command line',
    )
      ..addCommand(StartCommand(timerService, taskService, worklogService,
          categories: avoConfig.effectiveCategories))
      ..addCommand(StopCommand(timerService, jiraService: jiraService, taskService: taskService))
      ..addCommand(StatusCommand(
        timerService: timerService,
        taskService: taskService,
        worklogService: worklogService,
        projectService: projectService,
        planService: planService,
        categories: avoConfig.effectiveCategories,
      ))
      ..addCommand(PauseCommand(timerService))
      ..addCommand(ResumeCommand(timerService))
      ..addCommand(CancelCommand(timerService))
      ..addCommand(TaskCommand(taskService, worklogService, projectService, jiraService))
      ..addCommand(ProjectCommand(projectService))
      ..addCommand(WorklogCommand(worklogService, taskService))
      ..addCommand(TodayCommand(
          worklogService: worklogService, taskService: taskService))
      ..addCommand(WeekCommand(worklogService: worklogService))
      ..addCommand(PlanCommand(planService,
          categories: avoConfig.effectiveCategories))
      ..addCommand(JiraCommand(jiraService, paths));

    // No args → run status + hint
    if (args.isEmpty) {
      await runner.run(['status']);
      print('');
      print('  -> avo --help              for all commands');
    }
    // `avo plan` with no subcommand → run plan list
    else if (args.length == 1 && args.first == 'plan') {
      await runner.run(['plan', 'list']);
    }
    // `avo jira` with no subcommand → run jira status + hint
    else if (args.length == 1 && args.first == 'jira') {
      await runner.run(['jira', 'status']);
      print('');
      print('  -> avo jira --help         for all subcommands');
    } else {
      await runner.run(args);
    }
  } on UsageException catch (e) {
    print(e);
    exit(64);
  } finally {
    jiraService.close();
    await db.close();
  }
}
