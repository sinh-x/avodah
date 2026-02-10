import 'package:drift/drift.dart';

/// Projects table - aligned with Super Productivity Project model
class Projects extends Table {
  // Core fields
  TextColumn get id => text()();
  TextColumn get title => text()();

  // Basic config
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isHiddenFromMenu => boolean().withDefault(const Constant(false))();
  BoolColumn get isEnableBacklog => boolean().withDefault(const Constant(false))();

  // Task lists
  TextColumn get taskIds => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get backlogTaskIds => text().withDefault(const Constant('[]'))(); // JSON array

  // Theme config (stored as JSON)
  TextColumn get theme => text().withDefault(const Constant('{}'))();

  // Advanced config (worklog export settings, etc.)
  TextColumn get advancedCfg => text().withDefault(const Constant('{}'))();

  // Icon
  TextColumn get icon => text().nullable()();

  // Timestamps
  IntColumn get created => integer()(); // Unix ms
  IntColumn get modified => integer().nullable()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
