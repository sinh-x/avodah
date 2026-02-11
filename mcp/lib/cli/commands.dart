/// CLI commands for Avodah.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:avodah_core/avodah_core.dart';

import '../config/paths.dart';
import '../services/jira_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/timer_service.dart';
import '../services/worklog_service.dart';
import 'format.dart';

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
      print('Missing task title.');
      print('');
      print('  Usage: avo start <task title> [-n note]');
      print('  Example: avo start "Fix login bug" -n "auth flow"');
      return;
    }

    final note = argResults?['note'] as String?;

    try {
      final timer = await timerService.start(
        taskTitle: taskTitle,
        note: note,
      );
      print('Timer started: "$taskTitle"');
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
      print(kvRow('Duration:', result.elapsedFormatted));
      print(kvRow('Worklog:', result.worklogId.substring(0, 8)));
      if (result.note != null) print(kvRow('Note:', result.note!));
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
  final JiraService jiraService;

  StatusCommand({
    required this.timerService,
    required this.taskService,
    required this.worklogService,
    required this.projectService,
    required this.jiraService,
  });

  @override
  String get name => 'status';

  @override
  String get description => 'Show dashboard (timer, today, tasks, jira)';

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

    // ── Tasks ──
    print(sectionHeader('TASKS'));
    final tasks = await taskService.list();
    if (tasks.isEmpty) {
      print('  No active tasks.');
      print(hint('avo task add <title>', 'to create one'));
    } else {
      print('  ${tasks.length} active task${tasks.length == 1 ? '' : 's'}');
      final showTasks = tasks.take(5).toList();
      for (final task in showTasks) {
        final check = task.isDone ? 'x' : ' ';
        final id = task.id.substring(0, 8);
        final time = formatDuration(Duration(milliseconds: task.timeSpent));
        print('  [$check] $id  ${task.title}  ($time)');
      }
      if (tasks.length > 5) {
        print(hint('avo task list', 'to see all ${tasks.length} tasks'));
      }
    }
    print(separator());
    print('');

    // ── Jira ──
    print(sectionHeader('JIRA'));
    final jira = await jiraService.status();
    if (!jira.configured) {
      print('  Not configured.');
      print(hint('avo jira init', 'to generate credentials template'));
      print(hint('avo jira setup', 'to configure connection'));
    } else {
      print(kvRow('Project:', jira.jiraProjectKey ?? '-'));
      print(kvRow('URL:', jira.baseUrl ?? '-'));
      print(kvRow('Linked tasks:', '${jira.linkedTasks}'));
      print(kvRow('Pending logs:', '${jira.pendingWorklogs}'));
      if (jira.lastSyncAt != null) {
        print(kvRow('Last sync:', jira.lastSyncAt.toString().substring(0, 16)));
      } else {
        print(kvRow('Last sync:', 'never'));
      }
      if (jira.lastSyncError != null) {
        print(kvRow('Last error:', jira.lastSyncError!));
      }
      if (jira.pendingWorklogs > 0) {
        print(hint('avo jira sync', 'to push pending worklogs'));
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
      print('Missing task title.');
      print('');
      print('  Usage: avo task add <title> [-p project]');
      print('  Example: avo task add "Fix login bug" -p a1b2');
      return;
    }

    final projectId = argResults?['project'] as String?;

    final task = await taskService.add(
      title: title,
      projectId: projectId,
    );
    final shortId = task.id.substring(0, 8);
    print('Created task: "$title"');
    print(kvRow('ID:', shortId));
    print('');
    print(hint('avo start $title', 'to start timing'));
    print(hint('avo task show $shortId', 'to see details'));
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
      print('');
      if (!includeCompleted) {
        print(hint('avo task add <title>', 'to create one'));
        print(hint('avo task list -a', 'to see completed tasks'));
      }
      return;
    }

    final label = includeCompleted ? 'All Tasks' : 'Active Tasks';
    print('$label (${tasks.length}):');
    for (final task in tasks) {
      final check = task.isDone ? 'x' : ' ';
      final id = task.id.substring(0, 8);
      final time = formatDuration(Duration(milliseconds: task.timeSpent));
      print('  [$check] $id  ${task.title}  ($time)');
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
      print('Marked done: "${task.title}"');
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
      final time = formatDuration(Duration(milliseconds: task.timeSpent));
      print('Task: "${task.title}"');
      print(kvRow('ID:', task.id));
      print(kvRow('Status:', status));
      if (task.projectId != null) {
        print(kvRow('Project:', task.projectId!));
      }
      if (task.description != null) {
        print(kvRow('Description:', task.description!));
      }
      print(kvRow('Created:', '${task.createdTimestamp ?? 'unknown'}'));
      print(kvRow('Time spent:', time));
      if (task.timeEstimate > 0) {
        print(kvRow('Estimate:',
            formatDuration(Duration(milliseconds: task.timeEstimate))));
      }
      if (task.dueDay != null) {
        print(kvRow('Due:', '${task.dueDay}'));
      }
      if (task.doneOn != null) {
        print(kvRow('Done on:', '${task.doneOn}'));
      }
      if (task.tagIds.isNotEmpty) {
        print(kvRow('Tags:', task.tagIds.join(', ')));
      }
      if (task.hasIssueLink) {
        print(kvRow('Issue:', '${task.issueId} (${task.issueType?.toValue()})'));
      }
      if (!task.isDone) {
        print('');
        print(hint('avo start ${task.title}', 'to start timing'));
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

  WeekCommand({required this.worklogService});

  @override
  String get name => 'week';

  @override
  String get description => "This week's work summary";

  @override
  Future<void> run() async {
    final summaries = await worklogService.weekSummary();
    final totalMs =
        summaries.fold<int>(0, (sum, d) => sum + d.total.inMilliseconds);
    final total = Duration(milliseconds: totalMs);

    print('This Week:${' ' * 10}${formatDuration(total)}');
    print(separator());

    if (totalMs == 0) {
      print('  No time logged this week.');
      print('');
      print(hint('avo start <task>', 'to begin tracking'));
      return;
    }

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxMs = summaries.fold<int>(
        0,
        (max, d) =>
            d.total.inMilliseconds > max ? d.total.inMilliseconds : max);

    for (var i = 0; i < summaries.length; i++) {
      final day = summaries[i];
      final label = days[i];
      final bar = buildBar(day.total.inMilliseconds, maxMs);
      final dur =
          day.total.inMilliseconds > 0 ? day.formattedDuration : '-';
      print('  $label  $bar  $dur');
    }
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
    addSubcommand(JiraSetupCommand(jiraService));
  }

  @override
  String get name => 'jira';

  @override
  String get description => 'Jira integration';
}

/// Generate Jira credentials template file.
class JiraInitCommand extends Command<void> {
  final AvodahPaths paths;

  JiraInitCommand(this.paths);

  @override
  String get name => 'init';

  @override
  String get description => 'Generate Jira credentials template file';

  @override
  Future<void> run() async {
    final credPath = paths.jiraCredentialsPath;
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

    const template = '''{
  "_comment": "Jira API credentials for Avodah. Get your token at: https://id.atlassian.com/manage-profile/security/api-tokens",
  "email": "your-email@example.com",
  "apiToken": "your-jira-api-token"
}
''';

    await file.writeAsString(template);

    print('Created Jira credentials template:');
    print(kvRow('Path:', credPath));
    print('');
    print('Next steps:');
    print('  1. Edit the file with your Jira email and API token');
    print('  2. Get an API token at:');
    print('     https://id.atlassian.com/manage-profile/security/api-tokens');
    print('  3. Run setup to connect:');
    print('');
    print(hint(
      'avo jira setup -u <url> -p <key> -c $credPath',
      '',
    ));
    print('');
    print('  Example:');
    print('     avo jira setup -u https://company.atlassian.net -p PROJ -c $credPath');
  }
}

class JiraSyncCommand extends JiraSubcommand {
  JiraSyncCommand(super.jiraService);

  @override
  String get name => 'sync';

  @override
  String get description => 'Sync with Jira';

  @override
  Future<void> run() async {
    print('Syncing with Jira...');
    try {
      final result = await jiraService.sync();
      print(kvRow('Pull:', '${result.pull.created} created, ${result.pull.updated} updated'));
      print(kvRow('Push:', '${result.push.pushed} pushed, ${result.push.failed} failed'));
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
}

class JiraStatusCommand extends JiraSubcommand {
  JiraStatusCommand(super.jiraService);

  @override
  String get name => 'status';

  @override
  String get description => 'Show Jira sync status';

  @override
  Future<void> run() async {
    final status = await jiraService.status();

    if (!status.configured) {
      print('Jira: not configured');
      print('');
      print(hint('avo jira init', 'to generate credentials template'));
      print(hint('avo jira setup', 'to configure connection'));
      return;
    }

    print('Jira: ${status.jiraProjectKey}');
    print(kvRow('URL:', status.baseUrl ?? '-'));
    print(kvRow('Linked tasks:', '${status.linkedTasks}'));
    print(kvRow('Pending logs:', '${status.pendingWorklogs}'));
    if (status.lastSyncAt != null) {
      print(kvRow('Last sync:', status.lastSyncAt.toString().substring(0, 16)));
    } else {
      print(kvRow('Last sync:', 'never'));
    }
    if (status.lastSyncError != null) {
      print(kvRow('Last error:', status.lastSyncError!));
    }
    print('');
    print(hint('avo jira sync', 'to sync now'));
  }
}

class JiraSetupCommand extends JiraSubcommand {
  JiraSetupCommand(super.jiraService) {
    argParser
      ..addOption('url',
          abbr: 'u',
          help: 'Jira base URL (e.g., https://company.atlassian.net)')
      ..addOption('project',
          abbr: 'p', help: 'Jira project key (e.g., PROJ)')
      ..addOption('credentials',
          abbr: 'c', help: 'Path to credentials JSON file');
  }

  @override
  String get name => 'setup';

  @override
  String get description => 'Configure Jira connection';

  @override
  Future<void> run() async {
    final url = argResults?['url'] as String?;
    final project = argResults?['project'] as String?;
    final credentials = argResults?['credentials'] as String?;

    if (url == null || project == null || credentials == null) {
      print('Missing required options.');
      print('');
      print('  Usage: avo jira setup -u <url> -p <project> -c <credentials>');
      print('');
      print('  Options:');
      print('    -u  Jira base URL       (e.g., https://company.atlassian.net)');
      print('    -p  Jira project key    (e.g., PROJ)');
      print('    -c  Credentials file    (JSON with email + apiToken)');
      print('');
      print('  Example:');
      print('    avo jira setup -u https://company.atlassian.net -p PROJ -c ~/.config/avodah/jira-credentials.json');
      print('');
      print(hint('avo jira init', 'to generate credentials template'));
      return;
    }

    final config = await jiraService.setup(
      baseUrl: url,
      jiraProjectKey: project,
      credentialsPath: credentials,
    );
    print('Jira configured successfully.');
    print(kvRow('Project:', config.jiraProjectKey));
    print(kvRow('URL:', config.baseUrl));
    print(kvRow('Credentials:', config.credentialsFilePath));
    print('');
    print(hint('avo jira sync', 'to pull issues and push worklogs'));
  }
}
