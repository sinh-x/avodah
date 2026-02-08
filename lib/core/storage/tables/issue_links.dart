import 'package:drift/drift.dart';

/// Issue links table - connects local tasks to external issues
/// Supports both Jira and GitHub issue tracking
class IssueLinks extends Table {
  // Core identification
  TextColumn get id => text()();
  TextColumn get taskId => text()(); // Local task ID

  // Integration reference
  TextColumn get integrationId => text()(); // Jira or GitHub integration ID
  TextColumn get issueType =>
      text()(); // 'jira' or 'github' (for quick filtering)

  // External issue identification
  TextColumn get externalIssueId => text()(); // Jira issue ID or GitHub issue number
  TextColumn get externalIssueKey =>
      text().nullable()(); // Jira: "PROJ-123", GitHub: "owner/repo#123"
  TextColumn get externalIssueUrl => text().nullable()(); // Direct link

  // Cached external issue data (for offline display)
  TextColumn get externalTitle => text().nullable()();
  TextColumn get externalStatus => text().nullable()();
  TextColumn get externalPriority => text().nullable()();
  TextColumn get externalAssignee => text().nullable()();

  // Sync metadata
  IntColumn get externalUpdatedAt => integer().nullable()(); // Unix ms
  IntColumn get lastSyncedAt => integer().nullable()(); // Unix ms
  BoolColumn get hasConflict => boolean().withDefault(const Constant(false))();
  TextColumn get conflictData =>
      text().nullable()(); // JSON with conflict details

  // Link direction and behavior
  BoolColumn get pullChanges =>
      boolean().withDefault(const Constant(true))(); // Sync from external
  BoolColumn get pushChanges =>
      boolean().withDefault(const Constant(false))(); // Sync to external

  // Timestamps
  IntColumn get created => integer()(); // Unix ms
  IntColumn get modified => integer().nullable()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
