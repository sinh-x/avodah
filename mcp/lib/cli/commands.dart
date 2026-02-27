/// CLI commands for Avodah.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:avodah_core/avodah_core.dart';

import '../config/paths.dart';
import '../services/jira_service.dart';
import '../services/plan_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/timer_service.dart';
import '../services/worklog_service.dart';
import 'format.dart';
import 'interactive_picker.dart';
import 'readline.dart';

// ============================================================
// Timer Commands
// ============================================================

/// Base class for timer commands that need the TimerService.
abstract class TimerCommand extends Command<void> {
  final TimerService timerService;
  TimerCommand(this.timerService);
}

/// Start timer command.
class StartCommand extends TimerCommand {
  final TaskService taskService;
  final WorklogService worklogService;
  final List<String> categories;

  StartCommand(super.timerService, this.taskService, this.worklogService, {this.categories = const []}) {
    argParser.addOption('note', abbr: 'n', help: 'Note about current work');
  }

  @override
  String get name => 'start';

  @override
  String get description => 'Start timer on a task';

  @override
  String get invocation => 'avo start [task] [-n note]';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo start "Fix login bug"\n'
      '  avo start a1b2 -n "working on auth"\n'
      '  avo start                          # interactive task picker';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final input = args.isNotEmpty ? args.join(' ') : null;

    final note = argResults?['note'] as String?;

    String? taskId;
    String taskTitle;

    if (input == null) {
      // Interactive picker mode
      final tasks = await taskService.list();
      if (tasks.isEmpty) {
        print('No active tasks.');
        print('');
        print(hint('avo task add <title>', 'to create one'));
        return;
      }

      final timeByTask = await worklogService.timeByTask();
      final pickerItems = tasks.map((task) {
        final check = task.isDone ? 'x' : ' ';
        final id = task.id.substring(0, 8);
        final issueTag = task.issueId != null
            ? task.issueId!.padRight(10)
            : ''.padRight(10);
        final cat = task.category ?? '-';
        final due = task.dueDay ?? '-';
        final worked = timeByTask[task.id] ?? Duration.zero;
        final estimate = task.timeEstimate > 0
            ? Duration(milliseconds: task.timeEstimate)
            : null;
        final time = formatTimeWithEstimate(worked, estimate);
        final displayLine =
            '  [$check] $id  $issueTag  ${task.title}  {$cat}  [due: $due]  ($time)';
        final searchText =
            '${task.title} ${task.issueId ?? ''} ${task.id} ${task.category ?? ''}'.toLowerCase();
        return PickerItem<TaskDocument>(
          value: task,
          displayLine: displayLine,
          searchText: searchText,
        );
      }).toList();

      final picker = InteractivePicker<TaskDocument>(items: pickerItems);
      final selected = picker.pick();
      if (selected == null) {
        print('Cancelled.');
        return;
      }

      taskId = selected.id;
      taskTitle = selected.title;
    } else {
      taskTitle = input;
      // Try to resolve input as a task ID/prefix first
      try {
        final task = await taskService.show(input);
        taskId = task.id;
        taskTitle = task.title;
      } on TaskNotFoundException {
        // Not an ID — treat as title
      } on AmbiguousTaskIdException catch (e) {
        print('Multiple tasks match "$input":');
        for (final id in e.matchingIds) {
          print('  ${id.substring(0, 8)}');
        }
        print('');
        print(hintPlain('Use a longer prefix to be specific.'));
        return;
      }
    }

    // Prompt for category if the task doesn't have one (pre-start, for known tasks)
    if (taskId != null) {
      try {
        final task = await taskService.show(taskId);
        if (task.category == null) {
          await _promptCategory(task);
        }
      } catch (_) {
        // Task not found — skip category prompt
      }
    }

    try {
      final timer = await timerService.start(
        taskTitle: taskTitle,
        taskId: taskId,
        note: note,
      );

      // Prompt for category after start if task was just created (title-based start)
      if (taskId == null && timer.taskId != null) {
        try {
          final task = await taskService.show(timer.taskId!);
          if (task.category == null) {
            await _promptCategory(task);
          }
        } catch (_) {}
      }

      print('Timer started: "$taskTitle"');
      if (timer.taskId != null) {
        print(kvRow('Task:', timer.taskId!.substring(0, 8)));
        final task = await taskService.show(timer.taskId!);
        final worklogs = await worklogService.listForTask(timer.taskId!);
        final totalMs = worklogs.fold<int>(0, (sum, w) => sum + w.durationMs);
        final worked = Duration(milliseconds: totalMs);
        final estimate = task.timeEstimate > 0
            ? Duration(milliseconds: task.timeEstimate)
            : null;
        print(kvRow('Category:', task.category ?? '-'));
        print(kvRow('Due:', task.dueDay ?? '-'));
        print(kvRow('Time:', formatTimeWithEstimate(worked, estimate)));
      }
      print(kvRow('Started:', formatTime(timer.startedAt!)));
      if (note != null) print(kvRow('Note:', note));
      print('');
      print(hint('avo stop', 'to log your time'));
      print(hint('avo pause', 'to take a break'));
    } on TimerAlreadyRunningException catch (e) {
      print('Timer already running: "${e.timer.taskTitle}"');
      print(kvRow('Elapsed:', e.timer.elapsedFormatted));
      print('');
      print(hint('avo stop', 'to stop and log time'));
      print(hint('avo cancel', 'to discard and start fresh'));
    }
  }

  Future<void> _promptCategory(TaskDocument task) async {
    final cats = categories;
    print('Task "${task.title}" has no category.');
    if (cats.isNotEmpty) {
      print('  Categories:');
      for (var i = 0; i < cats.length; i++) {
        print('  ${i + 1}. ${cats[i]}');
      }
    }
    print('  s. Skip');
    final prompt = cats.isNotEmpty
        ? '  Pick (1-${cats.length}) or type custom: '
        : '  Enter category (or s to skip): ';
    stdout.write(prompt);
    final input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty || input.toLowerCase() == 's') return;

    final num = int.tryParse(input);
    final String category;
    if (num != null && num >= 1 && num <= cats.length) {
      category = cats[num - 1];
    } else {
      category = input;
    }

    await taskService.setCategory(task.id, category);
    print(kvRow('Category:', category));
  }
}

/// Stop timer command.
class StopCommand extends TimerCommand {
  final JiraService? jiraService;
  final TaskService? taskService;

  StopCommand(super.timerService, {this.jiraService, this.taskService}) {
    argParser.addOption('message', abbr: 'm', help: 'Worklog comment/description');
    argParser.addFlag('done', abbr: 'd', help: 'Mark task as done after stopping');
  }

  @override
  String get name => 'stop';

  @override
  String get description => 'Stop timer and log time';

  @override
  String get invocation => 'avo stop [-m comment] [-d]';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo stop\n'
      '  avo stop -m "finished auth flow"\n'
      '  avo stop -d                        # stop and mark task done\n'
      '\n'
      'Worklogs are auto-pushed to Jira if configured.';

  @override
  Future<void> run() async {
    try {
      final messageArg = argResults?['message'] as String?;

      // Resolve comment: -m flag > interactive prompt (if no timer note) > timer note
      String? comment;
      if (messageArg != null) {
        comment = messageArg;
      } else {
        final timer = await timerService.status();
        if (timer != null && timer.note == null) {
          stdout.write('Description (Enter to skip): ');
          final input = stdin.readLineSync()?.trim();
          if (input != null && input.isNotEmpty) {
            comment = input;
          }
        }
        // If timer has a note, leave comment null — stop() will use it
      }

      final result = await timerService.stop(comment: comment);
      print('Timer stopped: "${result.taskTitle}"');
      print(kvRow('Duration:', result.elapsedFormatted));
      print(kvRow('Worklog:', result.worklogId.substring(0, 8)));
      if (result.note != null) print(kvRow('Note:', result.note!));

      // Auto-push worklog to Jira if service is available
      if (jiraService != null) {
        final pushed = await jiraService!.pushWorklog(result.worklogId);
        if (pushed) {
          print(kvRow('Jira:', 'worklog synced'));
        }
      }

      // Mark task as done if --done flag is set
      final markDone = argResults?['done'] as bool? ?? false;
      if (markDone && result.taskId != null && taskService != null) {
        try {
          await taskService!.done(result.taskId!);
          print(kvRow('Task:', 'marked done'));
        } on TaskAlreadyDoneException {
          print(kvRow('Task:', 'already done'));
        }
      }

      print('');
      print(hint('avo today', 'to see today\'s total'));
      print(hint('avo start <task>', 'to start another timer'));
    } on NoTimerRunningException {
      print('No timer is running.');
      print('');
      print(hint('avo start <task>', 'to begin tracking'));
    }
  }
}

/// Timer status command — now a full dashboard.
class StatusCommand extends Command<void> {
  final TimerService timerService;
  final TaskService taskService;
  final WorklogService worklogService;
  final ProjectService projectService;
  final PlanService planService;
  final List<String> categories;

  StatusCommand({
    required this.timerService,
    required this.taskService,
    required this.worklogService,
    required this.projectService,
    required this.planService,
    this.categories = const [],
  });

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  String get name => 'status';

  @override
  String get description => 'Show dashboard with timer, today\'s summary, tasks, and plan';

  @override
  String get invocation => 'avo status';

  @override
  Future<void> run() async {
    // ── Timer ──
    print(sectionHeader('TIMER'));
    final timer = await timerService.status();
    if (timer == null) {
      print('  No timer running.');
      print(hint('avo start <task>', 'to begin tracking'));
    } else {
      final indicator = timer.isPaused ? '||' : '>>';
      print('  $indicator ${timer.isPaused ? "Paused" : "Running"}: "${timer.taskTitle}"');
      print(kvRow('Elapsed:', timer.elapsedFormatted));
      print(kvRow('Started:', formatTime(timer.startedAt!)));
      if (timer.note != null) print(kvRow('Note:', timer.note!));
    }
    print(separator());
    print('');

    // ── Today ──
    print(sectionHeader('TODAY'));
    final summary = await worklogService.todaySummary();
    final now = DateTime.now();
    final dateStr = formatDate(now);
    print('  $dateStr${' ' * (lineWidth - dateStr.length - summary.formattedDuration.length - 4)}${summary.formattedDuration}');

    if (summary.tasks.isEmpty) {
      print('  No time logged yet.');
    } else {
      for (final task in summary.tasks) {
        final title = await resolveTaskTitle(taskService, task.taskId);
        final dur = task.formattedDuration;
        final padLen = lineWidth - title.length - dur.length - 4;
        final padding = padLen > 0 ? ' ' * padLen : ' ';
        print('  $title$padding$dur');
      }
    }
    print(separator());
    print('');

    // ── Plan ──
    final today = _today();
    final planSummary = await planService.summary();
    final plannedTasks = await planService.listTasksForDay(day: today);
    print(sectionHeader('PLAN'));
    await printPlanTable(planSummary,
        defaultCategories: categories,
        plannedTasks: plannedTasks,
        taskService: taskService,
        worklogService: worklogService);
    print(separator());
    print('');

    // ── Tasks ──
    print(sectionHeader('TASKS'));
    final tasks = await taskService.list();
    if (tasks.isEmpty) {
      print('  No active tasks.');
      print(hint('avo task add <title>', 'to create one'));
    } else {
      final timeByTask = await worklogService.timeByTask();
      print('  ${tasks.length} active task${tasks.length == 1 ? '' : 's'}');
      final showTasks = tasks.take(5).toList();
      for (final task in showTasks) {
        final check = task.isDone ? 'x' : ' ';
        final id = task.id.substring(0, 8);
        final worked = timeByTask[task.id] ?? Duration.zero;
        final estimate = task.timeEstimate > 0
            ? Duration(milliseconds: task.timeEstimate)
            : null;
        final time = formatTimeWithEstimate(worked, estimate);
        final issueTag = task.issueId != null ? ' [${task.issueId}]' : '';
        print('  [$check] $id  ${task.title}$issueTag  ($time)');
      }
      if (tasks.length > 5) {
        print(hint('avo task list', 'to see all ${tasks.length} tasks'));
      }

      // Overdue
      final overdueTasks = tasks.where((t) => t.isOverdue).toList();
      if (overdueTasks.isNotEmpty) {
        print('');
        print('  ${overdueTasks.length} overdue:');
        for (final t in overdueTasks.take(3)) {
          print('  ! ${t.id.substring(0, 8)}  ${t.title}  [due: ${t.dueDay}]');
        }
        if (overdueTasks.length > 3) {
          print('  ... and ${overdueTasks.length - 3} more');
        }
      }
    }
    print(separator());
  }
}

/// Pause timer command.
class PauseCommand extends TimerCommand {
  PauseCommand(super.timerService);

  @override
  String get name => 'pause';

  @override
  String get description => 'Pause running timer';

  @override
  String get invocation => 'avo pause';

  @override
  String? get usageFooter => '\nUse "avo resume" to continue or "avo stop" to log time.';

  @override
  Future<void> run() async {
    try {
      final timer = await timerService.pause();
      print('Timer paused: "${timer.taskTitle}"');
      print(kvRow('Elapsed:', timer.elapsedFormatted));
      print('');
      print(hint('avo resume', 'to continue'));
      print(hint('avo stop', 'to log what you have'));
    } on NoTimerRunningException {
      print('No timer is running.');
      print('');
      print(hint('avo start <task>', 'to begin tracking'));
    } on TimerAlreadyPausedException {
      print('Timer is already paused.');
      print('');
      print(hint('avo resume', 'to continue'));
      print(hint('avo stop', 'to log what you have'));
    }
  }
}

/// Resume timer command.
class ResumeCommand extends TimerCommand {
  ResumeCommand(super.timerService);

  @override
  String get name => 'resume';

  @override
  String get description => 'Resume paused timer';

  @override
  String get invocation => 'avo resume';

  @override
  String? get usageFooter => '\nResumes a previously paused timer. Use "avo stop" when done.';

  @override
  Future<void> run() async {
    try {
      final timer = await timerService.resume();
      print('Timer resumed: "${timer.taskTitle}"');
      print(kvRow('Elapsed:', timer.elapsedFormatted));
      print('');
      print(hint('avo stop', 'when done'));
    } on NoTimerRunningException {
      print('No timer is running.');
      print('');
      print(hint('avo start <task>', 'to begin tracking'));
    } on TimerNotPausedException {
      print('Timer is not paused -- it\'s already running.');
    }
  }
}

/// Cancel timer command.
class CancelCommand extends TimerCommand {
  CancelCommand(super.timerService);

  @override
  String get name => 'cancel';

  @override
  String get description => 'Cancel timer without logging';

  @override
  String get invocation => 'avo cancel';

  @override
  String? get usageFooter => '\nDiscards the running timer. No time is logged.';

  @override
  Future<void> run() async {
    try {
      await timerService.cancel();
      print('Timer cancelled. No time was logged.');
      print('');
      print(hint('avo start <task>', 'to begin a new timer'));
    } on NoTimerRunningException {
      print('No timer is running.');
    }
  }
}

// ============================================================
// Task Commands
// ============================================================

/// Base class for task commands that need the TaskService.
abstract class TaskSubcommand extends Command<void> {
  final TaskService taskService;
  TaskSubcommand(this.taskService);
}

/// Task management command group.
class TaskCommand extends Command<void> {
  TaskCommand(TaskService taskService, WorklogService worklogService,
      ProjectService projectService, JiraService jiraService) {
    addSubcommand(TaskAddCommand(taskService));
    addSubcommand(TaskListCommand(taskService, worklogService, projectService, jiraService));
    addSubcommand(TaskDoneCommand(taskService));
    addSubcommand(TaskUndoneCommand(taskService));
    addSubcommand(TaskShowCommand(taskService, worklogService, projectService));
    addSubcommand(TaskDeleteCommand(taskService, worklogService));
    addSubcommand(TaskUndeleteCommand(taskService));
    addSubcommand(TaskDueCommand(taskService));
    addSubcommand(TaskCatCommand(taskService));
  }

  @override
  String get name => 'task';

  @override
  String get description =>
      'Task management (add, list, show, done, undone, delete, undelete, due, cat)';
}

class TaskAddCommand extends TaskSubcommand {
  TaskAddCommand(super.taskService) {
    argParser.addOption('project', abbr: 'p', help: 'Project ID');
    argParser.addOption('due', help: 'Due date (YYYY-MM-DD)');
    argParser.addOption('cat', help: 'Category (e.g. Working, Learning)');
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Create a new task';

  @override
  String get invocation => 'avo task add <title> [-p project] [--due YYYY-MM-DD] [--cat category]';

  @override
  String? get usageFooter => '\nExample:\n'
      '  avo task add "Fix login bug" -p a1b2 --due 2026-03-01 --cat Working';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final title = args.isNotEmpty ? args.join(' ') : null;

    if (title == null) {
      print('Missing task title.');
      print('');
      print('  Usage: avo task add <title> [-p project] [--due YYYY-MM-DD] [--cat category]');
      print('  Example: avo task add "Fix login bug" -p a1b2 --due 2026-03-01 --cat Working');
      return;
    }

    final projectId = argResults?['project'] as String?;
    final dueDay = argResults?['due'] as String?;
    final category = argResults?['cat'] as String?;

    if (dueDay != null && !isValidDate(dueDay)) {
      print('Invalid date: "$dueDay". Use YYYY-MM-DD format.');
      return;
    }

    final task = await taskService.add(
      title: title,
      projectId: projectId,
      dueDay: dueDay,
      category: category,
    );
    final shortId = task.id.substring(0, 8);
    print('Created task: "$title"');
    print(kvRow('ID:', shortId));
    if (dueDay != null) print(kvRow('Due:', dueDay));
    if (category != null) print(kvRow('Category:', category));
    print('');
    print(hint('avo start $title', 'to start timing'));
    print(hint('avo task show $shortId', 'to see details'));
  }
}

class TaskListCommand extends TaskSubcommand {
  final WorklogService worklogService;
  final ProjectService projectService;
  final JiraService jiraService;

  TaskListCommand(super.taskService, this.worklogService,
      this.projectService, this.jiraService) {
    argParser.addFlag('all', abbr: 'a', help: 'Include completed tasks');
    argParser.addFlag('deleted', help: 'Show only soft-deleted tasks');
    argParser.addFlag('local', abbr: 'l',
        help: 'Show only local tasks (no external link)');
    argParser.addOption('source', abbr: 's',
        help: 'Filter by integration source (jira, github)',
        allowed: ['jira', 'github']);
    argParser.addOption('project', abbr: 'p',
        help: 'Filter by project (Jira key with -s jira, local project otherwise)');
    argParser.addOption('profile',
        help: 'Filter by Jira profile name (e.g. work, personal)');
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List tasks';

  @override
  String get invocation => 'avo task list [flags]';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo task list                      # active tasks\n'
      '  avo task list -a                   # include completed\n'
      '  avo task list -s jira              # Jira-linked tasks only\n'
      '  avo task list -s jira -p PROJ      # Jira project PROJ\n'
      '  avo task list -l                   # local tasks only\n'
      '  avo task list --profile work       # tasks from Jira profile "work"\n'
      '  avo task list -p myproject         # tasks in local project';

  @override
  Future<void> run() async {
    final includeCompleted = argResults?['all'] as bool? ?? false;
    final showDeleted = argResults?['deleted'] as bool? ?? false;
    final localOnly = argResults?['local'] as bool? ?? false;
    final source = argResults?['source'] as String?;
    final project = argResults?['project'] as String?;
    final profile = argResults?['profile'] as String?;

    if (showDeleted) {
      final deleted = await taskService.listDeleted();
      if (deleted.isEmpty) {
        print('No deleted tasks.');
        return;
      }
      print('Deleted Tasks (${deleted.length}):');
      for (final task in deleted) {
        final id = task.id.substring(0, 8);
        final doneTag = task.isDone ? ' [done]' : '';
        print('  $id  ${task.title}$doneTag');
      }
      print('');
      print(hint('avo task undelete <id>', 'to restore a task'));
      return;
    }

    var tasks = await taskService.list(includeCompleted: includeCompleted);

    // Apply filters (use issueId directly — hasIssueLink requires issueProviderId too)
    if (localOnly) {
      tasks = tasks.where((t) => t.issueId == null).toList();
    } else if (source != null) {
      final type = IssueType.fromValue(source);
      tasks = tasks.where((t) => t.issueType == type).toList();
    }
    // --project: with --source jira → filter by Jira project key prefix;
    //            without --source → filter by local projectId
    if (project != null) {
      if (source == 'jira') {
        final key = project.toUpperCase();
        tasks = tasks.where((t) {
          if (t.issueId == null) return false;
          return t.issueId!.toUpperCase().startsWith('$key-');
        }).toList();
      } else if (source == null) {
        // Match local project by ID prefix or title
        final projects = await projectService.list();
        final match = projects.where((p) =>
            p.id.startsWith(project) ||
            p.title.toLowerCase() == project.toLowerCase()).toList();
        if (match.isEmpty) {
          print('Project "$project" not found.');
          print(hint('avo project list', 'to see available projects'));
          return;
        }
        final projectIds = match.map((p) => p.id).toSet();
        tasks = tasks.where((t) => projectIds.contains(t.projectId)).toList();
      }
    }
    if (profile != null) {
      // Look up project keys for this profile name
      final config = await jiraService.getConfig(profileName: profile);
      if (config == null) {
        print('Jira profile "$profile" not found.');
        print(hint('avo jira status', 'to see configured profiles'));
        return;
      }
      final projectKeys = config.jiraProjectKey
          .split(',')
          .map((k) => k.trim().toUpperCase())
          .where((k) => k.isNotEmpty)
          .toList();
      tasks = tasks.where((t) {
        if (t.issueId == null) return false;
        final id = t.issueId!.toUpperCase();
        return projectKeys.any((key) => id.startsWith('$key-'));
      }).toList();
    }

    if (tasks.isEmpty) {
      final filterDesc = localOnly
          ? 'local '
          : source != null
              ? '$source '
              : '';
      print(includeCompleted
          ? 'No ${filterDesc}tasks.'
          : 'No active ${filterDesc}tasks.');
      print('');
      if (!includeCompleted) {
        print(hint('avo task add <title>', 'to create one'));
        print(hint('avo task list -a', 'to see completed tasks'));
      }
      return;
    }

    final timeByTask = await worklogService.timeByTask();
    final projectLabel = project != null ? ' ($project)' : '';
    final filterLabel = localOnly
        ? 'Local'
        : source != null
            ? '${source[0].toUpperCase()}${source.substring(1)}$projectLabel'
            : profile != null
                ? 'Profile: $profile'
                : project != null
                    ? 'Project: $project'
                    : includeCompleted
                        ? 'All'
                        : 'Active';
    print('$filterLabel Tasks (${tasks.length}):');
    for (final task in tasks) {
      final check = task.isDone ? 'x' : ' ';
      final id = task.id.substring(0, 8);
      final worked = timeByTask[task.id] ?? Duration.zero;
      final estimate = task.timeEstimate > 0
          ? Duration(milliseconds: task.timeEstimate)
          : null;
      final time = formatTimeWithEstimate(worked, estimate);
      final issueTag = task.issueId != null ? ' [${task.issueId}]' : '';
      final catTag = task.category != null ? ' {${task.category}}' : '';
      final dueTag = task.dueDay != null
          ? (task.isOverdue ? ' [OVERDUE: ${task.dueDay}]' : ' [due: ${task.dueDay}]')
          : '';
      print('  [$check] $id  ${task.title}$issueTag$catTag$dueTag  ($time)');
    }
    print('');
    print(hint('avo task show <id>', 'to see details'));
    print(hint('avo start <task>', 'to start timing'));
  }
}

class TaskDoneCommand extends TaskSubcommand {
  TaskDoneCommand(super.taskService);

  @override
  String get name => 'done';

  @override
  String get description => 'Mark task as done';

  @override
  String get invocation => 'avo task done <id>';

  @override
  String? get usageFooter => '\nID can be a prefix (e.g. "a1b2" matches "a1b2c3d4...").';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskId = args.isNotEmpty ? args.first : null;

    if (taskId == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo task done <id>');
      print(hint('avo task list', 'to see task IDs'));
      return;
    }

    try {
      final task = await taskService.done(taskId);
      final time = formatDuration(Duration(milliseconds: task.timeSpent));
      final issueTag = task.issueId != null ? ' [${task.issueId}]' : '';
      print('Marked done: "${task.title}"$issueTag');
      print(kvRow('ID:', task.id.substring(0, 8)));
      print(kvRow('Time spent:', time));
    } on TaskNotFoundException {
      print('No task found matching "$taskId".');
      print('');
      print(hint('avo task list', 'to see available tasks'));
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    } on TaskAlreadyDoneException catch (e) {
      print('Task "${e.task.title}" is already done.');
      print('');
      print(hint('avo task list', 'to see active tasks'));
    }
  }
}

class TaskUndoneCommand extends TaskSubcommand {
  TaskUndoneCommand(super.taskService);

  @override
  String get name => 'undone';

  @override
  String get description => 'Mark a done task as not done';

  @override
  String get invocation => 'avo task undone <id>';

  @override
  String? get usageFooter => '\nReverses "avo task done". '
      'ID can be a prefix (e.g. "a1b2" matches "a1b2c3d4...").';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskId = args.isNotEmpty ? args.first : null;

    if (taskId == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo task undone <id>');
      print(hint('avo task list -a', 'to see completed tasks'));
      return;
    }

    try {
      final task = await taskService.undone(taskId);
      print('Marked active: "${task.title}"');
      print(kvRow('ID:', task.id.substring(0, 8)));
    } on TaskNotFoundException {
      print('No task found matching "$taskId".');
      print('');
      print(hint('avo task list -a', 'to see all tasks'));
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    } on TaskNotDoneException catch (e) {
      print('Task "${e.task.title}" is not done.');
      print('');
      print(hint('avo task done ${taskId}', 'to mark it done first'));
    }
  }
}

class TaskUndeleteCommand extends TaskSubcommand {
  TaskUndeleteCommand(super.taskService);

  @override
  String get name => 'undelete';

  @override
  String get description => 'Restore a deleted task';

  @override
  String get invocation => 'avo task undelete <id>';

  @override
  String? get usageFooter => '\nRestores a soft-deleted task.\n'
      'Use "avo task list --deleted" to find deleted task IDs.';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskId = args.isNotEmpty ? args.first : null;

    if (taskId == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo task undelete <id>');
      print(hint('avo task list --deleted', 'to see deleted tasks'));
      return;
    }

    try {
      final task = await taskService.undelete(taskId);
      print('Restored: "${task.title}"');
      print(kvRow('ID:', task.id.substring(0, 8)));
    } on TaskNotFoundException {
      print('No task found matching "$taskId".');
      print('');
      print(hint('avo task list --deleted', 'to see deleted tasks'));
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    } on TaskNotDeletedException catch (e) {
      print('Task "${e.task.title}" is not deleted.');
    }
  }
}

class TaskDeleteCommand extends TaskSubcommand {
  final WorklogService worklogService;

  TaskDeleteCommand(super.taskService, this.worklogService) {
    argParser.addFlag('force', abbr: 'f',
        help: 'Skip worklog check and confirmation');
  }

  @override
  String get name => 'delete';

  @override
  String get description => 'Delete a task';

  @override
  String get invocation => 'avo task delete <id> [-f]';

  @override
  String? get usageFooter => '\nPrompts for confirmation before deleting.\n'
      'Warns if the task has logged worklogs.\n'
      'Use --force to skip all checks.';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskId = args.isNotEmpty ? args.first : null;
    final force = argResults?['force'] as bool? ?? false;

    if (taskId == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo task delete <id> [-f]');
      print(hint('avo task list', 'to see task IDs'));
      return;
    }

    try {
      final task = await taskService.show(taskId);

      if (!force) {
        // Check for worklogs
        final info = await worklogService.worklogInfoForTask(task.id);
        if (info.count > 0) {
          final dur = _formatDur(info.total);
          print(
              'Warning: This task has $dur logged across ${info.count} worklog(s).');
        }

        stdout.write(
            'Delete "${task.title}" (${task.id.substring(0, 8)})? [y/N] ');
        final input = stdin.readLineSync()?.trim().toLowerCase() ?? 'n';
        if (input != 'y') {
          print('Cancelled.');
          return;
        }
      }

      await taskService.delete(taskId);
      print('Deleted: "${task.title}"');
      print('');
      print(hint('avo task undelete ${task.id.substring(0, 8)}', 'to undo'));
    } on TaskNotFoundException {
      print('No task found matching "$taskId".');
      print('');
      print(hint('avo task list', 'to see available tasks'));
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    }
  }

  static String _formatDur(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class TaskDueCommand extends TaskSubcommand {
  TaskDueCommand(super.taskService);

  @override
  String get name => 'due';

  @override
  String get description => 'Set or clear due date on a task';

  @override
  String get invocation => 'avo task due <id> <YYYY-MM-DD|clear>';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo task due a1b2 2026-03-01       # set due date\n'
      '  avo task due a1b2 clear            # remove due date';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo task due <id> <YYYY-MM-DD|clear>');
      print(hint('avo task list', 'to see task IDs'));
      return;
    }

    final taskId = args.first;
    final dateArg = args.length > 1 ? args[1] : null;

    if (dateArg == null) {
      print('Missing date. Use YYYY-MM-DD or "clear".');
      print('');
      print('  Usage: avo task due <id> <YYYY-MM-DD|clear>');
      return;
    }

    final String? dueDay;
    if (dateArg.toLowerCase() == 'clear') {
      dueDay = null;
    } else if (isValidDate(dateArg)) {
      dueDay = dateArg;
    } else {
      print('Invalid date: "$dateArg". Use YYYY-MM-DD or "clear".');
      return;
    }

    try {
      final task = await taskService.setDue(taskId, dueDay);
      if (dueDay != null) {
        print('Set due date on "${task.title}": $dueDay');
      } else {
        print('Cleared due date on "${task.title}".');
      }
    } on TaskNotFoundException {
      print('No task found matching "$taskId".');
      print('');
      print(hint('avo task list', 'to see available tasks'));
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    }
  }
}

class TaskCatCommand extends TaskSubcommand {
  TaskCatCommand(super.taskService);

  @override
  String get name => 'cat';

  @override
  String get description => 'Set or clear category on a task';

  @override
  String get invocation => 'avo task cat <id> <category|clear>';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo task cat a1b2 Working\n'
      '  avo task cat a1b2 clear\n'
      '\n'
      'Common categories: Working, Learning, Side-project, Family & Friends, Personal';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo task cat <id> <category|clear>');
      print(hint('avo task list', 'to see task IDs'));
      return;
    }

    final taskId = args.first;
    final catArg = args.length > 1 ? args.sublist(1).join(' ') : null;

    if (catArg == null) {
      print('Missing category. Use a name or "clear".');
      print('');
      print('  Usage: avo task cat <id> <category|clear>');
      print('  Categories: Learning, Working, Side-project, Family & Friends, Personal');
      return;
    }

    final String? category;
    if (catArg.toLowerCase() == 'clear') {
      category = null;
    } else {
      category = catArg;
    }

    try {
      final task = await taskService.setCategory(taskId, category);
      if (category != null) {
        print('Set category on "${task.title}": $category');
      } else {
        print('Cleared category on "${task.title}".');
      }
    } on TaskNotFoundException {
      print('No task found matching "$taskId".');
      print('');
      print(hint('avo task list', 'to see available tasks'));
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    }
  }
}

class TaskShowCommand extends TaskSubcommand {
  final WorklogService worklogService;
  final ProjectService projectService;

  TaskShowCommand(super.taskService, this.worklogService, this.projectService);

  @override
  String get name => 'show';

  @override
  String get description => 'Show task details';

  @override
  String get invocation => 'avo task show <id>';

  @override
  String? get usageFooter => '\nID can be a prefix (e.g. "a1b2" matches "a1b2c3d4...").\n'
      'Shows status, project, category, time, worklogs, Jira sync info.';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskId = args.isNotEmpty ? args.first : null;

    if (taskId == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo task show <id>');
      print(hint('avo task list', 'to see task IDs'));
      return;
    }

    try {
      final task = await taskService.show(taskId);
      final status =
          task.isDone ? 'Done' : (task.isDeleted ? 'Deleted' : 'Active');
      final timeByTask = await worklogService.timeByTask();
      final worked = timeByTask[task.id] ?? Duration.zero;
      final estimate = task.timeEstimate > 0
          ? Duration(milliseconds: task.timeEstimate)
          : null;

      // Resolve project name
      String? projectName;
      if (task.projectId != null) {
        try {
          final project = await projectService.show(task.projectId!);
          projectName = project.title;
        } catch (_) {
          projectName = task.projectId;
        }
      }

      // Count worklogs for this task
      final allWorklogs = await worklogService.listForTask(task.id);

      print('Task: "${task.title}"');
      print(kvRow('ID:', task.id));
      if (task.issueId != null && task.issueStatus != null) {
        print(kvRow('Status:', '$status (Jira: ${task.issueStatus})'));
      } else {
        print(kvRow('Status:', status));
      }
      print(kvRow('Project:', projectName ?? '-'));
      print(kvRow('Category:', task.category ?? '-'));
      if (task.description != null) {
        print(kvRow('Description:', task.description!));
      }
      // Use Jira created time for linked tasks, fall back to local
      final created = (task.issueId != null ? task.issueCreated : null)
          ?? task.createdTimestamp;
      print(kvRow('Created:', created != null
          ? formatRelativeDate(created)
          : '-'));
      print(kvRow('Time:', formatTimeWithEstimate(worked, estimate)));
      print(kvRow('Worklogs:', '${allWorklogs.length} entries'));
      final dueDisplay = task.dueDay != null
          ? (task.isOverdue ? '${task.dueDay} (OVERDUE)' : task.dueDay!)
          : '-';
      print(kvRow('Due:', dueDisplay));
      if (task.doneOn != null) {
        print(kvRow('Done on:', formatRelativeDate(task.doneOn!)));
      }
      if (task.tagIds.isNotEmpty) {
        print(kvRow('Tags:', task.tagIds.join(', ')));
      }
      if (task.issueId != null) {
        print(kvRow('Issue:', task.issueId!));
        final syncStatus = task.issueLastUpdated != null
            ? 'synced ${formatRelativeDate(task.issueLastUpdated!)}'
            : 'never synced';
        print(kvRow('Jira sync:', syncStatus));
      }
      if (!task.isDone) {
        print('');
        print(hint('avo start ${task.id.substring(0, 8)}', 'to start timing'));
        print(hint('avo task done ${task.id.substring(0, 8)}', 'to mark done'));
      }
    } on TaskNotFoundException {
      print('No task found matching "$taskId".');
      print('');
      print(hint('avo task list', 'to see available tasks'));
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    }
  }
}

// ============================================================
// Worklog Commands
// ============================================================

/// Today summary command.
class TodayCommand extends Command<void> {
  final WorklogService worklogService;
  final TaskService taskService;

  TodayCommand({required this.worklogService, required this.taskService});

  @override
  String get name => 'today';

  @override
  String get description => "Today's work summary";

  @override
  String get invocation => 'avo today';

  @override
  Future<void> run() async {
    final summary = await worklogService.todaySummary();
    final now = DateTime.now();
    final dateStr = formatDate(now);

    print('Today ($dateStr):${' ' * 6}${summary.formattedDuration}');
    print(separator());

    if (summary.tasks.isEmpty) {
      print('  No time logged yet.');
      print('');
      print(hint('avo start <task>', 'to begin tracking'));
      return;
    }

    for (final task in summary.tasks) {
      final title = await resolveTaskTitle(taskService, task.taskId);
      final dur = task.formattedDuration;
      final padLen = lineWidth - title.length - dur.length - 4;
      final padding = padLen > 0 ? ' ' * padLen : ' ';
      print('  $title$padding$dur');
    }
    print('');
    print(hint('avo week', 'to see this week\'s summary'));
  }
}

/// Week summary command.
class WeekCommand extends Command<void> {
  final WorklogService worklogService;
  final TaskService taskService;
  final PlanService planService;
  final List<String> categories;

  WeekCommand({
    required this.worklogService,
    required this.taskService,
    required this.planService,
    this.categories = const [],
  });

  @override
  String get name => 'week';

  @override
  String get description => 'Weekly report with categories and tasks';

  @override
  String get invocation => 'avo week [FROM] [TO]';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;

    late List<DaySummary> summaries;

    if (rest.length >= 2) {
      // Custom date range: avo week 2026-02-01 2026-02-14
      if (!isValidDate(rest[0]) || !isValidDate(rest[1])) {
        print('Invalid date range. Use: avo week YYYY-MM-DD YYYY-MM-DD');
        return;
      }
      final fromParts = rest[0].split('-');
      final toParts = rest[1].split('-');
      final from = DateTime(int.parse(fromParts[0]), int.parse(fromParts[1]), int.parse(fromParts[2]));
      final to = DateTime(int.parse(toParts[0]), int.parse(toParts[1]), int.parse(toParts[2]));
      if (to.isBefore(from)) {
        print('End date must be after start date.');
        return;
      }
      summaries = await worklogService.rangeSummary(from: from, to: to);
    } else if (rest.length == 1) {
      // Anchor to a specific week: avo week 2026-02-10
      if (!isValidDate(rest[0])) {
        print('Invalid date: "${rest[0]}". Use YYYY-MM-DD format.');
        return;
      }
      final parts = rest[0].split('-');
      final anchor = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      summaries = await worklogService.weekSummary(anchor: anchor);
    } else {
      // Current week
      summaries = await worklogService.weekSummary();
    }

    final totalMs =
        summaries.fold<int>(0, (sum, d) => sum + d.total.inMilliseconds);
    final total = Duration(milliseconds: totalMs);

    final startDate = summaries.first.date;
    final endDate = summaries.last.date;
    print(sectionHeader('$startDate ~ $endDate'));
    print('  Total:${' ' * (lineWidth - 8 - formatDuration(total).length - 2)}${formatDuration(total)}');
    print(separator());

    if (totalMs == 0) {
      print('  No time logged this week.');
      print('');
      print(hint('avo start <task>', 'to begin tracking'));
      return;
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxMs = summaries.fold<int>(
        0,
        (max, d) =>
            d.total.inMilliseconds > max ? d.total.inMilliseconds : max);

    for (final day in summaries) {
      final dateParts = day.date.split('-');
      final dt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
      final label = '${dayNames[dt.weekday - 1]} ${dateParts[1]}/${dateParts[2]}';
      final bar = buildBar(day.total.inMilliseconds, maxMs);
      final dur =
          day.total.inMilliseconds > 0 ? day.formattedDuration : '-';
      print('  ${label.padRight(9)}  $bar  $dur');
    }
    print(separator());
    print('');

    // ── Categories: plan vs actual for the range ──
    final fromParts = summaries.first.date.split('-');
    final toParts = summaries.last.date.split('-');
    final rangeFrom = DateTime(int.parse(fromParts[0]), int.parse(fromParts[1]), int.parse(fromParts[2]));
    final rangeTo = DateTime(int.parse(toParts[0]), int.parse(toParts[1]), int.parse(toParts[2]));
    final weekPlan = await planService.rangeSummary(from: rangeFrom, to: rangeTo);
    print(sectionHeader('CATEGORIES'));
    await printPlanTable(weekPlan, defaultCategories: categories);
    print(separator());
    print('');

    // ── Tasks worked on this week ──
    print(sectionHeader('TASKS'));
    final taskTotals = <String, int>{};
    for (final daySummary in summaries) {
      for (final t in daySummary.tasks) {
        taskTotals[t.taskId] =
            (taskTotals[t.taskId] ?? 0) + t.total.inMilliseconds;
      }
    }

    if (taskTotals.isEmpty) {
      print('  No tasks worked on.');
    } else {
      // Sort by total time descending
      final sorted = taskTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sorted) {
        try {
          final task = await taskService.show(entry.key);
          final check = task.isDone ? 'x' : ' ';
          final id = task.id.substring(0, 8);
          final dur = formatDuration(Duration(milliseconds: entry.value));
          final issueTag = task.issueId != null ? ' [${task.issueId}]' : '';
          final catTag = task.category != null ? ' (${task.category})' : '';
          print('  [$check] $id  ${task.title}$issueTag$catTag  $dur');
        } catch (_) {
          final dur = formatDuration(Duration(milliseconds: entry.value));
          print('  [ ] ${entry.key.substring(0, 8)}  (unknown)  $dur');
        }
      }
    }
    print(separator());
  }
}

/// Daily report command — status-style dashboard for any date.
class DailyCommand extends Command<void> {
  final WorklogService worklogService;
  final TaskService taskService;
  final PlanService planService;
  final List<String> categories;

  DailyCommand({
    required this.worklogService,
    required this.taskService,
    required this.planService,
    this.categories = const [],
  });

  @override
  String get name => 'daily';

  @override
  String get description => 'Daily report: worklogs, tasks, and plan vs actual';

  @override
  String get invocation => 'avo daily [YYYY-MM-DD]';

  @override
  Future<void> run() async {
    final dateArg = argResults!.rest.isNotEmpty ? argResults!.rest.first : null;
    final dateStr = dateArg ?? todayString();

    if (!isValidDate(dateStr)) {
      print('Invalid date: "$dateStr". Use YYYY-MM-DD format.');
      return;
    }

    final dateParts = dateStr.split('-');
    final date = DateTime(
        int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
    final dateLabel = formatDate(date);

    // ── Worklog ──
    print(sectionHeader('$dateLabel'));
    final summary = await worklogService.daySummary(dateStr);
    print('  Total:${' ' * (lineWidth - 8 - summary.formattedDuration.length - 2)}${summary.formattedDuration}');

    if (summary.tasks.isEmpty) {
      print('  No time logged.');
    } else {
      for (final task in summary.tasks) {
        final title = await resolveTaskTitle(taskService, task.taskId);
        final dur = task.formattedDuration;
        final padLen = lineWidth - title.length - dur.length - 4;
        final padding = padLen > 0 ? ' ' * padLen : ' ';
        print('  $title$padding$dur');
      }
    }
    print(separator());
    print('');

    // ── Tasks worked on ──
    print(sectionHeader('TASKS'));
    if (summary.tasks.isEmpty) {
      print('  No tasks worked on.');
    } else {
      for (final taskSummary in summary.tasks) {
        try {
          final task = await taskService.show(taskSummary.taskId);
          final check = task.isDone ? 'x' : ' ';
          final id = task.id.substring(0, 8);
          final issueTag = task.issueId != null ? ' [${task.issueId}]' : '';
          final catTag = task.category != null ? ' (${task.category})' : '';
          print('  [$check] $id  ${task.title}$issueTag$catTag  ${taskSummary.formattedDuration}');
        } catch (_) {
          print('  [ ] ${taskSummary.taskId.substring(0, 8)}  (unknown)  ${taskSummary.formattedDuration}');
        }
      }
    }
    print(separator());
    print('');

    // ── Plan vs Actual ──
    final planSummary = await planService.summary(day: dateStr);
    final plannedTasks = await planService.listTasksForDay(day: dateStr);
    print(sectionHeader('PLAN'));
    await printPlanTable(planSummary,
        defaultCategories: categories,
        plannedTasks: plannedTasks,
        taskService: taskService,
        worklogService: worklogService);
    print(separator());
  }
}

// ============================================================
// Project Commands
// ============================================================

/// Base class for project commands.
abstract class ProjectSubcommand extends Command<void> {
  final ProjectService projectService;
  ProjectSubcommand(this.projectService);
}

/// Project management command group.
class ProjectCommand extends Command<void> {
  ProjectCommand(ProjectService projectService) {
    addSubcommand(ProjectAddCommand(projectService));
    addSubcommand(ProjectListCommand(projectService));
    addSubcommand(ProjectShowCommand(projectService));
    addSubcommand(ProjectDeleteCommand(projectService));
  }

  @override
  String get name => 'project';

  @override
  String get description => 'Project management (add, list, show, delete)';
}

class ProjectAddCommand extends ProjectSubcommand {
  ProjectAddCommand(super.projectService) {
    argParser.addOption('icon', abbr: 'i', help: 'Project icon');
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Create a new project';

  @override
  String get invocation => 'avo project add <title> [-i icon]';

  @override
  String? get usageFooter => '\nExample:\n'
      '  avo project add "Web App" -i "🌐"';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final title = args.isNotEmpty ? args.join(' ') : null;

    if (title == null) {
      print('Missing project title.');
      print('');
      print('  Usage: avo project add <title> [-i icon]');
      print('  Example: avo project add "Web App" -i "🌐"');
      return;
    }

    final icon = argResults?['icon'] as String?;

    final project = await projectService.add(
      title: title,
      icon: icon,
    );
    final shortId = project.id.substring(0, 8);
    print('Created project: "$title"');
    print(kvRow('ID:', shortId));
    print('');
    print(hint('avo task add -p $shortId <title>', 'to add a task'));
    print(hint('avo project show $shortId', 'to see details'));
  }
}

class ProjectListCommand extends ProjectSubcommand {
  ProjectListCommand(super.projectService) {
    argParser.addFlag('all', abbr: 'a', help: 'Include archived projects');
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List projects';

  @override
  String get invocation => 'avo project list [-a]';

  @override
  String? get usageFooter => '\nUse -a to include archived projects.';

  @override
  Future<void> run() async {
    final includeArchived = argResults?['all'] as bool? ?? false;
    final projects =
        await projectService.list(includeArchived: includeArchived);

    if (projects.isEmpty) {
      print(includeArchived ? 'No projects.' : 'No active projects.');
      print('');
      if (!includeArchived) {
        print(hint('avo project add <title>', 'to create one'));
      }
      return;
    }

    final label = includeArchived ? 'All Projects' : 'Projects';
    print('$label (${projects.length}):');
    for (final project in projects) {
      final id = project.id.substring(0, 8);
      final archived = project.isArchived ? ' [archived]' : '';
      final count = await projectService.taskCount(project.id);
      final iconStr = project.icon != null ? '${project.icon} ' : '';
      print('  $id  $iconStr${project.title}  ($count tasks)$archived');
    }
    print('');
    print(hint('avo project show <id>', 'to see details'));
  }
}

class ProjectShowCommand extends ProjectSubcommand {
  ProjectShowCommand(super.projectService);

  @override
  String get name => 'show';

  @override
  String get description => 'Show project details';

  @override
  String get invocation => 'avo project show <id>';

  @override
  String? get usageFooter => '\nID can be a prefix (e.g. "a1b2" matches "a1b2c3d4...").';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final projectId = args.isNotEmpty ? args.first : null;

    if (projectId == null) {
      print('Missing project ID.');
      print('');
      print('  Usage: avo project show <id>');
      print(hint('avo project list', 'to see project IDs'));
      return;
    }

    try {
      final project = await projectService.show(projectId);
      final count = await projectService.taskCount(project.id);
      print('Project: "${project.title}"');
      print(kvRow('ID:', project.id));
      if (project.icon != null) {
        print(kvRow('Icon:', project.icon!));
      }
      print(kvRow('Tasks:', '$count active'));
      print(kvRow('Archived:', '${project.isArchived}'));
      print(kvRow('Created:', '${project.createdTimestamp ?? 'unknown'}'));
      print('');
      final shortId = project.id.substring(0, 8);
      print(hint('avo task add -p $shortId <title>', 'to add a task'));
      print(hint('avo task list', 'to see tasks'));
    } on ProjectNotFoundException {
      print('No project found matching "$projectId".');
      print('');
      print(hint('avo project list', 'to see available projects'));
    } on AmbiguousProjectIdException catch (e) {
      print('Multiple projects match "$projectId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    }
  }
}

class ProjectDeleteCommand extends ProjectSubcommand {
  ProjectDeleteCommand(super.projectService);

  @override
  String get name => 'delete';

  @override
  String get description => 'Delete a project';

  @override
  String get invocation => 'avo project delete <id>';

  @override
  String? get usageFooter => '\nPrompts for confirmation before deleting.';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final projectId = args.isNotEmpty ? args.first : null;

    if (projectId == null) {
      print('Missing project ID.');
      print('');
      print('  Usage: avo project delete <id>');
      print(hint('avo project list', 'to see project IDs'));
      return;
    }

    try {
      final project = await projectService.show(projectId);
      stdout.write('Delete "${project.title}" (${project.id.substring(0, 8)})? [y/N] ');
      final input = stdin.readLineSync()?.trim().toLowerCase() ?? 'n';
      if (input != 'y') {
        print('Cancelled.');
        return;
      }

      await projectService.delete(projectId);
      print('Deleted: "${project.title}"');
    } on ProjectNotFoundException {
      print('No project found matching "$projectId".');
      print('');
      print(hint('avo project list', 'to see available projects'));
    } on AmbiguousProjectIdException catch (e) {
      print('Multiple projects match "$projectId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    }
  }
}

// ============================================================
// Worklog Commands
// ============================================================

/// Base class for worklog subcommands.
abstract class WorklogSubcommand extends Command<void> {
  final WorklogService worklogService;
  final TaskService taskService;
  final JiraService? jiraService;
  WorklogSubcommand(this.worklogService, this.taskService, {this.jiraService});
}

/// Worklog management command group.
class WorklogCommand extends Command<void> {
  WorklogCommand(WorklogService worklogService, TaskService taskService,
      {JiraService? jiraService}) {
    addSubcommand(
        WorklogAddCommand(worklogService, taskService, jiraService: jiraService));
    addSubcommand(WorklogEditCommand(worklogService, taskService));
    addSubcommand(WorklogListCommand(worklogService, taskService));
    addSubcommand(WorklogDeleteCommand(worklogService, taskService));
  }

  @override
  String get name => 'worklog';

  @override
  String get description => 'Worklog management (add, edit, list, delete)';
}

/// Worklog list subcommand (under `avo worklog list`).
class WorklogListCommand extends WorklogSubcommand {
  WorklogListCommand(super.worklogService, super.taskService) {
    argParser.addOption('count', abbr: 'n', help: 'Number of entries',
        defaultsTo: '10');
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List recent worklogs';

  @override
  String get invocation => 'avo worklog list [-n count]';

  @override
  String? get usageFooter => '\nShows the 10 most recent worklogs by default.';

  @override
  Future<void> run() async {
    final limit = int.tryParse(argResults?['count'] as String? ?? '10') ?? 10;
    final worklogs = await worklogService.listRecent(limit: limit);

    if (worklogs.isEmpty) {
      print('No worklogs yet.');
      print('');
      print(hint('avo worklog add', 'to log manually'));
      return;
    }

    print('Recent Worklogs (${worklogs.length}):');
    print(separator());
    for (final w in worklogs) {
      final title = await resolveTaskTitle(taskService, w.taskId);
      final dur = formatDuration(Duration(milliseconds: w.durationMs));
      final startDate = formatRelativeDate(w.startTime);
      final startTime = formatTime(w.startTime);
      final syncIcon = w.isSyncedToJira ? ' [synced]' : '';
      final commentStr = w.comment != null && w.comment!.isNotEmpty
          ? '  "${w.comment}"'
          : '';
      print('  ${w.id.substring(0, 8)}  $title  $dur  $startDate $startTime$syncIcon$commentStr');
    }
  }
}

class WorklogDeleteCommand extends WorklogSubcommand {
  WorklogDeleteCommand(super.worklogService, super.taskService);

  @override
  String get name => 'delete';

  @override
  String get description => 'Delete a worklog';

  @override
  String get invocation => 'avo worklog delete <id>';

  @override
  String? get usageFooter => '\nPrompts for confirmation before deleting.';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final worklogId = args.isNotEmpty ? args.first : null;

    if (worklogId == null) {
      print('Missing worklog ID.');
      print('');
      print('  Usage: avo worklog delete <id>');
      print(hint('avo worklog list', 'to see recent worklogs'));
      return;
    }

    try {
      final worklog = await worklogService.show(worklogId);
      final taskTitle = await resolveTaskTitle(taskService, worklog.taskId);
      final dur = formatDuration(Duration(milliseconds: worklog.durationMs));
      stdout.write('Delete worklog "$taskTitle" ($dur, ${worklog.id.substring(0, 8)})? [y/N] ');
      final input = stdin.readLineSync()?.trim().toLowerCase() ?? 'n';
      if (input != 'y') {
        print('Cancelled.');
        return;
      }

      await worklogService.deleteWorklog(worklogId);
      print('Deleted worklog: "$taskTitle" ($dur)');
    } on WorklogNotFoundException {
      print('No worklog found matching "$worklogId".');
      print('');
      print(hint('avo worklog list', 'to see recent worklogs'));
    } on AmbiguousWorklogIdException catch (e) {
      print('Multiple worklogs match "$worklogId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
    }
  }
}

/// Worklog add subcommand (under `avo worklog add`).
class WorklogAddCommand extends WorklogSubcommand {
  WorklogAddCommand(super.worklogService, super.taskService,
      {super.jiraService}) {
    argParser.addOption('task', abbr: 't', help: 'Task ID or prefix');
    argParser.addOption('start', abbr: 's', help: 'Start time (e.g. 9:00, 2026-02-15T09:00)');
    argParser.addOption('duration', abbr: 'd', help: 'Duration (e.g. 1h30m, 45m)');
    argParser.addOption('message', abbr: 'm', help: 'Description/comment');
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Add a worklog with start time and duration';

  @override
  String get invocation => 'avo worklog add [-t task] [-s start] [-d duration] [-m message]';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo worklog add -t a1b2 -s 9:00 -d 1h30m -m "morning work"\n'
      '  avo worklog add                    # interactive mode\n'
      '\n'
      'Time formats: 9:00, 14:30, 2026-02-15T09:00, yesterday 14:00\n'
      'Duration formats: 30m, 1h, 1h30m, 2h 15m';

  @override
  Future<void> run() async {
    var taskInput = argResults?['task'] as String?;
    final startInput = argResults?['start'] as String?;
    final durationInput = argResults?['duration'] as String?;
    var comment = argResults?['message'] as String?;

    // Also accept task as positional arg
    final rest = argResults?.rest ?? [];
    if (taskInput == null && rest.isNotEmpty) {
      taskInput = rest.first;
    }

    // Determine if interactive mode is needed
    final interactive = taskInput == null || startInput == null || durationInput == null;

    // Resolve task
    String taskId;
    String taskTitle;
    if (taskInput == null) {
      // Interactive task picker
      final tasks = await taskService.list();
      if (tasks.isEmpty) {
        print('No active tasks.');
        print('');
        print(hint('avo task add <title>', 'to create one'));
        return;
      }

      final timeByTask = await worklogService.timeByTask();
      final pickerItems = tasks.map((task) {
        final check = task.isDone ? 'x' : ' ';
        final id = task.id.substring(0, 8);
        final issueTag = task.issueId != null
            ? task.issueId!.padRight(10)
            : ''.padRight(10);
        final worked = timeByTask[task.id] ?? Duration.zero;
        final estimate = task.timeEstimate > 0
            ? Duration(milliseconds: task.timeEstimate)
            : null;
        final time = formatTimeWithEstimate(worked, estimate);
        final displayLine =
            '  [$check] $id  $issueTag  ${task.title}  ($time)';
        final searchText =
            '${task.title} ${task.issueId ?? ''} ${task.id} ${task.category ?? ''}'.toLowerCase();
        return PickerItem<TaskDocument>(
          value: task,
          displayLine: displayLine,
          searchText: searchText,
        );
      }).toList();

      final picker = InteractivePicker<TaskDocument>(items: pickerItems);
      final selected = picker.pick();
      if (selected == null) {
        print('Cancelled.');
        return;
      }
      taskId = selected.id;
      taskTitle = selected.title;
    } else {
      try {
        final task = await taskService.show(taskInput);
        taskId = task.id;
        taskTitle = task.title;
      } on TaskNotFoundException {
        print('No task found matching "$taskInput".');
        print('');
        print(hint('avo task list', 'to see available tasks'));
        return;
      } on AmbiguousTaskIdException catch (e) {
        print('Multiple tasks match "$taskInput":');
        for (final id in e.matchingIds) {
          print('  ${id.substring(0, 8)}');
        }
        print('');
        print(hintPlain('Use a longer prefix to be specific.'));
        return;
      }
    }

    // Resolve start time
    DateTime? start;
    if (startInput != null) {
      start = parseTimeOfDay(startInput);
      if (start == null) {
        print('Invalid start time: "$startInput"');
        print('');
        print('  Valid formats: 9:00, 14:30, 2026-02-15T09:00, yesterday 14:00');
        return;
      }
    } else if (interactive) {
      final rl = TerminalReadline();
      while (start == null) {
        final input = rl.readLine('Start time (e.g. 9:00, 14:30): ');
        if (input == null) { print('Cancelled.'); return; }
        start = parseTimeOfDay(input.trim());
        if (start == null) {
          print('  Invalid time. Try 9:00, 14:30, 2026-02-15T09:00, or yesterday 14:00.');
        }
      }
    }

    // Resolve duration
    Duration? duration;
    if (durationInput != null) {
      duration = parseDuration(durationInput);
      if (duration == null) {
        print('Invalid duration: "$durationInput"');
        print('');
        print('  Valid formats: 30m, 1h, 1h30m, 2h 15m');
        return;
      }
    } else if (interactive) {
      final rl = TerminalReadline();
      while (duration == null) {
        final input = rl.readLine('Duration (e.g. 1h30m, 45m): ');
        if (input == null) { print('Cancelled.'); return; }
        duration = parseDuration(input.trim());
        if (duration == null) {
          print('  Invalid duration. Try 30m, 1h, 1h30m.');
        }
      }
    }

    // Resolve comment
    if (comment == null && interactive) {
      final rl = TerminalReadline();
      final input = rl.readLine('Description (optional): ');
      if (input != null && input.trim().isNotEmpty) {
        comment = input.trim();
      }
    }

    final worklog = await worklogService.createWorklog(
      taskId: taskId,
      start: start!,
      duration: duration!,
      comment: comment,
    );

    print('Logged ${formatDuration(duration)} on "$taskTitle"');
    print(kvRow('Worklog:', worklog.id.substring(0, 8)));
    print(kvRow('Start:', formatTime(start)));
    print(kvRow('End:', formatTime(start.add(duration))));
    if (comment != null) print(kvRow('Comment:', comment));

    // Auto-push worklog to Jira if service is available
    if (jiraService != null) {
      final pushed = await jiraService!.pushWorklog(worklog.id);
      if (pushed) {
        print(kvRow('Jira:', 'worklog synced'));
      }
    }

    print('');
    print(hint('avo today', 'to see today\'s total'));
    print(hint('avo worklog edit ${worklog.id.substring(0, 8)}', 'to edit'));
  }
}

/// Worklog edit subcommand (under `avo worklog edit`).
class WorklogEditCommand extends WorklogSubcommand {
  WorklogEditCommand(super.worklogService, super.taskService) {
    argParser.addOption('start', abbr: 's', help: 'New start time');
    argParser.addOption('duration', abbr: 'd', help: 'New duration');
    argParser.addOption('message', abbr: 'm', help: 'New description');
  }

  @override
  String get name => 'edit';

  @override
  String get description => 'Edit an existing worklog';

  @override
  String get invocation => 'avo worklog edit <id> [-s start] [-d duration] [-m message]';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo worklog edit a1b2 -d 2h -m "updated"\n'
      '  avo worklog edit a1b2              # interactive mode';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final worklogId = args.isNotEmpty ? args.first : null;

    if (worklogId == null) {
      print('Missing worklog ID.');
      print('');
      print('  Usage: avo worklog edit <id> [-s start] [-d duration] [-m message]');
      print(hint('avo worklog list', 'to see recent worklogs'));
      return;
    }

    final startInput = argResults?['start'] as String?;
    final durationInput = argResults?['duration'] as String?;
    final messageInput = argResults?['message'] as String?;

    // Load existing worklog first
    WorklogDocument worklog;
    try {
      worklog = await worklogService.show(worklogId);
    } on WorklogNotFoundException {
      print('No worklog found matching "$worklogId".');
      print('');
      print(hint('avo worklog list', 'to see recent worklogs'));
      return;
    } on AmbiguousWorklogIdException catch (e) {
      print('Multiple worklogs match "$worklogId":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
      return;
    }

    final interactive = startInput == null && durationInput == null && messageInput == null;

    DateTime? newStart;
    Duration? newDuration;
    String? newComment;

    if (interactive) {
      // Show current values
      final curStart = formatTime(worklog.startTime);
      final curEnd = formatTime(worklog.endTime);
      final curDur = formatDuration(Duration(milliseconds: worklog.durationMs));
      final curComment = worklog.comment ?? '';
      final taskTitle = await resolveTaskTitle(taskService, worklog.taskId);
      print('Editing worklog ${worklog.id.substring(0, 8)} — "$taskTitle"');
      print('  Current:  $curStart - $curEnd  ($curDur)  "$curComment"');
      print('');

      final rl = TerminalReadline();

      // Prompt start
      final startStr = rl.readLine('  Start [$curStart]: ');
      if (startStr == null) { print('Cancelled.'); return; }
      if (startStr.trim().isNotEmpty) {
        newStart = parseTimeOfDay(startStr.trim());
        if (newStart == null) {
          print('  Invalid time — keeping current.');
        }
      }

      // Prompt duration
      final durStr = rl.readLine('  Duration [$curDur]: ');
      if (durStr == null) { print('Cancelled.'); return; }
      if (durStr.trim().isNotEmpty) {
        newDuration = parseDuration(durStr.trim());
        if (newDuration == null) {
          print('  Invalid duration — keeping current.');
        }
      }

      // Prompt comment
      final commentStr = rl.readLine('  Description [$curComment]: ');
      if (commentStr == null) { print('Cancelled.'); return; }
      if (commentStr.trim().isNotEmpty) {
        newComment = commentStr.trim();
      }

      if (newStart == null && newDuration == null && newComment == null) {
        print('No changes.');
        return;
      }
    } else {
      // Param mode
      if (startInput != null) {
        newStart = parseTimeOfDay(startInput);
        if (newStart == null) {
          print('Invalid start time: "$startInput"');
          print('');
          print('  Valid formats: 9:00, 14:30, 2026-02-15T09:00, yesterday 14:00');
          return;
        }
      }
      if (durationInput != null) {
        newDuration = parseDuration(durationInput);
        if (newDuration == null) {
          print('Invalid duration: "$durationInput"');
          print('');
          print('  Valid formats: 30m, 1h, 1h30m, 2h 15m');
          return;
        }
      }
      newComment = messageInput;
    }

    final updated = await worklogService.editWorklog(
      worklogId,
      start: newStart,
      duration: newDuration,
      comment: newComment,
    );

    final taskTitle = await resolveTaskTitle(taskService, updated.taskId);
    print('Updated worklog ${updated.id.substring(0, 8)} — "$taskTitle"');
    print(kvRow('Start:', formatTime(updated.startTime)));
    print(kvRow('End:', formatTime(updated.endTime)));
    print(kvRow('Duration:', formatDuration(Duration(milliseconds: updated.durationMs))));
    if (updated.comment != null) print(kvRow('Comment:', updated.comment!));
  }
}

// ============================================================
// Plan Commands
// ============================================================

/// Base class for plan commands.
abstract class PlanSubcommand extends Command<void> {
  final PlanService planService;
  PlanSubcommand(this.planService);
}

/// Plan management command group.
class PlanCommand extends Command<void> {
  final PlanService planService;

  PlanCommand(this.planService, {
    List<String> categories = const [],
    required TaskService taskService,
    required WorklogService worklogService,
  }) {
    addSubcommand(PlanAddCommand(planService));
    addSubcommand(PlanListCommand(planService,
        categories: categories,
        taskService: taskService,
        worklogService: worklogService));
    addSubcommand(PlanRemoveCommand(planService));
    addSubcommand(PlanTaskCommand(planService, taskService));
    addSubcommand(PlanUntaskCommand(planService, taskService));
    addSubcommand(PlanCancelCommand(planService, taskService));
    addSubcommand(PlanUncancelCommand(planService, taskService));
  }

  @override
  String get name => 'plan';

  @override
  String get description => 'Daily time planning by category (add, list, remove, task, untask, cancel, uncancel)';
}

class PlanAddCommand extends PlanSubcommand {
  PlanAddCommand(super.planService) {
    argParser.addOption('duration', abbr: 'd', help: 'Planned duration (e.g. 3h, 1h30m)');
    argParser.addOption('day', help: 'Day (YYYY-MM-DD, defaults to today)');
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Add planned time for a category';

  @override
  String get invocation => 'avo plan add <category> -d <duration> [--day YYYY-MM-DD]';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo plan add Working -d 3h\n'
      '  avo plan add Learning -d 2h --day 2026-02-14';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final category = args.isNotEmpty ? args.join(' ') : null;
    final durationStr = argResults?['duration'] as String?;
    final dayStr = argResults?['day'] as String?;

    if (category == null || durationStr == null) {
      print('Missing category or duration.');
      print('');
      print('  Usage: avo plan add <category> -d <duration> [--day YYYY-MM-DD]');
      print('  Example: avo plan add Working -d 3h');
      print('  Example: avo plan add Learning -d 2h --day 2026-02-14');
      return;
    }

    final duration = parseDuration(durationStr);
    if (duration == null) {
      print('Invalid duration: "$durationStr"');
      print('');
      print('  Valid formats: 30m, 1h, 1h30m, 2h 15m');
      return;
    }

    if (dayStr != null && !isValidDate(dayStr)) {
      print('Invalid date: "$dayStr". Use YYYY-MM-DD format.');
      return;
    }

    try {
      final plan = await planService.add(
        category: category,
        durationMs: duration.inMilliseconds,
        day: dayStr,
      );
      print('Planned ${formatDuration(duration)} for "$category" on ${plan.day}.');
      print('');
      print(hint('avo plan', 'to see today\'s plan'));
    } on DuplicatePlanEntryException catch (e) {
      print('$e');
      print('');
      print(hint('avo plan remove $category', 'to remove and re-add'));
    }
  }
}

class PlanListCommand extends PlanSubcommand {
  final List<String> categories;
  final TaskService taskService;
  final WorklogService worklogService;

  PlanListCommand(super.planService, {
    this.categories = const [],
    required this.taskService,
    required this.worklogService,
  }) {
    argParser.addOption('day', help: 'Day (YYYY-MM-DD, defaults to today)');
  }

  @override
  String get name => 'list';

  @override
  String get description => 'Show plan-vs-actual for a day';

  @override
  String get invocation => 'avo plan list [--day YYYY-MM-DD]';

  @override
  String? get usageFooter => '\nDefaults to today if no day is specified.';

  @override
  Future<void> run() async {
    final dayStr = argResults?['day'] as String?;

    if (dayStr != null && !isValidDate(dayStr)) {
      print('Invalid date: "$dayStr". Use YYYY-MM-DD format.');
      return;
    }

    final summary = await planService.summary(day: dayStr);
    final plannedTasks = await planService.listTasksForDay(day: dayStr);

    print('Plan for ${summary.day}:');
    await printPlanTable(summary,
        defaultCategories: categories,
        plannedTasks: plannedTasks,
        taskService: taskService,
        worklogService: worklogService);

    if (summary.totalPlanned == Duration.zero &&
        summary.totalActual == Duration.zero &&
        plannedTasks.isEmpty) {
      print('');
      print(hint('avo plan add <category> -d <dur>', 'to start planning'));
    }
  }
}

class PlanRemoveCommand extends PlanSubcommand {
  PlanRemoveCommand(super.planService) {
    argParser.addOption('day', help: 'Day (YYYY-MM-DD, defaults to today)');
  }

  @override
  String get name => 'remove';

  @override
  String get description => 'Remove a category from the plan';

  @override
  String get invocation => 'avo plan remove <category> [--day YYYY-MM-DD]';

  @override
  String? get usageFooter => '\nExample:\n'
      '  avo plan remove Learning --day 2026-02-14';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final category = args.isNotEmpty ? args.join(' ') : null;
    final dayStr = argResults?['day'] as String?;

    if (category == null) {
      print('Missing category.');
      print('');
      print('  Usage: avo plan remove <category> [--day YYYY-MM-DD]');
      return;
    }

    if (dayStr != null && !isValidDate(dayStr)) {
      print('Invalid date: "$dayStr". Use YYYY-MM-DD format.');
      return;
    }

    try {
      final entry = await planService.remove(category: category, day: dayStr);
      print('Removed "$category" from plan on ${entry.day}.');
    } on PlanEntryNotFoundException catch (e) {
      print('$e');
      print('');
      print(hint('avo plan', 'to see current plan'));
    }
  }
}

class PlanTaskCommand extends PlanSubcommand {
  final TaskService taskService;

  PlanTaskCommand(super.planService, this.taskService) {
    argParser.addOption('day', help: 'Day (YYYY-MM-DD, defaults to today)');
    argParser.addOption('estimate', abbr: 'e', help: 'Time estimate (e.g. 2h, 1h30m)');
  }

  @override
  String get name => 'task';

  @override
  String get description => 'Add a task to the day plan';

  @override
  String get invocation => 'avo plan task <task-id> [--day YYYY-MM-DD] [-e <duration>]';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo plan task a1b2\n'
      '  avo plan task a1b2 -e 2h\n'
      '  avo plan task a1b2 --day 2026-02-20 -e 1h30m';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskIdInput = args.isNotEmpty ? args.first : null;
    final dayStr = argResults?['day'] as String?;
    final estimateStr = argResults?['estimate'] as String?;

    if (taskIdInput == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo plan task <task-id> [-e <duration>] [--day YYYY-MM-DD]');
      return;
    }

    if (dayStr != null && !isValidDate(dayStr)) {
      print('Invalid date: "$dayStr". Use YYYY-MM-DD format.');
      return;
    }

    int estimateMs = 0;
    if (estimateStr != null) {
      final duration = parseDuration(estimateStr);
      if (duration == null) {
        print('Invalid duration: "$estimateStr"');
        print('');
        print('  Valid formats: 30m, 1h, 1h30m, 2h 15m');
        return;
      }
      estimateMs = duration.inMilliseconds;
    }

    // Resolve task
    String taskId;
    String taskTitle;
    try {
      final task = await taskService.show(taskIdInput);
      taskId = task.id;
      taskTitle = task.title;
    } on TaskNotFoundException {
      print('Task not found: "$taskIdInput"');
      return;
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskIdInput":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
      return;
    }

    try {
      final entry = await planService.addTask(
        taskId: taskId,
        estimateMs: estimateMs,
        day: dayStr,
      );
      final est = estimateMs > 0
          ? ' (${formatDuration(Duration(milliseconds: estimateMs))})'
          : '';
      print('Added "$taskTitle" to plan for ${entry.day}$est.');
      print('');
      print(hint('avo plan', 'to see today\'s plan'));
    } on DuplicatePlanTaskException catch (e) {
      print('$e');
      print('');
      print(hint('avo plan untask ${taskId.substring(0, 8)}', 'to remove and re-add'));
    }
  }
}

class PlanUntaskCommand extends PlanSubcommand {
  final TaskService taskService;

  PlanUntaskCommand(super.planService, this.taskService) {
    argParser.addOption('day', help: 'Day (YYYY-MM-DD, defaults to today)');
  }

  @override
  String get name => 'untask';

  @override
  String get description => 'Remove a task from the day plan';

  @override
  String get invocation => 'avo plan untask <task-id> [--day YYYY-MM-DD]';

  @override
  String? get usageFooter => '\nExample:\n'
      '  avo plan untask a1b2 --day 2026-02-20';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskIdInput = args.isNotEmpty ? args.first : null;
    final dayStr = argResults?['day'] as String?;

    if (taskIdInput == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo plan untask <task-id> [--day YYYY-MM-DD]');
      return;
    }

    if (dayStr != null && !isValidDate(dayStr)) {
      print('Invalid date: "$dayStr". Use YYYY-MM-DD format.');
      return;
    }

    // Resolve task
    String taskId;
    String taskTitle;
    try {
      final task = await taskService.show(taskIdInput);
      taskId = task.id;
      taskTitle = task.title;
    } on TaskNotFoundException {
      print('Task not found: "$taskIdInput"');
      return;
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskIdInput":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
      return;
    }

    try {
      final entry = await planService.removeTask(taskId: taskId, day: dayStr);
      print('Removed "$taskTitle" from plan on ${entry.day}.');
    } on PlanTaskNotFoundException catch (e) {
      print('$e');
      print('');
      print(hint('avo plan', 'to see current plan'));
    }
  }
}

class PlanCancelCommand extends PlanSubcommand {
  final TaskService taskService;

  PlanCancelCommand(super.planService, this.taskService) {
    argParser.addOption('day', help: 'Day (YYYY-MM-DD, defaults to today)');
  }

  @override
  String get name => 'cancel';

  @override
  String get description => 'Cancel a task in the day plan';

  @override
  String get invocation => 'avo plan cancel <task-id> [--day YYYY-MM-DD]';

  @override
  String? get usageFooter => '\nExample:\n'
      '  avo plan cancel a1b2 --day 2026-02-20';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskIdInput = args.isNotEmpty ? args.first : null;
    final dayStr = argResults?['day'] as String?;

    if (taskIdInput == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo plan cancel <task-id> [--day YYYY-MM-DD]');
      return;
    }

    if (dayStr != null && !isValidDate(dayStr)) {
      print('Invalid date: "$dayStr". Use YYYY-MM-DD format.');
      return;
    }

    // Resolve task
    String taskId;
    String taskTitle;
    try {
      final task = await taskService.show(taskIdInput);
      taskId = task.id;
      taskTitle = task.title;
    } on TaskNotFoundException {
      print('Task not found: "$taskIdInput"');
      return;
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskIdInput":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
      return;
    }

    try {
      final entry = await planService.cancelTask(taskId: taskId, day: dayStr);
      print('Cancelled "$taskTitle" on ${entry.day}.');
      print('');
      print(hint('avo plan', 'to see today\'s plan'));
    } on PlanTaskNotFoundException catch (e) {
      print('$e');
      print('');
      print(hint('avo plan', 'to see current plan'));
    }
  }
}

class PlanUncancelCommand extends PlanSubcommand {
  final TaskService taskService;

  PlanUncancelCommand(super.planService, this.taskService) {
    argParser.addOption('day', help: 'Day (YYYY-MM-DD, defaults to today)');
  }

  @override
  String get name => 'uncancel';

  @override
  String get description => 'Un-cancel a task in the day plan';

  @override
  String get invocation => 'avo plan uncancel <task-id> [--day YYYY-MM-DD]';

  @override
  String? get usageFooter => '\nExample:\n'
      '  avo plan uncancel a1b2 --day 2026-02-20';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskIdInput = args.isNotEmpty ? args.first : null;
    final dayStr = argResults?['day'] as String?;

    if (taskIdInput == null) {
      print('Missing task ID.');
      print('');
      print('  Usage: avo plan uncancel <task-id> [--day YYYY-MM-DD]');
      return;
    }

    if (dayStr != null && !isValidDate(dayStr)) {
      print('Invalid date: "$dayStr". Use YYYY-MM-DD format.');
      return;
    }

    // Resolve task
    String taskId;
    String taskTitle;
    try {
      final task = await taskService.show(taskIdInput);
      taskId = task.id;
      taskTitle = task.title;
    } on TaskNotFoundException {
      print('Task not found: "$taskIdInput"');
      return;
    } on AmbiguousTaskIdException catch (e) {
      print('Multiple tasks match "$taskIdInput":');
      for (final id in e.matchingIds) {
        print('  ${id.substring(0, 8)}');
      }
      print('');
      print(hintPlain('Use a longer prefix to be specific.'));
      return;
    }

    try {
      final entry = await planService.uncancelTask(taskId: taskId, day: dayStr);
      print('Un-cancelled "$taskTitle" on ${entry.day}.');
      print('');
      print(hint('avo plan', 'to see today\'s plan'));
    } on PlanTaskNotFoundException catch (e) {
      print('$e');
      print('');
      print(hint('avo plan', 'to see current plan'));
    }
  }
}

// ============================================================
// Jira Commands
// ============================================================

/// Base class for Jira commands that need the JiraService.
abstract class JiraSubcommand extends Command<void> {
  final JiraService jiraService;
  JiraSubcommand(this.jiraService);
}

/// Jira sync command group.
class JiraCommand extends Command<void> {
  JiraCommand(JiraService jiraService, AvodahPaths paths) {
    addSubcommand(JiraInitCommand(paths));
    addSubcommand(JiraSyncCommand(jiraService));
    addSubcommand(JiraStatusCommand(jiraService));
    addSubcommand(JiraSetupCommand(jiraService, paths));
  }

  @override
  String get name => 'jira';

  @override
  String get description => 'Jira integration (init, setup, sync, status)\n\n'
      'Workflow: init -> setup -> sync';
}

/// Generate Jira credentials template file with profile format.
class JiraInitCommand extends Command<void> {
  final AvodahPaths paths;

  JiraInitCommand(this.paths);

  @override
  String get name => 'init';

  @override
  String get description => 'Generate Jira credentials template file';

  @override
  String get invocation => 'avo jira init';

  @override
  String? get usageFooter => '\nCreates a credentials template at ~/.config/avodah/.\n'
      'Next steps: edit credentials, then run "avo jira setup".';

  @override
  Future<void> run() async {
    final credPath = paths.jiraCredentialsPath;
    final examplePath = '${credPath}.example';
    final file = File(credPath);

    if (await file.exists()) {
      print('Credentials file already exists:');
      print(kvRow('Path:', credPath));
      print('');
      print(hintPlain('Delete it first if you want to regenerate.'));
      print(hint('avo jira setup', 'to configure connection'));
      return;
    }

    // Ensure config directory exists
    await Directory(paths.configDir).create(recursive: true);

    final templateData = {
      '_comment':
          'Jira profiles for Avodah. Get your token at: https://id.atlassian.com/manage-profile/security/api-tokens',
      'jira_profiles': {
        'work': {
          'name': 'Work JIRA',
          'base_url': 'https://company.atlassian.net',
          'username': 'email@company.com',
          'api_token': 'your-api-token',
          'project_keys': ['PROJ'],
          'default_category': 'Working',
        },
      },
      'default_profiles': {
        'jira': 'work',
      },
    };

    // Pretty-print it
    const encoder = JsonEncoder.withIndent('  ');
    final content = '${encoder.convert(templateData)}\n';
    await file.writeAsString(content);

    // Also create .example file (safe to commit)
    await File(examplePath).writeAsString(content);

    print('Created Jira credentials files:');
    print(kvRow('Credentials:', credPath));
    print(kvRow('Example:', examplePath));
    print('');
    print('Next steps:');
    print('  1. Edit the credentials file with your Jira details');
    print('  2. Get an API token at:');
    print('     https://id.atlassian.com/manage-profile/security/api-tokens');
    print('  3. Run setup to connect:');
    print('');
    print(hintPlain('The .example file is safe to commit to version control.'));
    print(hint('avo jira setup', 'uses default profile'));
    print(hint('avo jira setup --profile work', 'uses named profile'));
  }
}

class JiraSyncCommand extends JiraSubcommand {
  JiraSyncCommand(super.jiraService) {
    argParser.addOption('profile',
        help: 'Switch to a named profile before syncing');
    argParser.addFlag('dry-run', help: 'Preview changes without applying');
    argParser.addFlag('interactive', defaultsTo: true,
        help: 'Prompt for each conflict (disable with --no-interactive)');
  }

  @override
  String get name => 'sync';

  @override
  String get description => 'Sync with Jira (2-way with conflict resolution)';

  @override
  String get invocation => 'avo jira sync [issue-key] [--profile name] [--dry-run] [--no-interactive]';

  @override
  String? get usageFooter => '\nExamples:\n'
      '  avo jira sync                      # sync all configured projects\n'
      '  avo jira sync PROJ-123             # sync single issue\n'
      '  avo jira sync --dry-run            # preview without applying\n'
      '  avo jira sync --profile work       # use specific profile\n'
      '  avo jira sync --no-interactive     # skip conflict prompts';

  @override
  Future<void> run() async {
    final profileName = argResults?['profile'] as String?;
    if (profileName != null) {
      await jiraService.setup(profileName: profileName);
    }

    final args = argResults?.rest ?? [];
    final issueKey = args.isNotEmpty ? args.first : null;
    final dryRun = argResults?['dry-run'] as bool? ?? false;
    final interactive = argResults?['interactive'] as bool? ?? true;

    var curPhase = '';
    var curTotal = 0;

    void finishPhase() {
      if (curPhase.isEmpty) return;
      stdout.write('\r\x1B[K');
      switch (curPhase) {
        case 'Fetching issues':
          print('  Fetched $curTotal issues.');
        case 'Fetching worklogs':
          print('  Fetched worklogs for $curTotal issues.');
        case 'Applying changes':
          print('  Applied $curTotal changes.');
      }
      curPhase = '';
    }

    void showProgress(String phase, int current, int total) {
      if (phase != curPhase) finishPhase();
      curPhase = phase;
      curTotal = total;
      final bar = progressBar(current, total, width: 20);
      stdout.write('\r  $phase... $bar $current/$total\x1B[K');
    }

    try {
      final context = await jiraService.computeSyncPreview(
        issueKey: issueKey,
        onProgress: showProgress,
      );
      finishPhase();
      final preview = context.preview;

      // Display preview
      print(sectionHeader('SYNC PREVIEW'));
      print(kvRow('New issues:', '${preview.newRemoteIssues.length}', labelWidth: 16) +
          (preview.newRemoteIssues.isNotEmpty ? '  (will create local tasks)' : ''));
      print(kvRow('New local logs:', '${preview.newLocalWorklogs.length}', labelWidth: 16) +
          (preview.newLocalWorklogs.isNotEmpty ? '  (will push to Jira)' : ''));
      print(kvRow('New remote logs:', '${preview.newRemoteWorklogs.length}', labelWidth: 16) +
          (preview.newRemoteWorklogs.isNotEmpty ? '  (will pull from Jira)' : ''));
      print(kvRow('Mismatches:', '${preview.worklogMismatches.length + preview.titleMismatches.length}', labelWidth: 16) +
          (preview.hasMismatches ? '  (need resolution)' : ''));
      print(kvRow('Up to date:', '${preview.upToDateTasks}', labelWidth: 16));
      print(separator());

      if (!preview.hasChanges) {
        print('Already in sync.');
        return;
      }

      if (dryRun) {
        _printMismatchDetails(preview);
        print('');
        print(hintPlain('Dry run -- no changes applied.'));
        return;
      }

      // Resolve mismatches
      if (preview.hasMismatches) {
        if (interactive) {
          _printAndPromptMismatches(preview);
        } else {
          print('');
          print(hintPlain('Non-interactive: skipping ${preview.worklogMismatches.length + preview.titleMismatches.length} mismatch(es).'));
        }
      }

      // Execute
      final result = await jiraService.executeSyncPlan(
        context,
        onProgress: showProgress,
      );
      finishPhase();

      print('');
      print(sectionHeader('SYNC RESULT'));
      if (result.tasksCreated > 0) print(kvRow('Tasks created:', '${result.tasksCreated}', labelWidth: 18));
      if (result.worklogsPushed > 0) print(kvRow('Worklogs pushed:', '${result.worklogsPushed}', labelWidth: 18));
      if (result.worklogsPulled > 0) print(kvRow('Worklogs pulled:', '${result.worklogsPulled}', labelWidth: 18));
      if (result.mismatchesPushed > 0) print(kvRow('Pushed (conflict):', '${result.mismatchesPushed}', labelWidth: 18));
      if (result.mismatchesPulled > 0) print(kvRow('Pulled (conflict):', '${result.mismatchesPulled}', labelWidth: 18));
      if (result.titlesPushed > 0) print(kvRow('Titles pushed:', '${result.titlesPushed}', labelWidth: 18));
      if (result.titlesPulled > 0) print(kvRow('Titles pulled:', '${result.titlesPulled}', labelWidth: 18));
      if (result.failed > 0) print(kvRow('Failed:', '${result.failed}', labelWidth: 18));
      if (result.tasksCreated == 0 && result.worklogsPushed == 0 &&
          result.worklogsPulled == 0 && result.mismatchesPushed == 0 &&
          result.mismatchesPulled == 0 && result.titlesPushed == 0 &&
          result.titlesPulled == 0 && result.failed == 0) {
        print('  No changes applied.');
      }
      print('');
      print(hint('avo task list', 'to see synced tasks'));
      print(hint('avo jira status', 'to see sync status'));
    } on JiraNotConfiguredException {
      print('Jira is not configured.');
      print('');
      print(hint('avo jira init', 'to generate credentials template'));
      print(hint('avo jira setup', 'to configure connection'));
    } on JiraCredentialsNotFoundException catch (e) {
      print('$e');
      print('');
      print(hint('avo jira init', 'to generate credentials template'));
    } on JiraSyncException catch (e) {
      print('Sync failed: $e');
      print('');
      print(hint('avo jira status', 'to check configuration'));
    }
  }

  void _printMismatchDetails(SyncPreview preview) {
    if (preview.worklogMismatches.isNotEmpty) {
      print('');
      print('WORKLOG MISMATCHES:');
      for (final m in preview.worklogMismatches) {
        final localDur = formatDuration(Duration(milliseconds: m.local.durationMs));
        final remoteDur = formatDuration(Duration(milliseconds: m.remote.durationMs));
        print('  [${m.remote.issueKey}] worklog #${m.remote.jiraWorklogId}');
        print('    Local:   $localDur  "${m.local.comment ?? ''}"');
        print('    Remote:  $remoteDur  "${m.remote.comment ?? ''}"');
        final diffs = <String>[];
        if (m.durationDiffers) diffs.add('Duration differs');
        if (m.commentDiffers) diffs.add('Comment differs');
        print('    -> ${diffs.join(', ')}');
      }
    }

    if (preview.titleMismatches.isNotEmpty) {
      print('');
      print('TITLE MISMATCHES:');
      for (final m in preview.titleMismatches) {
        print('  [${m.issueKey}]');
        print('    Local:   "${m.localTask.title}"');
        print('    Remote:  "${m.remoteTitle}"');
      }
    }
  }

  void _printAndPromptMismatches(SyncPreview preview) {
    if (preview.worklogMismatches.isNotEmpty) {
      print('');
      print('WORKLOG MISMATCHES:');
      for (final m in preview.worklogMismatches) {
        final localDur = formatDuration(Duration(milliseconds: m.local.durationMs));
        final remoteDur = formatDuration(Duration(milliseconds: m.remote.durationMs));
        print('  [${m.remote.issueKey}] worklog #${m.remote.jiraWorklogId}');
        print('    Local:   $localDur  "${m.local.comment ?? ''}"');
        print('    Remote:  $remoteDur  "${m.remote.comment ?? ''}"');
        final diffs = <String>[];
        if (m.durationDiffers) diffs.add('Duration differs');
        if (m.commentDiffers) diffs.add('Comment differs');
        print('    -> ${diffs.join(', ')}');
        m.resolution = _promptResolution();
      }
    }

    if (preview.titleMismatches.isNotEmpty) {
      print('');
      print('TITLE MISMATCHES:');
      for (final m in preview.titleMismatches) {
        print('  [${m.issueKey}]');
        print('    Local:   "${m.localTask.title}"');
        print('    Remote:  "${m.remoteTitle}"');
        m.resolution = _promptResolution();
      }
    }
  }

  SyncDirection _promptResolution() {
    stdout.write('    [p]ush local / p[u]ll remote / [s]kip? ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? 's';
    return switch (input) {
      'p' => SyncDirection.push,
      'u' => SyncDirection.pull,
      _ => SyncDirection.skip,
    };
  }
}

class JiraStatusCommand extends JiraSubcommand {
  JiraStatusCommand(super.jiraService);

  @override
  String get name => 'status';

  @override
  String get description => 'Show Jira sync status';

  @override
  String get invocation => 'avo jira status';

  @override
  String? get usageFooter => '\nShows configured profiles, linked tasks, pending worklogs, and last sync time.';

  @override
  Future<void> run() async {
    final statuses = await jiraService.statusAll();

    if (statuses.isEmpty) {
      print('Jira: not configured');
      print('');
      print(hint('avo jira init', 'to generate credentials template'));
      print(hint('avo jira setup', 'to configure connection'));
      return;
    }

    for (var i = 0; i < statuses.length; i++) {
      final status = statuses[i];
      if (i > 0) print('');

      print(formatJiraProfile(
        profileName: status.profileName ?? 'default',
        baseUrl: status.baseUrl ?? '-',
        projectKeys: status.projectKeysList,
      ));
      print(kvRow('Linked tasks:', '${status.linkedTasks}'));
      print(kvRow('Pending logs:', '${status.pendingWorklogs}'));
      if (status.lastSyncAt != null) {
        print(kvRow('Last sync:', formatRelativeDate(status.lastSyncAt!)));
      } else {
        print(kvRow('Last sync:', 'never'));
      }
      if (status.lastSyncError != null) {
        print(kvRow('Last error:', status.lastSyncError!));
      }
    }
    print('');
    print(hint('avo jira sync', 'to sync now'));
    print(hint('avo jira sync --profile X', 'to sync a specific profile'));
  }
}

class JiraSetupCommand extends JiraSubcommand {
  final AvodahPaths paths;

  JiraSetupCommand(super.jiraService, this.paths) {
    argParser.addOption('profile',
        help: 'Profile name from credentials file (uses default if omitted)');
  }

  @override
  String get name => 'setup';

  @override
  String get description => 'Configure Jira connection (interactive or from profile)';

  @override
  String get invocation => 'avo jira setup [--profile name]';

  @override
  String? get usageFooter => '\nInteractive wizard that prompts for URL, credentials, and project keys.\n'
      'Prerequisite: run "avo jira init" first to create the credentials file.';

  @override
  Future<void> run() async {
    final profileArg = argResults?['profile'] as String?;
    await _interactiveSetup(profileArg);
  }

  /// Loads an existing profile from the credentials file, returning null
  /// if the file doesn't exist or the profile isn't found.
  Future<JiraProfile?> _loadExistingProfile(String profileName) async {
    final credFile = File(paths.jiraCredentialsPath);
    if (!await credFile.exists()) return null;
    try {
      final json = jsonDecode(await credFile.readAsString()) as Map<String, dynamic>;
      final config = JiraProfileConfig.fromJson(json);
      return config.getProfile(profileName);
    } catch (_) {
      return null;
    }
  }

  final _rl = TerminalReadline();

  /// Prompts for a value with an optional current default shown in brackets.
  /// Returns the current value if the user presses Enter on a non-empty default.
  String? _prompt(String label, {String? current, bool mask = false}) {
    final display = current != null && current.isNotEmpty
        ? (mask
            ? '****${current.substring((current.length - 4).clamp(0, current.length))}'
            : current)
        : null;
    final suffix = display != null ? ' [$display]' : '';
    final input = _rl.readLine('  $label$suffix: ')?.trim();
    if (input == null || input.isEmpty) return current;
    return input;
  }

  /// Prompts for a required value, re-prompting until non-empty.
  String _promptRequired(String label, {String? current, bool mask = false}) {
    while (true) {
      final result = _prompt(label, current: current, mask: mask);
      if (result != null && result.isNotEmpty) return result;
      print('  $label is required.');
    }
  }

  Future<void> _interactiveSetup(String? presetProfile) async {
    print('Jira Setup Wizard');
    print(separator());
    print('');

    // 1. Determine profile name
    final String key;
    if (presetProfile != null) {
      key = presetProfile;
      print('  Profile: $key');
    } else {
      key = _promptRequired('Profile name', current: 'work');
    }

    // 2. Try to load existing profile for pre-fill
    final existing = await _loadExistingProfile(key);
    if (existing != null) {
      print('  Editing existing profile "$key".');
    }
    print('');

    // 3. Prompt each field (rclone-style: Enter keeps current value)
    final baseUrl =
        _promptRequired('Jira base URL', current: existing?.baseUrl);
    final username =
        _promptRequired('Username/email', current: existing?.username);
    final apiToken =
        _promptRequired('API token', current: existing?.apiToken, mask: true);
    final currentKeys = existing?.projectKeys.isNotEmpty == true
        ? existing!.projectKeys.join(',')
        : null;
    final keysInput =
        _promptRequired('Project keys (comma-separated)', current: currentKeys);
    final projectKeys =
        keysInput.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final defaultCategory = _prompt('Default category (empty=none)',
        current: existing?.defaultCategory);

    // 4. Show summary and confirm
    final maskedToken = apiToken.length > 4
        ? '****${apiToken.substring(apiToken.length - 4)}'
        : '****';
    print('');
    print('  Review:');
    print(kvRow('Profile:', key));
    print(kvRow('URL:', baseUrl));
    print(kvRow('Username:', username));
    print(kvRow('API Token:', maskedToken));
    print(kvRow('Projects:', projectKeys.join(', ')));
    if (defaultCategory != null && defaultCategory.isNotEmpty) {
      print(kvRow('Category:', defaultCategory));
    }
    print('');
    final confirm = _rl.readLine('  Save? (y/n) [y]: ')?.trim().toLowerCase();
    if (confirm == 'n' || confirm == 'no') {
      print('  Setup cancelled.');
      return;
    }

    // 5. Write credentials file
    final credPath = paths.jiraCredentialsPath;
    final credFile = File(credPath);
    Map<String, dynamic> existingJson = {};

    if (await credFile.exists()) {
      try {
        existingJson =
            jsonDecode(await credFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        // Ignore parse errors, start fresh
      }
    }

    final profiles =
        (existingJson['jira_profiles'] as Map<String, dynamic>?) ?? {};
    final profileData = <String, dynamic>{
      'name': key,
      'base_url': baseUrl,
      'username': username,
      'api_token': apiToken,
      'project_keys': projectKeys,
    };
    if (defaultCategory != null && defaultCategory.isNotEmpty) {
      profileData['default_category'] = defaultCategory;
    }
    profiles[key] = profileData;
    existingJson['jira_profiles'] = profiles;
    existingJson['default_profiles'] = {'jira': key};

    await Directory(paths.configDir).create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await credFile.writeAsString('${encoder.convert(existingJson)}\n');

    // 6. Run setup from the newly saved profile
    final config = await jiraService.setup(profileName: key);
    final configKeys = config.jiraProjectKey
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    print('');
    print('Jira configured successfully.');
    print(formatJiraProfile(
      profileName: key,
      baseUrl: baseUrl,
      projectKeys: configKeys,
      username: username,
    ));
    print('');
    print(hintPlain('Credentials saved to: $credPath'));
    print(hint('avo jira sync', 'to pull issues and push worklogs'));
  }
}
