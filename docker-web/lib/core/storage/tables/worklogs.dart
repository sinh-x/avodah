import 'package:drift/drift.dart';

/// Worklog entries table - aligned with Super Productivity WorklogEntry model
/// Individual timer sessions / time entries
class WorklogEntries extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();

  // Time tracking (all in Unix milliseconds)
  IntColumn get start => integer()(); // Unix ms
  IntColumn get end => integer()(); // Unix ms
  IntColumn get duration => integer()(); // Duration in ms

  // Date for grouping
  TextColumn get date => text()(); // YYYY-MM-DD

  // Optional comment/note
  TextColumn get comment => text().nullable()();

  // External provider sync
  TextColumn get jiraWorklogId => text().nullable()();

  // Timestamps
  IntColumn get created => integer()(); // Unix ms
  IntColumn get updated => integer()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
