/// CLI commands for Avodah.
library;

import 'package:args/command_runner.dart';
import 'package:avodah_core/avodah_core.dart';

import '../services/timer_service.dart';

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

/// Task management command group.
class TaskCommand extends DatabaseCommand {
  TaskCommand(super.db) {
    addSubcommand(TaskAddCommand(db));
    addSubcommand(TaskListCommand(db));
    addSubcommand(TaskDoneCommand(db));
    addSubcommand(TaskShowCommand(db));
  }

  @override
  String get name => 'task';

  @override
  String get description => 'Task management';
}

class TaskAddCommand extends DatabaseCommand {
  TaskAddCommand(super.db);

  @override
  String get name => 'add';

  @override
  String get description => 'Create a new task';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    final title = args.isNotEmpty ? args.join(' ') : null;

    if (title == null) {
      print('Usage: avo task add <title>');
      return;
    }

    // TODO: Implement task creation
    print('Created task: $title');
  }
}

class TaskListCommand extends DatabaseCommand {
  TaskListCommand(super.db);

  @override
  String get name => 'list';

  @override
  String get description => 'List tasks';

  @override
  Future<void> run() async {
    // TODO: Implement task list
    print('Active Tasks:');
    print('  (none)');
  }
}

class TaskDoneCommand extends DatabaseCommand {
  TaskDoneCommand(super.db);

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

    // TODO: Implement mark done
    print('Marked done: $taskId');
  }
}

class TaskShowCommand extends DatabaseCommand {
  TaskShowCommand(super.db);

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

    // TODO: Implement task show
    print('Task: $taskId');
    print('  (not found)');
  }
}

/// Today summary command.
class TodayCommand extends DatabaseCommand {
  TodayCommand(super.db);

  @override
  String get name => 'today';

  @override
  String get description => "Today's work summary";

  @override
  Future<void> run() async {
    // TODO: Implement today summary
    final now = DateTime.now();
    print('Today (${_formatDate(now)}):');
    print('  Total: 0m');
  }
}

/// Week summary command.
class WeekCommand extends DatabaseCommand {
  WeekCommand(super.db);

  @override
  String get name => 'week';

  @override
  String get description => "This week's work summary";

  @override
  Future<void> run() async {
    // TODO: Implement week summary
    print('This Week:');
    print('  Total: 0m');
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

String _formatDate(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}
