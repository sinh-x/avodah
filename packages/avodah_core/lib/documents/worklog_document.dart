/// CRDT-backed Worklog document for conflict-free synchronization.
///
/// Worklog entries represent individual time tracking sessions.
/// Each entry records start/end times and can be linked to external
/// issue trackers like Jira.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../crdt/crdt.dart';
import '../storage/database.dart';

/// Field keys for WorklogDocument.
class WorklogFields {
  WorklogFields._();

  static const String taskId = 'taskId';
  static const String start = 'start';
  static const String end = 'end';
  static const String duration = 'duration';
  static const String date = 'date';
  static const String comment = 'comment';
  static const String jiraWorklogId = 'jiraWorklogId';
  static const String created = 'created';
  static const String updated = 'updated';
}

/// A CRDT-backed worklog document.
///
/// All fields are tracked with individual timestamps for fine-grained
/// conflict resolution during P2P sync.
class WorklogDocument extends CrdtDocument<WorklogDocument> {
  /// Creates a new worklog document with a generated UUID.
  ///
  /// [start] and [end] are Unix milliseconds.
  factory WorklogDocument.create({
    required HybridLogicalClock clock,
    required String taskId,
    required int start,
    required int end,
    String? comment,
  }) {
    final doc = WorklogDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.taskId = taskId;
    doc.startMs = start;
    doc.endMs = end;
    doc.durationMs = end - start;
    doc.date = _dateFromMs(start);
    doc.comment = comment;
    final now = DateTime.now().millisecondsSinceEpoch;
    doc.createdMs = now;
    doc.updatedMs = now;
    return doc;
  }

  /// Creates a worklog from a timer session.
  factory WorklogDocument.fromTimer({
    required HybridLogicalClock clock,
    required String taskId,
    required DateTime start,
    required DateTime end,
    String? comment,
  }) {
    return WorklogDocument.create(
      clock: clock,
      taskId: taskId,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
      comment: comment,
    );
  }

  /// Creates a worklog document with an existing ID.
  WorklogDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a worklog document from existing CRDT state.
  WorklogDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a worklog document from a Drift WorklogEntry entity.
  factory WorklogDocument.fromDrift({
    required WorklogEntry worklog,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(worklog.crdtState);

    final doc = WorklogDocument.fromState(
      id: worklog.id,
      clock: clock,
      state: state,
    );

    // If no CRDT state exists, initialize from Drift fields
    if (state.isEmpty) {
      doc._initializeFromDrift(worklog);
    }

    return doc;
  }

  /// Initializes fields from Drift entity when no CRDT state exists.
  void _initializeFromDrift(WorklogEntry worklog) {
    setString(WorklogFields.taskId, worklog.taskId);
    setInt(WorklogFields.start, worklog.start);
    setInt(WorklogFields.end, worklog.end);
    setInt(WorklogFields.duration, worklog.duration);
    setString(WorklogFields.date, worklog.date);
    setString(WorklogFields.comment, worklog.comment);
    setString(WorklogFields.jiraWorklogId, worklog.jiraWorklogId);
    setInt(WorklogFields.created, worklog.created);
    setInt(WorklogFields.updated, worklog.updated);
  }

  static String _dateFromMs(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // Core Fields
  // ============================================================

  /// Parent task ID.
  String get taskId => getString(WorklogFields.taskId) ?? '';
  set taskId(String value) => setString(WorklogFields.taskId, value);

  /// Start time (Unix ms).
  int get startMs => getInt(WorklogFields.start) ?? 0;
  set startMs(int value) => setInt(WorklogFields.start, value);

  /// End time (Unix ms).
  int get endMs => getInt(WorklogFields.end) ?? 0;
  set endMs(int value) => setInt(WorklogFields.end, value);

  /// Duration in milliseconds.
  int get durationMs => getInt(WorklogFields.duration) ?? 0;
  set durationMs(int value) => setInt(WorklogFields.duration, value);

  /// Date string (YYYY-MM-DD) for grouping.
  String get date => getString(WorklogFields.date) ?? '';
  set date(String value) => setString(WorklogFields.date, value);

  /// Optional comment/note.
  String? get comment => getString(WorklogFields.comment);
  set comment(String? value) => setString(WorklogFields.comment, value);

  /// Created timestamp (Unix ms).
  int get createdMs => getInt(WorklogFields.created) ?? 0;
  set createdMs(int value) => setInt(WorklogFields.created, value);

  /// Updated timestamp (Unix ms).
  int get updatedMs => getInt(WorklogFields.updated) ?? 0;
  set updatedMs(int value) => setInt(WorklogFields.updated, value);

  // ============================================================
  // DateTime Accessors
  // ============================================================

  /// Start time as DateTime.
  DateTime get startTime => DateTime.fromMillisecondsSinceEpoch(startMs);

  /// End time as DateTime.
  DateTime get endTime => DateTime.fromMillisecondsSinceEpoch(endMs);

  /// Duration as Duration object.
  Duration get duration => Duration(milliseconds: durationMs);

  /// Created time as DateTime.
  DateTime get createdTime => DateTime.fromMillisecondsSinceEpoch(createdMs);

  /// Updated time as DateTime.
  DateTime get updatedTime => DateTime.fromMillisecondsSinceEpoch(updatedMs);

  // ============================================================
  // Jira Integration
  // ============================================================

  /// Jira worklog ID if synced.
  String? get jiraWorklogId => getString(WorklogFields.jiraWorklogId);
  set jiraWorklogId(String? value) =>
      setString(WorklogFields.jiraWorklogId, value);

  /// Whether this worklog is synced to Jira.
  bool get isSyncedToJira => jiraWorklogId != null;

  /// Links this worklog to a Jira worklog.
  void linkToJira(String worklogId) {
    jiraWorklogId = worklogId;
    updatedMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Unlinks from Jira.
  void unlinkFromJira() {
    jiraWorklogId = null;
    updatedMs = DateTime.now().millisecondsSinceEpoch;
  }

  // ============================================================
  // Duration Helpers
  // ============================================================

  /// Returns duration formatted as "Xh Ym".
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Returns duration in hours (decimal).
  double get hoursDecimal => durationMs / (1000 * 60 * 60);

  /// Updates the end time and recalculates duration.
  void updateEnd(DateTime newEnd) {
    endMs = newEnd.millisecondsSinceEpoch;
    durationMs = endMs - startMs;
    updatedMs = DateTime.now().millisecondsSinceEpoch;
  }

  // ============================================================
  // Conversion
  // ============================================================

  /// Converts to a Drift WorklogEntriesCompanion for insert/update.
  WorklogEntriesCompanion toDriftCompanion() {
    return WorklogEntriesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      start: Value(startMs),
      end: Value(endMs),
      duration: Value(durationMs),
      date: Value(date),
      comment: Value(comment),
      jiraWorklogId: Value(jiraWorklogId),
      created: Value(createdMs),
      updated: Value(updatedMs),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  /// Converts to an immutable Worklog UI model.
  WorklogModel toModel() {
    return WorklogModel(
      id: id,
      taskId: taskId,
      start: startTime,
      end: endTime,
      duration: duration,
      date: date,
      comment: comment,
      isSyncedToJira: isSyncedToJira,
      isDeleted: isDeleted,
    );
  }

  @override
  WorklogDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return WorklogDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable worklog model for UI consumption.
class WorklogModel {
  final String id;
  final String taskId;
  final DateTime start;
  final DateTime end;
  final Duration duration;
  final String date;
  final String? comment;
  final bool isSyncedToJira;
  final bool isDeleted;

  const WorklogModel({
    required this.id,
    required this.taskId,
    required this.start,
    required this.end,
    required this.duration,
    required this.date,
    this.comment,
    required this.isSyncedToJira,
    required this.isDeleted,
  });

  /// Returns duration formatted as "Xh Ym".
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorklogModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WorklogModel($id, $date, ${formattedDuration})';
}
