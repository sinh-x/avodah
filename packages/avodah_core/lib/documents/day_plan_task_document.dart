/// CRDT-backed Day Plan Task document for linking tasks to specific days.
///
/// Each entry represents a task planned for a specific day with an optional
/// time estimate. Separate from the category-based daily plan system.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../crdt/crdt.dart';
import '../storage/database.dart';

/// Field keys for DayPlanTaskDocument.
class DayPlanTaskFields {
  DayPlanTaskFields._();

  static const String taskId = 'taskId';
  static const String day = 'day';
  static const String estimateMs = 'estimateMs';
  static const String created = 'created';
}

/// A CRDT-backed day plan task entry.
class DayPlanTaskDocument extends CrdtDocument<DayPlanTaskDocument> {
  /// Creates a new day plan task entry with a generated UUID.
  factory DayPlanTaskDocument.create({
    required HybridLogicalClock clock,
    required String taskId,
    required String day,
    int estimateMs = 0,
  }) {
    final doc = DayPlanTaskDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.taskId = taskId;
    doc.day = day;
    doc.estimateMs = estimateMs;
    doc.createdMs = DateTime.now().millisecondsSinceEpoch;
    return doc;
  }

  /// Creates a day plan task document with an existing ID.
  DayPlanTaskDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a day plan task document from existing CRDT state.
  DayPlanTaskDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a day plan task document from a Drift DayPlanTask entity.
  factory DayPlanTaskDocument.fromDrift({
    required DayPlanTask entry,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(entry.crdtState);

    final doc = DayPlanTaskDocument.fromState(
      id: entry.id,
      clock: clock,
      state: state,
    );

    if (state.isEmpty) {
      doc._initializeFromDrift(entry);
    }

    return doc;
  }

  void _initializeFromDrift(DayPlanTask entry) {
    setString(DayPlanTaskFields.taskId, entry.taskId);
    setString(DayPlanTaskFields.day, entry.day);
    setInt(DayPlanTaskFields.estimateMs, entry.estimateMs);
    setInt(DayPlanTaskFields.created, entry.created);
  }

  // ============================================================
  // Fields
  // ============================================================

  String get taskId => getString(DayPlanTaskFields.taskId) ?? '';
  set taskId(String value) => setString(DayPlanTaskFields.taskId, value);

  String get day => getString(DayPlanTaskFields.day) ?? '';
  set day(String value) => setString(DayPlanTaskFields.day, value);

  int get estimateMs => getInt(DayPlanTaskFields.estimateMs) ?? 0;
  set estimateMs(int value) => setInt(DayPlanTaskFields.estimateMs, value);

  int get createdMs => getInt(DayPlanTaskFields.created) ?? 0;
  set createdMs(int value) => setInt(DayPlanTaskFields.created, value);

  // ============================================================
  // Conversion
  // ============================================================

  DayPlanTasksCompanion toDriftCompanion() {
    return DayPlanTasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      day: Value(day),
      estimateMs: Value(estimateMs),
      created: Value(createdMs),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  DayPlanTaskModel toModel() {
    return DayPlanTaskModel(
      id: id,
      taskId: taskId,
      day: day,
      estimate: Duration(milliseconds: estimateMs),
      isDeleted: isDeleted,
    );
  }

  @override
  DayPlanTaskDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return DayPlanTaskDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable day plan task model for UI consumption.
class DayPlanTaskModel {
  final String id;
  final String taskId;
  final String day;
  final Duration estimate;
  final bool isDeleted;

  const DayPlanTaskModel({
    required this.id,
    required this.taskId,
    required this.day,
    required this.estimate,
    required this.isDeleted,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayPlanTaskModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DayPlanTaskModel($id, task=$taskId, $day)';
}
