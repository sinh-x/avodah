import 'package:drift/drift.dart';

/// Day plan task entries — links tasks to specific days for daily planning.
///
/// Each entry represents a task planned for a specific day, with an optional
/// time estimate. This is separate from the category-based daily plan system.
class DayPlanTasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get day => text()(); // YYYY-MM-DD
  IntColumn get estimateMs => integer().withDefault(const Constant(0))();
  BoolColumn get cancelled => boolean().withDefault(const Constant(false))();
  IntColumn get created => integer()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
