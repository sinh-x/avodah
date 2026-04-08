/// CRDT-backed Subtask document for conflict-free synchronization.
///
/// Subtasks are simple checklist items within a task for mental breakdown.
/// They have no time tracking - all time is tracked at the parent Task level.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:avodah_core/crdt/crdt.dart';
import 'package:avodah_core/storage/database.dart';

/// Field keys for SubtaskDocument.
class SubtaskFields {
  SubtaskFields._();

  static const String taskId = 'taskId';
  static const String title = 'title';
  static const String isDone = 'isDone';
  static const String order = 'order';
  static const String notes = 'notes';
  static const String created = 'created';
}

/// A CRDT-backed subtask document.
///
/// All fields are tracked with individual timestamps for fine-grained
/// conflict resolution during P2P sync.
class SubtaskDocument extends CrdtDocument<SubtaskDocument> {
  /// Creates a new subtask document with a generated UUID.
  factory SubtaskDocument.create({
    required HybridLogicalClock clock,
    required String taskId,
    required String title,
    int order = 0,
  }) {
    final doc = SubtaskDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.taskId = taskId;
    doc.title = title;
    doc.isDone = false;
    doc.order = order;
    doc.createdTimestamp = DateTime.now();
    return doc;
  }

  /// Creates a subtask document with an existing ID.
  SubtaskDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a subtask document from existing CRDT state.
  SubtaskDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a subtask document from a Drift Subtask entity.
  factory SubtaskDocument.fromDrift({
    required Subtask subtask,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(subtask.crdtState);

    final doc = SubtaskDocument.fromState(
      id: subtask.id,
      clock: clock,
      state: state,
    );

    // If no CRDT state exists, initialize from Drift fields
    if (state.isEmpty) {
      doc._initializeFromDrift(subtask);
    }

    return doc;
  }

  /// Initializes fields from Drift entity when no CRDT state exists.
  void _initializeFromDrift(Subtask subtask) {
    setString(SubtaskFields.taskId, subtask.taskId);
    setString(SubtaskFields.title, subtask.title);
    setBool(SubtaskFields.isDone, subtask.isDone);
    setInt(SubtaskFields.order, subtask.order);
    setString(SubtaskFields.notes, subtask.notes);
    setInt(SubtaskFields.created, subtask.created);
  }

  // ============================================================
  // Core Fields
  // ============================================================

  /// Parent task ID.
  String get taskId => getString(SubtaskFields.taskId) ?? '';
  set taskId(String value) => setString(SubtaskFields.taskId, value);

  /// Subtask title.
  String get title => getString(SubtaskFields.title) ?? '';
  set title(String value) => setString(SubtaskFields.title, value);

  /// Whether the subtask is completed.
  bool get isDone => getBool(SubtaskFields.isDone) ?? false;
  set isDone(bool value) => setBool(SubtaskFields.isDone, value);

  /// Order/position within the task's subtasks.
  int get order => getInt(SubtaskFields.order) ?? 0;
  set order(int value) => setInt(SubtaskFields.order, value);

  /// Optional notes/description.
  String? get notes => getString(SubtaskFields.notes);
  set notes(String? value) => setString(SubtaskFields.notes, value);

  /// When the subtask was created.
  DateTime? get createdTimestamp {
    final ms = getInt(SubtaskFields.created);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set createdTimestamp(DateTime? value) =>
      setInt(SubtaskFields.created, value?.millisecondsSinceEpoch);

  // ============================================================
  // Actions
  // ============================================================

  /// Marks subtask as done.
  void markDone() {
    isDone = true;
  }

  /// Marks subtask as not done.
  void markUndone() {
    isDone = false;
  }

  /// Toggles the done status.
  void toggle() {
    isDone = !isDone;
  }

  // ============================================================
  // Conversion
  // ============================================================

  /// Converts to a Drift SubtasksCompanion for insert/update.
  SubtasksCompanion toDriftCompanion() {
    return SubtasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      title: Value(title),
      isDone: Value(isDone),
      order: Value(order),
      notes: Value(notes),
      created: Value(createdTimestamp?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch),
      modified: Value(DateTime.now().millisecondsSinceEpoch),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  /// Converts to an immutable Subtask UI model.
  SubtaskModel toModel() {
    return SubtaskModel(
      id: id,
      taskId: taskId,
      title: title,
      isDone: isDone,
      isDeleted: isDeleted,
      order: order,
      notes: notes,
      created: createdTimestamp,
    );
  }

  @override
  SubtaskDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return SubtaskDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable subtask model for UI consumption.
class SubtaskModel {
  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final bool isDeleted;
  final int order;
  final String? notes;
  final DateTime? created;

  const SubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    required this.isDeleted,
    required this.order,
    this.notes,
    this.created,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtaskModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SubtaskModel($id, "$title", done: $isDone)';
}
