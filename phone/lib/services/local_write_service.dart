/// Local write service for the phone app.
///
/// Writes CRDT operations to the local phone database:
/// - Timer: start / stop (auto-creates worklog on stop)
/// - Task: toggle done/undone
/// - Worklog: create manually
///
/// All writes use CRDT documents to ensure proper per-field timestamps
/// that will merge correctly when pushed to the desktop in Phase 7.
library;

import 'package:avodah_core/avodah_core.dart';
import 'package:flutter/foundation.dart';

/// Result of stopping a timer (includes the generated worklog if any).
class StopTimerResult {
  final int elapsedMs;
  final String? worklogId;

  const StopTimerResult({required this.elapsedMs, this.worklogId});
}

/// Provides local write operations for timer, task, and worklog.
class LocalWriteService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  LocalWriteService({required this.db, required this.clock});

  // ============================================================
  // Timer operations
  // ============================================================

  /// Starts the active timer for [taskId] / [taskTitle].
  ///
  /// If a timer is already running it is silently replaced (last-write-wins).
  Future<void> startTimer({
    required String taskTitle,
    String? taskId,
    String? projectId,
    String? projectTitle,
    String? note,
  }) async {
    final doc = TimerDocument.start(
      clock: clock,
      taskTitle: taskTitle,
      taskId: taskId,
      projectId: projectId,
      projectTitle: projectTitle,
      note: note,
    );
    await db
        .into(db.timerEntries)
        .insertOnConflictUpdate(doc.toDriftCompanion());
    debugPrint('[LocalWrite] Timer started: "$taskTitle" (id: $taskId)');
  }

  /// Stops the active timer and creates a worklog entry for the session.
  ///
  /// Returns a [StopTimerResult] with elapsed time and new worklog ID.
  /// If no timer is running, returns elapsedMs = 0 and no worklog.
  Future<StopTimerResult> stopTimerAndLog({String? comment}) async {
    final rows = await (db.select(db.timerEntries)
          ..where((t) => t.id.equals(activeTimerId)))
        .get();

    if (rows.isEmpty) {
      debugPrint('[LocalWrite] stopTimerAndLog: no active timer found');
      return const StopTimerResult(elapsedMs: 0);
    }

    final timerDoc = TimerDocument.fromDrift(timer: rows.first, clock: clock);

    if (!timerDoc.isRunning) {
      debugPrint('[LocalWrite] stopTimerAndLog: timer is not running');
      return const StopTimerResult(elapsedMs: 0);
    }

    final startedAt = timerDoc.startedAt;
    final taskId = timerDoc.taskId;
    final totalMs = timerDoc.elapsed.inMilliseconds;
    final now = DateTime.now();

    // Stop the timer (resets all fields via CRDT)
    timerDoc.stop();
    await db
        .into(db.timerEntries)
        .insertOnConflictUpdate(timerDoc.toDriftCompanion());

    // Create worklog if we have a valid task and duration
    String? worklogId;
    if (taskId != null && taskId.isNotEmpty && totalMs > 0 && startedAt != null) {
      final wlDoc = WorklogDocument.fromTimer(
        clock: clock,
        taskId: taskId,
        start: startedAt,
        end: now,
        comment: comment,
      );
      await db
          .into(db.worklogEntries)
          .insertOnConflictUpdate(wlDoc.toDriftCompanion());
      worklogId = wlDoc.id;
      debugPrint(
          '[LocalWrite] Worklog created: ${wlDoc.id} (${wlDoc.formattedDuration})');
    }

    debugPrint('[LocalWrite] Timer stopped. Elapsed: ${totalMs}ms');
    return StopTimerResult(elapsedMs: totalMs, worklogId: worklogId);
  }

  // ============================================================
  // Task operations
  // ============================================================

  /// Toggles the done state of a task.
  ///
  /// If the task is done it becomes undone, and vice-versa.
  /// Returns the new isDone state, or null if task not found.
  Future<bool?> toggleTaskDone(String taskId) async {
    final rows = await (db.select(db.tasks)
          ..where((t) => t.id.equals(taskId)))
        .get();

    if (rows.isEmpty) {
      debugPrint('[LocalWrite] toggleTaskDone: task $taskId not found');
      return null;
    }

    final doc = TaskDocument.fromDrift(task: rows.first, clock: clock);
    final newDone = !doc.isDone;
    if (newDone) {
      doc.markDone();
    } else {
      doc.markUndone();
    }

    await db.into(db.tasks).insertOnConflictUpdate(doc.toDriftCompanion());
    debugPrint('[LocalWrite] Task $taskId toggled: isDone=$newDone');
    return newDone;
  }

  // ============================================================
  // Worklog operations
  // ============================================================

  /// Creates a manual worklog entry.
  ///
  /// [start] and [end] are the session boundaries.
  /// Returns the new worklog ID.
  Future<String> createWorklog({
    required String taskId,
    required DateTime start,
    required DateTime end,
    String? comment,
  }) async {
    final doc = WorklogDocument.fromTimer(
      clock: clock,
      taskId: taskId,
      start: start,
      end: end,
      comment: comment,
    );
    await db
        .into(db.worklogEntries)
        .insertOnConflictUpdate(doc.toDriftCompanion());
    debugPrint('[LocalWrite] Manual worklog created: ${doc.id}');
    return doc.id;
  }

  // ============================================================
  // Plan operations
  // ============================================================

  /// Adds a new category-based plan entry for today.
  ///
  /// Returns the new entry ID.
  Future<String> addPlanEntry({
    required String category,
    required int durationMs,
  }) async {
    final today = _today();
    final doc = DailyPlanDocument.create(
      clock: clock,
      category: category,
      day: today,
      durationMs: durationMs,
    );
    await db
        .into(db.dailyPlanEntries)
        .insertOnConflictUpdate(doc.toDriftCompanion());
    debugPrint('[LocalWrite] Plan entry added: $category ${durationMs}ms');
    return doc.id;
  }

  /// Updates the duration of an existing plan entry.
  Future<void> updatePlanEntry({
    required String id,
    required int durationMs,
  }) async {
    final rows = await (db.select(db.dailyPlanEntries)
          ..where((p) => p.id.equals(id)))
        .get();
    if (rows.isEmpty) {
      debugPrint('[LocalWrite] updatePlanEntry: entry $id not found');
      return;
    }
    final doc = DailyPlanDocument.fromDrift(entry: rows.first, clock: clock);
    doc.durationMs = durationMs;
    await db
        .into(db.dailyPlanEntries)
        .insertOnConflictUpdate(doc.toDriftCompanion());
    debugPrint('[LocalWrite] Plan entry $id updated: ${durationMs}ms');
  }

  /// Soft-deletes a plan entry via CRDT.
  Future<void> removePlanEntry(String id) async {
    final rows = await (db.select(db.dailyPlanEntries)
          ..where((p) => p.id.equals(id)))
        .get();
    if (rows.isEmpty) {
      debugPrint('[LocalWrite] removePlanEntry: entry $id not found');
      return;
    }
    final doc = DailyPlanDocument.fromDrift(entry: rows.first, clock: clock);
    doc.delete();
    await db
        .into(db.dailyPlanEntries)
        .insertOnConflictUpdate(doc.toDriftCompanion());
    debugPrint('[LocalWrite] Plan entry $id removed');
  }

  /// Adds a task to today's day plan.
  ///
  /// Returns the new day plan task ID.
  Future<String> addTaskToPlan({
    required String taskId,
    int estimateMs = 0,
  }) async {
    final today = _today();
    final doc = DayPlanTaskDocument.create(
      clock: clock,
      taskId: taskId,
      day: today,
      estimateMs: estimateMs,
    );
    await db
        .into(db.dayPlanTasks)
        .insertOnConflictUpdate(doc.toDriftCompanion());
    debugPrint('[LocalWrite] Task $taskId added to plan for $today');
    return doc.id;
  }

  // ============================================================
  // Delta extraction (for Phase 7 push)
  // ============================================================

  /// Returns the CRDT delta JSON for a timer document (for push in Phase 7).
  Future<Map<String, dynamic>?> getTimerDelta() async {
    final rows = await (db.select(db.timerEntries)
          ..where((t) => t.id.equals(activeTimerId)))
        .get();
    if (rows.isEmpty) return null;
    final doc = TimerDocument.fromDrift(timer: rows.first, clock: clock);
    final json = doc.toJson();
    return {'type': 'timer', 'id': json['id'], 'fields': json['fields']};
  }

  /// Returns the CRDT delta JSON for a task document (for push in Phase 7).
  Future<Map<String, dynamic>?> getTaskDelta(String taskId) async {
    final rows = await (db.select(db.tasks)
          ..where((t) => t.id.equals(taskId)))
        .get();
    if (rows.isEmpty) return null;
    final doc = TaskDocument.fromDrift(task: rows.first, clock: clock);
    final json = doc.toJson();
    return {'type': 'task', 'id': json['id'], 'fields': json['fields']};
  }

  /// Returns the CRDT delta JSON for a worklog document (for push in Phase 7).
  Future<Map<String, dynamic>?> getWorklogDelta(String worklogId) async {
    final rows = await (db.select(db.worklogEntries)
          ..where((t) => t.id.equals(worklogId)))
        .get();
    if (rows.isEmpty) return null;
    final doc = WorklogDocument.fromDrift(worklog: rows.first, clock: clock);
    final json = doc.toJson();
    return {'type': 'worklog', 'id': json['id'], 'fields': json['fields']};
  }

  /// Returns the CRDT delta JSON for a daily plan entry.
  Future<Map<String, dynamic>?> getPlanEntryDelta(String id) async {
    final rows = await (db.select(db.dailyPlanEntries)
          ..where((p) => p.id.equals(id)))
        .get();
    if (rows.isEmpty) return null;
    final doc = DailyPlanDocument.fromDrift(entry: rows.first, clock: clock);
    final json = doc.toJson();
    return {'type': 'dailyPlan', 'id': json['id'], 'fields': json['fields']};
  }

  /// Returns the CRDT delta JSON for a day plan task entry.
  Future<Map<String, dynamic>?> getDayPlanTaskDelta(String id) async {
    final rows = await (db.select(db.dayPlanTasks)
          ..where((p) => p.id.equals(id)))
        .get();
    if (rows.isEmpty) return null;
    final doc = DayPlanTaskDocument.fromDrift(entry: rows.first, clock: clock);
    final json = doc.toJson();
    return {'type': 'dayPlanTask', 'id': json['id'], 'fields': json['fields']};
  }

  // ============================================================
  // Helpers
  // ============================================================

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
