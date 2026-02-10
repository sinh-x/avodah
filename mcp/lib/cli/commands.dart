/// CLI commands for Avodah.
library;

import 'package:args/command_runner.dart';
import 'package:avodah_core/avodah_core.dart';

import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/timer_service.dart';
import '../services/worklog_service.dart';

/// Base class for commands that need database access.
abstract class DatabaseCommand extends Command<void> {
  final AppDatabase db;
  DatabaseCommand(this.db);
}

/// Base class for timer commands that need the TimerService.
abstract class TimerCommand extends Command<void> {
  final TimerService timerService;
  TimerCommand(this.timerService);
}

/// Start timer command.
class StartCommand extends TimerCommand {
  StartCommand(super.timerService) {
    argParser.addOption('note', abbr: 'n', help: 'Note about current work');
  }

  @override
  String get name => 'start';

  @override
  String get description => 'Start timer on a task';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskTitle = args.isNotEmpty ? args.join(' ') : null;

    if (taskTitle == null) {
      print('Usage: avo start <task title>');
      return;
    }

    final note = argResults?['note'] as String?;

    try {
      final timer = await timerService.start(
        taskTitle: taskTitle,
        note: note,
      );
      print('Timer started: $taskTitle');
      print('  Started at: ${_formatTime(timer.startedAt!)}');
      if (note != null) print('  Note: $note');
    } on TimerAlreadyRunningException catch (e) {
      print('Timer already running: "${e.timer.taskTitle}"');
      print('  Elapsed: ${e.timer.elapsedFormatted}');
      print('  Stop or cancel the current timer first.');
    }
  }
}

/// Stop timer command.
class StopCommand extends TimerCommand {
  StopCommand(super.timerService);

  @override
  String get name => 'stop';

  @override
  String get description => 'Stop timer and log time';

  @override
  Future<void> run() async {
    try {
      final result = await timerService.stop();
      print('Timer stopped: "${result.taskTitle}"');
      print('  Duration: ${result.elapsedFormatted}');
      print('  Worklog: ${result.worklogId.substring(0, 8)}');
      if (result.note != null) print('  Note: ${result.note}');
    } on NoTimerRunningException {
      print('No timer running.');
    }
  }
}

/// Timer status command.
class StatusCommand extends TimerCommand {
  StatusCommand(super.timerService);

  @override
  String get name => 'status';

  @override
  String get description => 'Show timer status';

  @override
  Future<void> run() async {
    final timer = await timerService.status();

    if (timer == null) {
      print('No timer running.');
      return;
    }

    final state = timer.isPaused ? 'paused' : 'running';
    print('Timer ($state): "${timer.taskTitle}"');
    print('  Elapsed: ${timer.elapsedFormatted}');
    print('  Started: ${_formatTime(timer.startedAt!)}');
    if (timer.note != null) print('  Note: ${timer.note}');
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
  Future<void> run() async {
    try {
      final timer = await timerService.pause();
      print('Timer paused: "${timer.taskTitle}"');
      print('  Elapsed: ${timer.elapsedFormatted}');
    } on NoTimerRunningException {
      print('No timer running.');
    } on TimerAlreadyPausedException {
      print('Timer is already paused.');
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
  Future<void> run() async {
    try {
      final timer = await timerService.resume();
      print('Timer resumed: "${timer.taskTitle}"');
      print('  Elapsed: ${timer.elapsedFormatted}');
    } on NoTimerRunningException {
      print('No timer running.');
    } on TimerNotPausedException {
      print('Timer is not paused.');
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
  Future<void> run() async {
    try {
      await timerService.cancel();
      print('Timer cancelled. No time logged.');
    } on NoTimerRunningException {
      print('No timer running.');
    }
  }
}

/// Base class for task commands that need the TaskService.
abstract class TaskSubcommand extends Command<void> {
  final TaskService taskService;
  TaskSubcommand(this.taskService);
}

/// Task management command group.
class TaskCommand extends Command<void> {
  TaskCommand(TaskService taskService) {
    addSubcommand(TaskAddCommand(taskService));
    addSubcommand(TaskListCommand(taskService));
    addSubcommand(TaskDoneCommand(taskService));
    addSubcommand(TaskShowCommand(taskService));
  }

  @override
  String get name => 'task';

  @override
  String get description => 'Task management';
}

class TaskAddCommand extends TaskSubcommand {
  TaskAddCommand(super.taskService) {
    argParser.addOption('project', abbr: 'p', help: 'Project ID');
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Create a new task';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final title = args.isNotEmpty ? args.join(' ') : null;

    if (title == null) {
      print('Usage: avo task add <title> [-p project]');
      return;
    }

    final projectId = argResults?['project'] as String?;

    final task = await taskService.add(
      title: title,
      projectId: projectId,
    );
    print('Created task: $title');
    print('  ID: ${task.id.substring(0, 8)}');
  }
}

class TaskListCommand extends TaskSubcommand {
  TaskListCommand(super.taskService) {
    argParser.addFlag('all', abbr: 'a', help: 'Include completed tasks');
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List tasks';

  @override
  Future<void> run() async {
    final includeCompleted = argResults?['all'] as bool? ?? false;
    final tasks = await taskService.list(includeCompleted: includeCompleted);

    if (tasks.isEmpty) {
      print(includeCompleted ? 'No tasks.' : 'No active tasks.');
      return;
    }

    final label = includeCompleted ? 'All Tasks' : 'Active Tasks';
    print('$label:');
    for (final task in tasks) {
      final check = task.isDone ? 'x' : ' ';
      final id = task.id.substring(0, 8);
      final time = _formatDuration(Duration(milliseconds: task.timeSpent));
      print('  [$check] $id  ${task.title}  ($time)');
    }
  }
}

class TaskDoneCommand extends TaskSubcommand {
  TaskDoneCommand(super.taskService);

  @override
  String get name => 'done';

  @override
  String get description => 'Mark task as done';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskId = args.isNotEmpty ? args.first : null;

    if (taskId == null) {
      print('Usage: avo task done <id>');
      return;
    }

    try {
      final task = await taskService.done(taskId);
      print('Marked done: "${task.title}"');
      print('  ID: ${task.id.substring(0, 8)}');
    } on TaskNotFoundException catch (e) {
      print(e);
    } on AmbiguousTaskIdException catch (e) {
      print(e);
    } on TaskAlreadyDoneException catch (e) {
      print(e);
    }
  }
}

class TaskShowCommand extends TaskSubcommand {
  TaskShowCommand(super.taskService);

  @override
  String get name => 'show';

  @override
  String get description => 'Show task details';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final taskId = args.isNotEmpty ? args.first : null;

    if (taskId == null) {
      print('Usage: avo task show <id>');
      return;
    }

    try {
      final task = await taskService.show(taskId);
      final status = task.isDone ? 'Done' : (task.isDeleted ? 'Deleted' : 'Active');
      print('Task: ${task.title}');
      print('  ID:       ${task.id}');
      print('  Status:   $status');
      if (task.projectId != null) {
        print('  Project:  ${task.projectId}');
      }
      if (task.description != null) {
        print('  Desc:     ${task.description}');
      }
      print('  Created:  ${task.createdTimestamp ?? 'unknown'}');
      print('  Spent:    ${_formatDuration(Duration(milliseconds: task.timeSpent))}');
      if (task.timeEstimate > 0) {
        print('  Estimate: ${_formatDuration(Duration(milliseconds: task.timeEstimate))}');
      }
      if (task.dueDay != null) {
        print('  Due:      ${task.dueDay}');
      }
      if (task.doneOn != null) {
        print('  Done on:  ${task.doneOn}');
      }
      if (task.tagIds.isNotEmpty) {
        print('  Tags:     ${task.tagIds.join(', ')}');
      }
      if (task.hasIssueLink) {
        print('  Issue:    ${task.issueId} (${task.issueType?.toValue()})');
      }
    } on TaskNotFoundException catch (e) {
      print(e);
    } on AmbiguousTaskIdException catch (e) {
      print(e);
    }
  }
}

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
  Future<void> run() async {
    final summary = await worklogService.todaySummary();
    final now = DateTime.now();

    print('Today (${_formatDate(now)}):      ${summary.formattedDuration}');

    if (summary.tasks.isEmpty) {
      print('  No time logged today.');
      return;
    }

    // Resolve task titles
    for (final task in summary.tasks) {
      final title = await _resolveTaskTitle(task.taskId);
      final pad = '  $title'.padRight(30);
      print('$pad ${task.formattedDuration}');
    }
  }

  Future<String> _resolveTaskTitle(String taskId) async {
    try {
      final task = await taskService.show(taskId);
      final issueTag = task.issueId != null ? ' [${task.issueId}]' : '';
      return '${task.title}$issueTag';
    } catch (_) {
      // taskId might be the title itself (from timer without linked task)
      return taskId;
    }
  }
}

/// Week summary command.
class WeekCommand extends Command<void> {
  final WorklogService worklogService;

  WeekCommand({required this.worklogService});

  @override
  String get name => 'week';

  @override
  String get description => "This week's work summary";

  @override
  Future<void> run() async {
    final summaries = await worklogService.weekSummary();
    final totalMs = summaries.fold<int>(
        0, (sum, d) => sum + d.total.inMilliseconds);
    final total = Duration(milliseconds: totalMs);

    print('This Week:      ${_formatDuration(total)}');
    print('');

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxMs = summaries.fold<int>(
        0, (max, d) => d.total.inMilliseconds > max ? d.total.inMilliseconds : max);

    for (var i = 0; i < summaries.length; i++) {
      final day = summaries[i];
      final label = days[i];
      final bar = maxMs > 0
          ? _buildBar(day.total.inMilliseconds, maxMs)
          : '';
      final dur = day.total.inMilliseconds > 0 ? day.formattedDuration : '-';
      print('  $label  $bar  $dur');
    }
  }

  String _buildBar(int value, int max) {
    const width = 20;
    final filled = max > 0 ? (value * width ~/ max) : 0;
    return '${'#' * filled}${'.' * (width - filled)}';
  }
}

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
  }

  @override
  String get name => 'project';

  @override
  String get description => 'Project management';
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
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final title = args.isNotEmpty ? args.join(' ') : null;

    if (title == null) {
      print('Usage: avo project add <title> [-i icon]');
      return;
    }

    final icon = argResults?['icon'] as String?;

    final project = await projectService.add(
      title: title,
      icon: icon,
    );
    print('Created project: $title');
    print('  ID: ${project.id.substring(0, 8)}');
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
  Future<void> run() async {
    final includeArchived = argResults?['all'] as bool? ?? false;
    final projects =
        await projectService.list(includeArchived: includeArchived);

    if (projects.isEmpty) {
      print(includeArchived ? 'No projects.' : 'No active projects.');
      return;
    }

    final label = includeArchived ? 'All Projects' : 'Projects';
    print('$label:');
    for (final project in projects) {
      final id = project.id.substring(0, 8);
      final archived = project.isArchived ? ' [archived]' : '';
      final count = await projectService.taskCount(project.id);
      final iconStr = project.icon != null ? '${project.icon} ' : '';
      print('  $id  $iconStr${project.title}  ($count tasks)$archived');
    }
  }
}

class ProjectShowCommand extends ProjectSubcommand {
  ProjectShowCommand(super.projectService);

  @override
  String get name => 'show';

  @override
  String get description => 'Show project details';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final projectId = args.isNotEmpty ? args.first : null;

    if (projectId == null) {
      print('Usage: avo project show <id>');
      return;
    }

    try {
      final project = await projectService.show(projectId);
      final count = await projectService.taskCount(project.id);
      print('Project: ${project.title}');
      print('  ID:       ${project.id}');
      if (project.icon != null) {
        print('  Icon:     ${project.icon}');
      }
      print('  Tasks:    $count active');
      print('  Archived: ${project.isArchived}');
      print('  Created:  ${project.createdTimestamp ?? 'unknown'}');
    } on ProjectNotFoundException catch (e) {
      print(e);
    } on AmbiguousProjectIdException catch (e) {
      print(e);
    }
  }
}

/// Jira sync command group.
class JiraCommand extends DatabaseCommand {
  JiraCommand(super.db) {
    addSubcommand(JiraSyncCommand(db));
    addSubcommand(JiraStatusCommand(db));
    addSubcommand(JiraSetupCommand(db));
  }

  @override
  String get name => 'jira';

  @override
  String get description => 'Jira integration';
}

class JiraSyncCommand extends DatabaseCommand {
  JiraSyncCommand(super.db);

  @override
  String get name => 'sync';

  @override
  String get description => 'Sync with Jira';

  @override
  Future<void> run() async {
    // TODO: Implement Jira sync
    print('Syncing with Jira...');
    print('  (not configured)');
  }
}

class JiraStatusCommand extends DatabaseCommand {
  JiraStatusCommand(super.db);

  @override
  String get name => 'status';

  @override
  String get description => 'Show Jira sync status';

  @override
  Future<void> run() async {
    // TODO: Implement Jira status
    print('Jira: not configured');
    print('  Run "avo jira setup" to configure.');
  }
}

class JiraSetupCommand extends DatabaseCommand {
  JiraSetupCommand(super.db);

  @override
  String get name => 'setup';

  @override
  String get description => 'Configure Jira connection';

  @override
  Future<void> run() async {
    // TODO: Implement Jira setup
    print('Jira Setup');
    print('  (not implemented yet)');
  }
}

// ============================================================
// Helpers
// ============================================================

String _formatTime(DateTime dt) => dt.toString().substring(11, 16);

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

String _formatDate(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}
