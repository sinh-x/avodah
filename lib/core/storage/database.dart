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
import 'tables/notes.dart';
import 'tables/task_repeat_cfgs.dart';
import 'tables/jira_integrations.dart';
import 'tables/github_integrations.dart';
import 'tables/issue_links.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Tasks,
  Subtasks,
  Projects,
  Tags,
  WorklogEntries,
  Notes,
  TaskRepeatCfgs,
  JiraIntegrations,
  GithubIntegrations,
  IssueLinks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

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
          await m.createTable(githubIntegrations);
          await m.createTable(issueLinks);
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
