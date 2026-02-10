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

  /// Starts a new timer. Throws if one is already running.
  Future<TimerDocument> start({
    required String taskTitle,
    String? taskId,
    String? note,
  }) async {
    final existing = await _loadActiveTimer();
    if (existing != null) {
      throw TimerAlreadyRunningException(existing);
    }

    final timer = TimerDocument.start(
      clock: clock,
      taskTitle: taskTitle,
      taskId: taskId,
      note: note,
    );

    await _saveTimer(timer);
    return timer;
  }

  /// Stops the running timer and creates a worklog entry.
  /// Throws if no timer is running.
  Future<StopResult> stop() async {
    final timer = await _loadActiveTimer();
    if (timer == null) throw NoTimerRunningException();

    // Capture values before stop() clears them
    final taskId = timer.taskId;
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
      taskId: taskId ?? taskTitle, // Use title as ID if no task ID
      start: startedAt,
      end: now,
      comment: note,
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
