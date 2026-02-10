import 'package:drift/drift.dart';

/// Tags table - aligned with Super Productivity Tag model
/// Tags share WorkContextCommon with Projects
class Tags extends Table {
  // Core fields (WorkContextCommon)
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get taskIds => text().withDefault(const Constant('[]'))(); // JSON array

  // Theme config (stored as JSON)
  TextColumn get theme => text().withDefault(const Constant('{}'))();

  // Advanced config (worklog export settings, etc.)
  TextColumn get advancedCfg => text().withDefault(const Constant('{}'))();

  // Timestamps
  IntColumn get created => integer()(); // Unix ms
  IntColumn get modified => integer().nullable()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
