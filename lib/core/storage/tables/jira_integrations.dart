import 'package:drift/drift.dart';

/// Jira integration configuration table
/// Stores connection settings and sync preferences for Jira instances
class JiraIntegrations extends Table {
  // Core identification
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()(); // Links to a specific project

  // Connection settings
  TextColumn get baseUrl => text()(); // e.g., https://company.atlassian.net
  TextColumn get email => text()(); // Jira account email
  TextColumn get apiToken => text()(); // Encrypted API token

  // Jira project config
  TextColumn get jiraProjectKey => text()(); // e.g., "PROJ"
  TextColumn get boardId => text().nullable()(); // For sprint tracking

  // Sync settings
  TextColumn get jqlFilter => text().nullable()(); // Custom JQL for issue filtering
  BoolColumn get syncEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get syncSubtasks => boolean().withDefault(const Constant(true))();
  BoolColumn get syncWorklogs => boolean().withDefault(const Constant(false))();
  IntColumn get syncIntervalMinutes =>
      integer().withDefault(const Constant(15))();

  // Field mappings (JSON: {jiraField: localField})
  TextColumn get fieldMappings => text().withDefault(const Constant('{}'))();

  // Status mappings (JSON: {jiraStatus: localStatus})
  TextColumn get statusMappings => text().withDefault(const Constant('{}'))();

  // Last sync tracking
  IntColumn get lastSyncAt => integer().nullable()(); // Unix ms
  TextColumn get lastSyncError => text().nullable()();

  // Timestamps
  IntColumn get created => integer()(); // Unix ms
  IntColumn get modified => integer().nullable()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
