/// CRDT-backed Daily Plan document for category-based time budgeting.
///
/// Each entry represents a planned duration for a category on a given day.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../crdt/crdt.dart';
import '../storage/database.dart';

/// Field keys for DailyPlanDocument.
class DailyPlanFields {
  DailyPlanFields._();

  static const String category = 'category';
  static const String day = 'day';
  static const String durationMs = 'durationMs';
  static const String created = 'created';
}

/// A CRDT-backed daily plan entry.
class DailyPlanDocument extends CrdtDocument<DailyPlanDocument> {
  /// Creates a new daily plan entry with a generated UUID.
  factory DailyPlanDocument.create({
    required HybridLogicalClock clock,
    required String category,
    required String day,
    required int durationMs,
  }) {
    final doc = DailyPlanDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.category = category;
    doc.day = day;
    doc.durationMs = durationMs;
    doc.createdMs = DateTime.now().millisecondsSinceEpoch;
    return doc;
  }

  /// Creates a daily plan document with an existing ID.
  DailyPlanDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a daily plan document from existing CRDT state.
  DailyPlanDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a daily plan document from a Drift DailyPlanEntry entity.
  factory DailyPlanDocument.fromDrift({
    required DailyPlanEntry entry,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(entry.crdtState);

    final doc = DailyPlanDocument.fromState(
      id: entry.id,
      clock: clock,
      state: state,
    );

    if (state.isEmpty) {
      doc._initializeFromDrift(entry);
    }

    return doc;
  }

  void _initializeFromDrift(DailyPlanEntry entry) {
    setString(DailyPlanFields.category, entry.category);
    setString(DailyPlanFields.day, entry.day);
    setInt(DailyPlanFields.durationMs, entry.durationMs);
    setInt(DailyPlanFields.created, entry.created);
  }

  // ============================================================
  // Fields
  // ============================================================

  String get category => getString(DailyPlanFields.category) ?? '';
  set category(String value) => setString(DailyPlanFields.category, value);

  String get day => getString(DailyPlanFields.day) ?? '';
  set day(String value) => setString(DailyPlanFields.day, value);

  int get durationMs => getInt(DailyPlanFields.durationMs) ?? 0;
  set durationMs(int value) => setInt(DailyPlanFields.durationMs, value);

  int get createdMs => getInt(DailyPlanFields.created) ?? 0;
  set createdMs(int value) => setInt(DailyPlanFields.created, value);

  // ============================================================
  // Conversion
  // ============================================================

  DailyPlanEntriesCompanion toDriftCompanion() {
    return DailyPlanEntriesCompanion(
      id: Value(id),
      category: Value(category),
      day: Value(day),
      durationMs: Value(durationMs),
      created: Value(createdMs),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  DailyPlanModel toModel() {
    return DailyPlanModel(
      id: id,
      category: category,
      day: day,
      duration: Duration(milliseconds: durationMs),
      isDeleted: isDeleted,
    );
  }

  @override
  DailyPlanDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return DailyPlanDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable daily plan model for UI consumption.
class DailyPlanModel {
  final String id;
  final String category;
  final String day;
  final Duration duration;
  final bool isDeleted;

  const DailyPlanModel({
    required this.id,
    required this.category,
    required this.day,
    required this.duration,
    required this.isDeleted,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyPlanModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DailyPlanModel($id, $category, $day)';
}
