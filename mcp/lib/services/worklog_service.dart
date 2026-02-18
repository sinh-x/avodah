/// Service layer for worklog operations against the SQLite database.
library;

import 'package:avodah_core/avodah_core.dart';

/// Summary of a single task's logged time.
class TaskTimeSummary {
  final String taskId;
  final String taskTitle;
  final Duration total;

  const TaskTimeSummary({
    required this.taskId,
    required this.taskTitle,
    required this.total,
  });

  String get formattedDuration {
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

/// Summary of a day's logged time.
class DaySummary {
  final String date;
  final Duration total;
  final List<TaskTimeSummary> tasks;

  const DaySummary({
    required this.date,
    required this.total,
    required this.tasks,
  });

  String get formattedDuration {
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

/// Wraps all worklog-related database operations.
class WorklogService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  WorklogService({required this.db, required this.clock});

  /// Saves a worklog document via upsert.
  Future<void> _saveWorklog(WorklogDocument worklog) async {
    await db
        .into(db.worklogEntries)
        .insertOnConflictUpdate(worklog.toDriftCompanion());
  }

  /// Returns today's summary: total duration and per-task breakdown.
  Future<DaySummary> todaySummary() => daySummary(_formatDate(DateTime.now()));

  /// Returns summary for a specific date: total duration and per-task breakdown.
  Future<DaySummary> daySummary(String date) async {
    final rows = await (db.select(db.worklogEntries)
          ..where((w) => w.date.equals(date)))
        .get();

    return _buildDaySummary(date, rows);
  }

  /// Returns summaries for a date range, one DaySummary per day.
  ///
  /// This is the core primitive — [weekSummary] derives from this.
  Future<List<DaySummary>> rangeSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final days = <String>[];
    var current = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(end)) {
      days.add(_formatDate(current));
      current = current.add(const Duration(days: 1));
    }

    final rows = await db.select(db.worklogEntries).get();
    final rangeRows = rows.where((r) => days.contains(r.date)).toList();

    final summaries = <DaySummary>[];
    for (final day in days) {
      final dayRows = rangeRows.where((r) => r.date == day).toList();
      summaries.add(_buildDaySummary(day, dayRows));
    }

    return summaries;
  }

  /// Returns this week's summary (Mon-Sun), one DaySummary per day.
  ///
  /// Convenience wrapper around [rangeSummary].
  Future<List<DaySummary>> weekSummary({DateTime? anchor}) async {
    final now = anchor ?? DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return rangeSummary(from: monday, to: sunday);
  }

  /// Creates a manual worklog entry.
  Future<WorklogDocument> manualLog({
    required String taskId,
    required int durationMinutes,
    String? comment,
  }) async {
    final now = DateTime.now();
    final durationMs = durationMinutes * 60 * 1000;
    final start = now.subtract(Duration(minutes: durationMinutes));

    final worklog = WorklogDocument.create(
      clock: clock,
      taskId: taskId,
      start: start.millisecondsSinceEpoch,
      end: now.millisecondsSinceEpoch,
      comment: comment,
    );

    await _saveWorklog(worklog);
    return worklog;
  }

  /// Creates a worklog with explicit start time and duration.
  Future<WorklogDocument> createWorklog({
    required String taskId,
    required DateTime start,
    required Duration duration,
    String? comment,
  }) async {
    final end = start.add(duration);
    final worklog = WorklogDocument.create(
      clock: clock,
      taskId: taskId,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
      comment: comment,
    );
    await _saveWorklog(worklog);
    return worklog;
  }

  /// Edits an existing worklog's fields.
  ///
  /// Only provided fields are updated. If [start] changes, end is
  /// recalculated from current duration. If [duration] changes, end is
  /// recalculated from current start.
  Future<WorklogDocument> editWorklog(
    String idOrPrefix, {
    DateTime? start,
    Duration? duration,
    String? comment,
  }) async {
    final worklog = await show(idOrPrefix);

    if (start != null) {
      worklog.startMs = start.millisecondsSinceEpoch;
      worklog.date = _formatDate(start);
      final dur = duration ?? Duration(milliseconds: worklog.durationMs);
      final end = start.add(dur);
      worklog.endMs = end.millisecondsSinceEpoch;
      worklog.durationMs = dur.inMilliseconds;
    } else if (duration != null) {
      worklog.durationMs = duration.inMilliseconds;
      final end = worklog.startTime.add(duration);
      worklog.endMs = end.millisecondsSinceEpoch;
    }

    if (comment != null) {
      worklog.comment = comment;
    }

    worklog.updatedMs = DateTime.now().millisecondsSinceEpoch;
    await _saveWorklog(worklog);
    return worklog;
  }

  /// Finds a worklog by exact ID or unique prefix match.
  ///
  /// Throws [WorklogNotFoundException] if no worklog matches.
  /// Throws [AmbiguousWorklogIdException] if multiple worklogs match.
  Future<WorklogDocument> show(String idOrPrefix) async {
    final exactRows = await (db.select(db.worklogEntries)
          ..where((w) => w.id.equals(idOrPrefix)))
        .get();

    if (exactRows.isNotEmpty) {
      return WorklogDocument.fromDrift(worklog: exactRows.first, clock: clock);
    }

    final allRows = await db.select(db.worklogEntries).get();
    final matches =
        allRows.where((row) => row.id.startsWith(idOrPrefix)).toList();

    if (matches.isEmpty) {
      throw WorklogNotFoundException(idOrPrefix);
    }
    if (matches.length > 1) {
      throw AmbiguousWorklogIdException(
        idOrPrefix,
        matches.map((r) => r.id).toList(),
      );
    }

    return WorklogDocument.fromDrift(worklog: matches.first, clock: clock);
  }

  /// Soft-deletes a worklog by exact ID or prefix match.
  ///
  /// Throws [WorklogNotFoundException] if no worklog matches.
  /// Throws [AmbiguousWorklogIdException] if multiple worklogs match.
  Future<WorklogDocument> deleteWorklog(String idOrPrefix) async {
    final worklog = await show(idOrPrefix);
    worklog.delete();
    await _saveWorklog(worklog);
    return worklog;
  }

  /// Returns the most recent worklogs.
  Future<List<WorklogDocument>> listRecent({int limit = 10}) async {
    final rows = await db.select(db.worklogEntries).get();

    final docs = rows
        .map((row) => WorklogDocument.fromDrift(worklog: row, clock: clock))
        .where((doc) => !doc.isDeleted)
        .toList()
      ..sort((a, b) => b.startMs.compareTo(a.startMs));

    return docs.take(limit).toList();
  }

  /// Returns all non-deleted worklogs for a specific task.
  Future<List<WorklogDocument>> listForTask(String taskId) async {
    final rows = await (db.select(db.worklogEntries)
          ..where((w) => w.taskId.equals(taskId)))
        .get();

    return rows
        .map((row) => WorklogDocument.fromDrift(worklog: row, clock: clock))
        .where((doc) => !doc.isDeleted)
        .toList()
      ..sort((a, b) => b.startMs.compareTo(a.startMs));
  }

  /// Returns total logged time per task as a map of taskId → Duration.
  Future<Map<String, Duration>> timeByTask() async {
    final rows = await db.select(db.worklogEntries).get();
    final result = <String, int>{};

    for (final row in rows) {
      final doc = WorklogDocument.fromDrift(worklog: row, clock: clock);
      if (doc.isDeleted) continue;
      result[doc.taskId] = (result[doc.taskId] ?? 0) + doc.durationMs;
    }

    return result.map((k, v) => MapEntry(k, Duration(milliseconds: v)));
  }

  /// Builds a DaySummary from worklog rows.
  DaySummary _buildDaySummary(String date, List<WorklogEntry> rows) {
    final docs = rows
        .map((row) => WorklogDocument.fromDrift(worklog: row, clock: clock))
        .where((doc) => !doc.isDeleted)
        .toList();

    // Group by taskId
    final byTask = <String, List<WorklogDocument>>{};
    for (final doc in docs) {
      byTask.putIfAbsent(doc.taskId, () => []).add(doc);
    }

    final taskSummaries = byTask.entries.map((entry) {
      final totalMs = entry.value.fold<int>(0, (sum, w) => sum + w.durationMs);
      // Use taskId as title — the caller can resolve to a task name
      return TaskTimeSummary(
        taskId: entry.key,
        taskTitle: entry.key,
        total: Duration(milliseconds: totalMs),
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final totalMs = docs.fold<int>(0, (sum, w) => sum + w.durationMs);

    return DaySummary(
      date: date,
      total: Duration(milliseconds: totalMs),
      tasks: taskSummaries,
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// Thrown when no worklog matches the given ID.
class WorklogNotFoundException implements Exception {
  final String id;
  WorklogNotFoundException(this.id);

  @override
  String toString() => 'No worklog found matching "$id".';
}

/// Thrown when multiple worklogs match a prefix.
class AmbiguousWorklogIdException implements Exception {
  final String prefix;
  final List<String> matchingIds;
  AmbiguousWorklogIdException(this.prefix, this.matchingIds);

  @override
  String toString() =>
      'Multiple worklogs match "$prefix": ${matchingIds.map((id) => id.substring(0, 8)).join(', ')}. '
      'Use a longer prefix.';
}
