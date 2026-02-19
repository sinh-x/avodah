import 'package:drift/drift.dart';

import 'tables/tasks.dart';
import 'tables/subtasks.dart';
import 'tables/projects.dart';
import 'tables/tags.dart';
import 'tables/worklogs.dart';
import 'tables/jira_integrations.dart';
import 'tables/timer.dart';
import 'tables/daily_plans.dart';
import 'tables/day_plan_tasks.dart';

part 'database.g.dart';

/// Avodah database - shared between Flutter app and MCP server.
///
/// Use [AppDatabase.executor] to create with a custom QueryExecutor.
/// The executor should be provided by the platform:
/// - Flutter: Use NativeDatabase with path_provider
/// - Pure Dart/CLI: Use NativeDatabase with custom path
@DriftDatabase(tables: [
  Tasks,
  Subtasks,
  Projects,
  Tags,
  WorklogEntries,
  JiraIntegrations,
  TimerEntries,
  DailyPlanEntries,
  DayPlanTasks,
])
class AppDatabase extends _$AppDatabase {
  /// Creates a database with the given executor.
  ///
  /// The executor handles opening the SQLite connection.
  /// Use [NativeDatabase] for native platforms.
  AppDatabase(super.e);

  /// Named constructor for clarity.
  AppDatabase.executor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 8;

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
        }
        if (from < 6) {
          // v0.4.0: Add timer table for MCP worklog tracker
          await m.createTable(timerEntries);
        }
        if (from < 7) {
          // v0.5.0: Add category to tasks, create daily plan entries table
          await m.addColumn(tasks, tasks.category);
          await m.createTable(dailyPlanEntries);
        }
        if (from < 8) {
          // Add day plan tasks table for linking tasks to daily plans
          await m.createTable(dayPlanTasks);
        }
      },
    );
  }
}
