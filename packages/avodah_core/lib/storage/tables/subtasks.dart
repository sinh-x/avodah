import 'package:drift/drift.dart';

/// Subtasks table - simple checklist items within a task
/// No time tracking, no complex relationships - just mental breakdown
class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()(); // Parent task
  TextColumn get title => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get order => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();

  // Timestamps
  IntColumn get created => integer()(); // Unix ms
  IntColumn get modified => integer().nullable()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
