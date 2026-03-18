/// Local database dashboard provider.
///
/// Reads today's data from the local Drift database and assembles a [DaySnapshot].
/// Replaces the WebSocket-based [SyncClient] as the data source for [DashboardScreen]
/// after CRDT sync has populated the phone database from the desktop.
///
/// Usage:
///   1. Call [refresh] after each CRDT pull to update displayed data.
///   2. Call [startPeriodicRefresh] to poll on a fixed interval.
library;

import 'dart:async';

import 'package:avodah_core/avodah_core.dart';
import 'package:flutter/foundation.dart';

import '../models/snapshot.dart';
import 'crdt_sync_service.dart' show SyncConnectionState;

/// Builds [DaySnapshot] from the local Drift database.
class LocalDashboardProvider extends ChangeNotifier {
  final AppDatabase db;
  final HybridLogicalClock clock;

  DaySnapshot? _snapshot;
  Timer? _refreshTimer;

  DaySnapshot? get snapshot => _snapshot;

  /// Reflects the current sync/load state for the connection indicator.
  final connectionState =
      ValueNotifier<SyncConnectionState>(SyncConnectionState.disconnected);

  LocalDashboardProvider({required this.db, required this.clock});

  /// Rebuilds the snapshot from the local DB and notifies listeners.
  Future<void> refresh() async {
    connectionState.value = SyncConnectionState.connecting;
    try {
      final snapshot = await _buildSnapshot();
      _snapshot = snapshot;
      connectionState.value = SyncConnectionState.connected;
      notifyListeners();
    } catch (e) {
      debugPrint('[LocalDashboard] Error building snapshot: $e');
      connectionState.value = _snapshot != null
          ? SyncConnectionState.connected
          : SyncConnectionState.disconnected;
    }
  }

  /// Starts a periodic refresh timer (for live timer updates).
  void startPeriodicRefresh(
      {Duration interval = const Duration(seconds: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => refresh());
  }

  /// Stops the periodic refresh timer.
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    connectionState.dispose();
    super.dispose();
  }

  // ============================================================
  // Snapshot builder
  // ============================================================

  Future<DaySnapshot> _buildSnapshot() async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      _queryActiveTimer(), // 0
      _queryDayPlanTasks(today), // 1
      _queryWorklogs(today), // 2
      _queryPlanEntries(today), // 3
    ]);

    final timerEntry = results[0] as TimerEntry?;
    final dayPlanDocs = results[1] as List<DayPlanTaskDocument>;
    final worklogRows = results[2] as List<WorklogEntry>;
    final planDocs = results[3] as List<DailyPlanDocument>;

    // Worklog totals by task ID
    final loggedByTask = <String, int>{};
    for (final wl in worklogRows) {
      loggedByTask[wl.taskId] = (loggedByTask[wl.taskId] ?? 0) + wl.duration;
    }

    // Task lookup for titles, category, isDone
    final taskIds = dayPlanDocs.map((t) => t.taskId).toSet();
    final taskById = await _fetchTasksById(taskIds);

    // Planned tasks
    final plannedTasks = dayPlanDocs.map((pt) {
      final task = taskById[pt.taskId];
      final loggedMs = loggedByTask[pt.taskId] ?? 0;
      return PlannedTaskSnapshot(
        taskId: pt.taskId,
        title: task?.title ?? '(unknown)',
        issueId: task?.issueId,
        category: task?.category,
        estimateMs: pt.estimateMs,
        estimate: _fmt(Duration(milliseconds: pt.estimateMs)),
        loggedMs: loggedMs,
        logged: _fmt(Duration(milliseconds: loggedMs)),
        isDone: task?.isDone ?? false,
        isCancelled: pt.isCancelled,
      );
    }).toList();

    final plan = _buildPlanSnapshot(planDocs, loggedByTask, taskById);
    final worklogSummary = _buildWorklogSummary(today, worklogRows, taskById);

    // Timer
    TimerSnapshot? timerSnapshot;
    if (timerEntry != null) {
      final doc = TimerDocument.fromDrift(timer: timerEntry, clock: clock);
      if (!doc.isIdle) {
        timerSnapshot = TimerSnapshot(
          isRunning: doc.isRunning,
          isPaused: doc.isPaused,
          taskTitle: doc.taskTitle,
          taskId: doc.taskId,
          elapsedMs: doc.elapsed.inMilliseconds,
          elapsed: _fmt(doc.elapsed),
          startedAt: doc.startedAt,
          note: doc.note,
        );
        timerSnapshot.snapshotTimestamp = now;
      }
    }

    return DaySnapshot(
      version: 1,
      timestamp: now,
      day: today,
      timer: timerSnapshot,
      plan: plan,
      plannedTasks: plannedTasks,
      worklogSummary: worklogSummary,
    );
  }

  // ============================================================
  // Queries
  // ============================================================

  Future<TimerEntry?> _queryActiveTimer() async {
    final rows = await (db.select(db.timerEntries)
          ..where((t) => t.id.equals(activeTimerId)))
        .get();
    return rows.firstOrNull;
  }

  Future<List<DayPlanTaskDocument>> _queryDayPlanTasks(String day) async {
    final rows = await (db.select(db.dayPlanTasks)
          ..where((t) => t.day.equals(day)))
        .get();
    return rows
        .map((r) => DayPlanTaskDocument.fromDrift(entry: r, clock: clock))
        .where((d) => !d.isDeleted)
        .toList();
  }

  Future<List<WorklogEntry>> _queryWorklogs(String day) async {
    return (db.select(db.worklogEntries)
          ..where((w) => w.date.equals(day)))
        .get();
  }

  Future<List<DailyPlanDocument>> _queryPlanEntries(String day) async {
    final rows = await (db.select(db.dailyPlanEntries)
          ..where((p) => p.day.equals(day)))
        .get();
    return rows
        .map((r) => DailyPlanDocument.fromDrift(entry: r, clock: clock))
        .where((d) => !d.isDeleted)
        .toList();
  }

  Future<Map<String, Task>> _fetchTasksById(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await (db.select(db.tasks)
          ..where((t) => t.id.isIn(ids.toList())))
        .get();
    return {for (final t in rows) t.id: t};
  }

  // ============================================================
  // Plan summary
  // ============================================================

  PlanSnapshot _buildPlanSnapshot(
    List<DailyPlanDocument> planDocs,
    Map<String, int> loggedByTask,
    Map<String, Task> taskById,
  ) {
    // Category → planned ms
    final plannedByCategory = <String, int>{};
    for (final doc in planDocs) {
      plannedByCategory[doc.category] =
          (plannedByCategory[doc.category] ?? 0) + doc.durationMs;
    }

    // Category → actual ms (from worklogs via task category)
    final actualByCategory = <String, int>{};
    var nonCategorizedMs = 0;
    for (final entry in loggedByTask.entries) {
      final cat = taskById[entry.key]?.category;
      if (cat != null && cat.isNotEmpty) {
        actualByCategory[cat] = (actualByCategory[cat] ?? 0) + entry.value;
      } else {
        nonCategorizedMs += entry.value;
      }
    }

    final allCategories = {
      ...plannedByCategory.keys,
      ...actualByCategory.keys,
    }.toList()
      ..sort();

    final categories = allCategories.map((cat) {
      final plannedMs = plannedByCategory[cat] ?? 0;
      final actualMs = actualByCategory[cat] ?? 0;
      final deltaMs = actualMs - plannedMs;
      return PlanCategorySnapshot(
        category: cat,
        plannedMs: plannedMs,
        planned: _fmt(Duration(milliseconds: plannedMs)),
        actualMs: actualMs,
        actual: _fmt(Duration(milliseconds: actualMs)),
        deltaMs: deltaMs,
        delta: _fmtDelta(deltaMs),
      );
    }).toList();

    final totalPlannedMs = plannedByCategory.values.fold(0, (a, b) => a + b);
    final totalActualMs = loggedByTask.values.fold(0, (a, b) => a + b);

    return PlanSnapshot(
      totalPlannedMs: totalPlannedMs,
      totalPlanned: _fmt(Duration(milliseconds: totalPlannedMs)),
      totalActualMs: totalActualMs,
      totalActual: _fmt(Duration(milliseconds: totalActualMs)),
      categories: categories,
      nonCategorized: nonCategorizedMs > 0
          ? NonCategorizedSnapshot(
              actualMs: nonCategorizedMs,
              actual: _fmt(Duration(milliseconds: nonCategorizedMs)),
            )
          : null,
    );
  }

  // ============================================================
  // Worklog summary
  // ============================================================

  WorklogSummarySnapshot _buildWorklogSummary(
    String today,
    List<WorklogEntry> worklogs,
    Map<String, Task> taskById,
  ) {
    final totalByTask = <String, int>{};
    for (final wl in worklogs) {
      totalByTask[wl.taskId] = (totalByTask[wl.taskId] ?? 0) + wl.duration;
    }

    final tasks = totalByTask.entries.map((e) {
      return WorklogTaskSnapshot(
        taskId: e.key,
        title: taskById[e.key]?.title ?? e.key,
        totalMs: e.value,
        total: _fmt(Duration(milliseconds: e.value)),
      );
    }).toList()
      ..sort((a, b) => b.totalMs.compareTo(a.totalMs));

    final totalMs = totalByTask.values.fold(0, (a, b) => a + b);
    return WorklogSummarySnapshot(
      date: today,
      totalMs: totalMs,
      total: _fmt(Duration(milliseconds: totalMs)),
      tasks: tasks,
    );
  }

  // ============================================================
  // Formatting helpers
  // ============================================================

  static String _fmt(Duration d) {
    final totalMinutes = d.inMinutes;
    if (totalMinutes == 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  static String _fmtDelta(int deltaMs) {
    if (deltaMs == 0) return '0m';
    final abs = Duration(milliseconds: deltaMs.abs());
    return deltaMs > 0 ? '+${_fmt(abs)}' : '-${_fmt(abs)}';
  }
}
