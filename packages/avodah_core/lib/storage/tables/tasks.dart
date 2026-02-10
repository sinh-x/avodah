import 'package:drift/drift.dart';

/// Tasks table - aligned with Super Productivity Task model
/// Timestamps are stored as Unix milliseconds
class Tasks extends Table {
  // Core fields
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()(); // Task description (supports markdown)
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get created => integer()(); // Unix ms

  // Time tracking
  IntColumn get timeSpent => integer().withDefault(const Constant(0))(); // ms
  IntColumn get timeEstimate => integer().withDefault(const Constant(0))(); // ms
  TextColumn get timeSpentOnDay => text().withDefault(const Constant('{}'))(); // JSON: {date: ms}

  // Due dates
  IntColumn get dueWithTime => integer().nullable()(); // Unix ms
  TextColumn get dueDay => text().nullable()(); // YYYY-MM-DD

  // Relations
  TextColumn get tagIds => text().withDefault(const Constant('[]'))(); // JSON array
  // Note: Subtasks are separate entities, queried by taskId

  // Attachments
  TextColumn get attachments => text().withDefault(const Constant('[]'))(); // JSON array

  // Reminders
  TextColumn get reminderId => text().nullable()();
  IntColumn get remindAt => integer().nullable()(); // Unix ms

  // Completion
  IntColumn get doneOn => integer().nullable()(); // Unix ms
  IntColumn get modified => integer().nullable()(); // Unix ms

  // Repeats
  TextColumn get repeatCfgId => text().nullable()();

  // Issue integration fields
  TextColumn get issueId => text().nullable()();
  TextColumn get issueProviderId => text().nullable()();
  TextColumn get issueType => text().nullable()(); // JIRA, GITHUB, GITLAB, etc.
  BoolColumn get issueWasUpdated => boolean().nullable()();
  IntColumn get issueLastUpdated => integer().nullable()(); // Unix ms
  IntColumn get issueAttachmentNr => integer().nullable()();
  TextColumn get issueTimeTracked => text().nullable()(); // JSON: {date: ms}
  IntColumn get issuePoints => integer().nullable()(); // Story points

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
