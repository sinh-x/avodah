import 'package:drift/drift.dart';

/// Daily plan entries for time budgeting by category per day.
class DailyPlanEntries extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()(); // "Learning", "Working", etc.
  TextColumn get day => text()(); // YYYY-MM-DD
  IntColumn get durationMs => integer()(); // Planned duration in ms
  IntColumn get created => integer()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
