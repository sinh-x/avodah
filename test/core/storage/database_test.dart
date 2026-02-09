import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avodah/core/storage/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase', () {
    test('creates all tables on initialization', () async {
      // Verify we can query each table without errors
      final tasks = await db.select(db.tasks).get();
      final subtasks = await db.select(db.subtasks).get();
      final projects = await db.select(db.projects).get();
      final tags = await db.select(db.tags).get();
      final worklogs = await db.select(db.worklogEntries).get();
      final jiraIntegrations = await db.select(db.jiraIntegrations).get();
      // Deferred: notes, taskRepeatCfgs, githubIntegrations

      expect(tasks, isEmpty);
      expect(subtasks, isEmpty);
      expect(projects, isEmpty);
      expect(tags, isEmpty);
      expect(worklogs, isEmpty);
      expect(jiraIntegrations, isEmpty);
    });
  });

  group('Tasks table', () {
    test('inserts and retrieves a task', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.tasks).insert(TasksCompanion.insert(
        id: 'task-1',
        title: 'Test Task',
        created: now,
      ));

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.id, 'task-1');
      expect(tasks.first.title, 'Test Task');
      expect(tasks.first.isDone, false);
      expect(tasks.first.timeSpent, 0);
    });

    test('updates a task', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.tasks).insert(TasksCompanion.insert(
        id: 'task-1',
        title: 'Original Title',
        created: now,
      ));

      await (db.update(db.tasks)..where((t) => t.id.equals('task-1')))
          .write(const TasksCompanion(title: Value('Updated Title')));

      final task = await (db.select(db.tasks)
            ..where((t) => t.id.equals('task-1')))
          .getSingle();

      expect(task.title, 'Updated Title');
    });

    test('deletes a task', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.tasks).insert(TasksCompanion.insert(
        id: 'task-1',
        title: 'To Delete',
        created: now,
      ));

      await (db.delete(db.tasks)..where((t) => t.id.equals('task-1'))).go();

      final tasks = await db.select(db.tasks).get();
      expect(tasks, isEmpty);
    });

    test('filters tasks by project', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.tasks).insert(TasksCompanion.insert(
        id: 'task-1',
        title: 'Project A Task',
        created: now,
        projectId: const Value('project-a'),
      ));

      await db.into(db.tasks).insert(TasksCompanion.insert(
        id: 'task-2',
        title: 'Project B Task',
        created: now,
        projectId: const Value('project-b'),
      ));

      final projectATasks = await (db.select(db.tasks)
            ..where((t) => t.projectId.equals('project-a')))
          .get();

      expect(projectATasks.length, 1);
      expect(projectATasks.first.id, 'task-1');
    });
  });

  group('Subtasks table', () {
    test('inserts subtask linked to task', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.subtasks).insert(SubtasksCompanion.insert(
        id: 'subtask-1',
        taskId: 'task-1',
        title: 'Subtask Item',
        created: now,
      ));

      final subtasks = await (db.select(db.subtasks)
            ..where((s) => s.taskId.equals('task-1')))
          .get();

      expect(subtasks.length, 1);
      expect(subtasks.first.title, 'Subtask Item');
      expect(subtasks.first.isDone, false);
    });
  });

  group('Projects table', () {
    test('inserts and retrieves a project', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.projects).insert(ProjectsCompanion.insert(
        id: 'project-1',
        title: 'My Project',
        created: now,
      ));

      final projects = await db.select(db.projects).get();
      expect(projects.length, 1);
      expect(projects.first.title, 'My Project');
      expect(projects.first.isArchived, false);
    });
  });

  group('Tags table', () {
    test('inserts and retrieves a tag', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.tags).insert(TagsCompanion.insert(
        id: 'tag-1',
        title: 'Urgent',
        created: now,
      ));

      final tags = await db.select(db.tags).get();
      expect(tags.length, 1);
      expect(tags.first.title, 'Urgent');
    });
  });

  group('WorklogEntries table', () {
    test('inserts and retrieves a worklog entry', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final start = now - 3600000; // 1 hour ago

      await db.into(db.worklogEntries).insert(WorklogEntriesCompanion.insert(
        id: 'worklog-1',
        taskId: 'task-1',
        start: start,
        end: now,
        duration: 3600000,
        date: '2026-02-08',
        created: now,
        updated: now,
      ));

      final worklogs = await db.select(db.worklogEntries).get();
      expect(worklogs.length, 1);
      expect(worklogs.first.duration, 3600000);
      expect(worklogs.first.taskId, 'task-1');
    });
  });

  group('Reactive streams', () {
    test('watches task changes', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final stream = db.select(db.tasks).watch();
      final emissions = <List<Task>>[];
      final subscription = stream.listen(emissions.add);

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));

      await db.into(db.tasks).insert(TasksCompanion.insert(
        id: 'task-1',
        title: 'Watched Task',
        created: now,
      ));

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first, isEmpty); // Initial empty
      expect(emissions.last.length, 1); // After insert
    });
  });

  group('JiraIntegrations table', () {
    test('inserts and retrieves jira integration', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.jiraIntegrations).insert(JiraIntegrationsCompanion.insert(
        id: 'jira-1',
        baseUrl: 'https://company.atlassian.net',
        jiraProjectKey: 'PROJ',
        credentialsFilePath: '~/.config/avodah/jira-creds.json',
        created: now,
      ));

      final integrations = await db.select(db.jiraIntegrations).get();
      expect(integrations.length, 1);
      expect(integrations.first.baseUrl, 'https://company.atlassian.net');
      expect(integrations.first.jiraProjectKey, 'PROJ');
      expect(integrations.first.credentialsFilePath, '~/.config/avodah/jira-creds.json');
      expect(integrations.first.syncEnabled, true);
    });

    test('updates sync settings', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.jiraIntegrations).insert(JiraIntegrationsCompanion.insert(
        id: 'jira-1',
        baseUrl: 'https://company.atlassian.net',
        jiraProjectKey: 'PROJ',
        credentialsFilePath: '~/.config/avodah/jira-creds.json',
        created: now,
      ));

      await (db.update(db.jiraIntegrations)..where((j) => j.id.equals('jira-1')))
          .write(const JiraIntegrationsCompanion(
            syncEnabled: Value(false),
            syncIntervalMinutes: Value(30),
          ));

      final integration = await (db.select(db.jiraIntegrations)
            ..where((j) => j.id.equals('jira-1')))
          .getSingle();

      expect(integration.syncEnabled, false);
      expect(integration.syncIntervalMinutes, 30);
    });
  });

  // Deferred: GithubIntegrations table tests (GitHub integration deferred)

}
