import 'package:drift/drift.dart';

/// GitHub integration configuration table
/// Stores connection settings and sync preferences for GitHub repositories
class GithubIntegrations extends Table {
  // Core identification
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()(); // Links to a specific project

  // Connection settings
  TextColumn get owner => text()(); // GitHub username or org
  TextColumn get repo => text()(); // Repository name
  TextColumn get accessToken => text()(); // Encrypted personal access token

  // Sync settings
  TextColumn get labelFilter => text().nullable()(); // Only sync issues with label
  BoolColumn get syncEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get syncClosedIssues =>
      boolean().withDefault(const Constant(false))();
  IntColumn get syncIntervalMinutes =>
      integer().withDefault(const Constant(15))();

  // Label mappings (JSON: {githubLabel: localTag})
  TextColumn get labelMappings => text().withDefault(const Constant('{}'))();

  // Status mappings (JSON: {githubState: localStatus})
  TextColumn get statusMappings => text().withDefault(const Constant('{}'))();

  // Milestone mappings (JSON: {milestoneId: projectId})
  TextColumn get milestoneMappings =>
      text().withDefault(const Constant('{}'))();

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
