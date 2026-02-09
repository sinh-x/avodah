import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tasks.dart';
import 'tables/subtasks.dart';
import 'tables/projects.dart';
import 'tables/tags.dart';
import 'tables/worklogs.dart';
import 'tables/jira_integrations.dart';
// Deferred: import 'tables/task_repeat_cfgs.dart';
// Deferred: import 'tables/github_integrations.dart';
// Removed: import 'tables/notes.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Tasks,
  Subtasks,
  Projects,
  Tags,
  WorklogEntries,
  JiraIntegrations,
  // Deferred: TaskRepeatCfgs,
  // Deferred: GithubIntegrations,
  // Removed: Notes,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add integration tables
          await m.createTable(jiraIntegrations);
          // Note: githubIntegrations was added in v2 but removed in v5
        }
        if (from < 3) {
          // Add description field to tasks
          await m.addColumn(tasks, tasks.description);
        }
        if (from < 4) {
          // Remove IssueLinks table (1 task = 1 issue, embedded fields sufficient)
          await m.deleteTable('issue_links');
        }
        if (from < 5) {
          // v0.3.0: Linux/NixOS MVP cleanup
          // Drop Notes table (entity removed)
          await m.deleteTable('notes');
          // Drop GithubIntegrations table (deferred)
          await m.deleteTable('github_integrations');
          // Note: Column changes to projects and jira_integrations
          // require table recreation - handled by Drift automatically
          // for new installs. Existing DBs may need manual cleanup.
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'avodah.db'));
    return NativeDatabase.createInBackground(file);
  });
}
