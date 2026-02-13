/// Service layer for timer operations against the SQLite database.
library;

import 'package:avodah_core/avodah_core.dart';

/// Result returned when a timer is stopped.
class StopResult {
  final String worklogId;
  final String? taskId;
  final String taskTitle;
  final Duration elapsed;
  final String? note;

  const StopResult({
    required this.worklogId,
    required this.taskId,
    required this.taskTitle,
    required this.elapsed,
    this.note,
  });

  String get elapsedFormatted {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

/// Wraps all timer-related database operations.
class TimerService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  TimerService({required this.db, required this.clock});

  /// Loads the active timer from the database, or null if none exists.
  Future<TimerDocument?> _loadActiveTimer() async {
    final rows = await (db.select(db.timerEntries)
          ..where((t) => t.id.equals(activeTimerId)))
        .get();

    if (rows.isEmpty) return null;

    final timer = TimerDocument.fromDrift(timer: rows.first, clock: clock);
    if (!timer.isRunning) return null;
    return timer;
  }

  /// Saves a timer document via upsert.
  Future<void> _saveTimer(TimerDocument timer) async {
    await db
        .into(db.timerEntries)
        .insertOnConflictUpdate(timer.toDriftCompanion());
  }

  /// Saves a worklog document via insert.
  Future<void> _saveWorklog(WorklogDocument worklog) async {
    await db.into(db.worklogEntries).insert(worklog.toDriftCompanion());
  }

  /// Saves a task document via upsert.
  Future<void> _saveTask(TaskDocument task) async {
    await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());
  }

  /// Finds an existing task by exact title match, or creates a new one.
  /// If [taskId] is provided, uses it directly without lookup.
  Future<String> _resolveOrCreateTask(String taskTitle, String? taskId) async {
    if (taskId != null) return taskId;

    // Look up by exact title match among non-deleted tasks
    final rows = await db.select(db.tasks).get();
    for (final row in rows) {
      final doc = TaskDocument.fromDrift(task: row, clock: clock);
      if (!doc.isDeleted && doc.title == taskTitle) {
        return doc.id;
      }
    }

    // No match — create a new task
    final task = TaskDocument.create(clock: clock, title: taskTitle);
    await _saveTask(task);
    return task.id;
  }

  /// Starts a new timer. Throws if one is already running.
  ///
  /// If [taskId] is not provided, looks up an existing task by [taskTitle]
  /// or creates a new one. The timer and resulting worklog always use a
  /// real task UUID.
  Future<TimerDocument> start({
    required String taskTitle,
    String? taskId,
    String? note,
  }) async {
    final existing = await _loadActiveTimer();
    if (existing != null) {
      throw TimerAlreadyRunningException(existing);
    }

    final resolvedTaskId = await _resolveOrCreateTask(taskTitle, taskId);

    final timer = TimerDocument.start(
      clock: clock,
      taskTitle: taskTitle,
      taskId: resolvedTaskId,
      note: note,
    );

    await _saveTimer(timer);
    return timer;
  }

  /// Stops the running timer and creates a worklog entry.
  /// Throws if no timer is running.
  ///
  /// If [comment] is provided, it overrides the timer's note as the
  /// worklog comment. Otherwise the timer note is used.
  Future<StopResult> stop({String? comment}) async {
    final timer = await _loadActiveTimer();
    if (timer == null) throw NoTimerRunningException();

    // Capture values before stop() clears them
    final taskId = timer.taskId!;
    final taskTitle = timer.taskTitle;
    final startedAt = timer.startedAt!;
    final note = timer.note;
    final elapsed = timer.elapsed;

    // Stop the timer (clears all fields)
    timer.stop();
    await _saveTimer(timer);

    // Create worklog entry
    final now = DateTime.now();
    final worklog = WorklogDocument.fromTimer(
      clock: clock,
      taskId: taskId,
      start: startedAt,
      end: now,
      comment: comment ?? note,
    );

    await _saveWorklog(worklog);

    return StopResult(
      worklogId: worklog.id,
      taskId: taskId,
      taskTitle: taskTitle,
      elapsed: elapsed,
      note: note,
    );
  }

  /// Pauses the running timer. Throws if no timer is running or already paused.
  Future<TimerDocument> pause() async {
    final timer = await _loadActiveTimer();
    if (timer == null) throw NoTimerRunningException();
    if (timer.isPaused) throw TimerAlreadyPausedException();

    timer.pause();
    await _saveTimer(timer);
    return timer;
  }

  /// Resumes a paused timer. Throws if no timer is running or not paused.
  Future<TimerDocument> resume() async {
    final timer = await _loadActiveTimer();
    if (timer == null) throw NoTimerRunningException();
    if (!timer.isPaused) throw TimerNotPausedException();

    timer.resume();
    await _saveTimer(timer);
    return timer;
  }

  /// Cancels the running timer without creating a worklog.
  /// Throws if no timer is running.
  Future<void> cancel() async {
    final timer = await _loadActiveTimer();
    if (timer == null) throw NoTimerRunningException();

    timer.cancel();
    await _saveTimer(timer);
  }

  /// Returns the active timer, or null if none is running.
  Future<TimerDocument?> status() async {
    return _loadActiveTimer();
  }
}

/// Thrown when trying to start a timer while one is already running.
class TimerAlreadyRunningException implements Exception {
  final TimerDocument timer;
  TimerAlreadyRunningException(this.timer);

  @override
  String toString() => 'Timer already running: "${timer.taskTitle}"';
}

/// Thrown when an operation requires a running timer but none exists.
class NoTimerRunningException implements Exception {
  @override
  String toString() => 'No timer is currently running.';
}

/// Thrown when trying to pause a timer that is already paused.
class TimerAlreadyPausedException implements Exception {
  @override
  String toString() => 'Timer is already paused.';
}

/// Thrown when trying to resume a timer that is not paused.
class TimerNotPausedException implements Exception {
  @override
  String toString() => 'Timer is not paused.';
}
