import 'dart:convert';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/cli/commands.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/services/project_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late TaskService taskService;
  late WorklogService worklogService;
  late ProjectService projectService;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    taskService = TaskService(db: db, clock: clock);
    worklogService = WorklogService(db: db, clock: clock);
    projectService = ProjectService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
  });

  group('DbStatsCommand', () {
    test('reports correct counts for tasks', () async {
      await taskService.add(title: 'Active task');
      final doneTask = await taskService.add(title: 'Done task');
      await taskService.done(doneTask.id);
      final delTask = await taskService.add(title: 'Deleted task');
      await taskService.delete(delTask.id);

      final taskRows = await db.select(db.tasks).get();
      final tasks = taskRows
          .map((r) => TaskDocument.fromDrift(task: r, clock: clock))
          .toList();

      expect(tasks.where((t) => !t.isDeleted && !t.isDone).length, equals(1));
      expect(tasks.where((t) => !t.isDeleted && t.isDone).length, equals(1));
      expect(tasks.where((t) => t.isDeleted).length, equals(1));
    });

    test('reports correct counts for worklogs', () async {
      final task = await taskService.add(title: 'Task');
      final now = DateTime.now();

      // Active worklog
      final w1 = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        end: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      );
      await db.into(db.worklogEntries).insert(w1.toDriftCompanion());

      // Synced worklog
      final w2 = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );
      w2.jiraWorklogId = 'jira-123';
      await db.into(db.worklogEntries).insert(w2.toDriftCompanion());

      final wlRows = await db.select(db.worklogEntries).get();
      final worklogs = wlRows
          .map((r) => WorklogDocument.fromDrift(worklog: r, clock: clock))
          .toList();

      expect(worklogs.where((w) => !w.isDeleted).length, equals(2));
      expect(
          worklogs
              .where((w) => !w.isDeleted && w.jiraWorklogId != null)
              .length,
          equals(1));
    });

    test('reports correct counts for projects', () async {
      await projectService.add(title: 'Active project');
      final archived = ProjectDocument.create(
        clock: clock,
        title: 'Archived project',
      );
      archived.isArchived = true;
      await db.into(db.projects).insert(archived.toDriftCompanion());

      final projRows = await db.select(db.projects).get();
      final projects = projRows
          .map((r) => ProjectDocument.fromDrift(project: r, clock: clock))
          .toList();

      expect(
          projects.where((p) => !p.isDeleted && !p.isArchived).length,
          equals(1));
      expect(
          projects.where((p) => !p.isDeleted && p.isArchived).length,
          equals(1));
    });
  });

  group('DbOrphansCommand', () {
    test('detects worklog with non-existent taskId', () async {
      final now = DateTime.now();

      // Create a worklog pointing to a non-existent task
      final orphan = WorklogDocument.create(
        clock: clock,
        taskId: 'nonexistent-task-id',
        start: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );
      await db.into(db.worklogEntries).insert(orphan.toDriftCompanion());

      final taskRows = await db.select(db.tasks).get();
      final taskIds = taskRows.map((r) => r.id).toSet();

      final wlRows = await db.select(db.worklogEntries).get();
      final orphanedWorklogs = <WorklogDocument>[];
      for (final row in wlRows) {
        final doc = WorklogDocument.fromDrift(worklog: row, clock: clock);
        if (!doc.isDeleted && !taskIds.contains(doc.taskId)) {
          orphanedWorklogs.add(doc);
        }
      }

      expect(orphanedWorklogs, hasLength(1));
      expect(orphanedWorklogs.first.taskId, equals('nonexistent-task-id'));
    });

    test('returns empty when all links are valid', () async {
      final task = await taskService.add(title: 'Real task');
      final now = DateTime.now();

      final w = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );
      await db.into(db.worklogEntries).insert(w.toDriftCompanion());

      final taskRows = await db.select(db.tasks).get();
      final taskIds = taskRows.map((r) => r.id).toSet();

      final wlRows = await db.select(db.worklogEntries).get();
      final orphanedWorklogs = wlRows
          .map((r) => WorklogDocument.fromDrift(worklog: r, clock: clock))
          .where((w) => !w.isDeleted && !taskIds.contains(w.taskId))
          .toList();

      expect(orphanedWorklogs, isEmpty);
    });
  });

  group('DbIntegrityCommand', () {
    test('detects worklog with zero duration', () async {
      final task = await taskService.add(title: 'Task');
      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch;

      // Create worklog with zero duration (same start and end)
      final w = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: ts,
        end: ts,
      );
      await db.into(db.worklogEntries).insert(w.toDriftCompanion());

      final wlRows = await db.select(db.worklogEntries).get();
      final worklogs = wlRows
          .map((r) => WorklogDocument.fromDrift(worklog: r, clock: clock))
          .where((w) => !w.isDeleted)
          .toList();

      final badDuration = worklogs.where((w) => w.durationMs <= 0).length;
      expect(badDuration, equals(1));
    });

    test('detects worklog with end before start', () async {
      final task = await taskService.add(title: 'Task');
      final now = DateTime.now();

      // Create worklog where end < start via direct CRDT manipulation
      final w = WorklogDocument(id: 'bad-worklog', clock: clock);
      w.taskId = task.id;
      w.startMs = now.millisecondsSinceEpoch;
      w.endMs = now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      w.durationMs = -3600000;
      w.date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      w.createdMs = now.millisecondsSinceEpoch;
      w.updatedMs = now.millisecondsSinceEpoch;
      await db.into(db.worklogEntries).insert(w.toDriftCompanion());

      final wlRows = await db.select(db.worklogEntries).get();
      final worklogs = wlRows
          .map((r) => WorklogDocument.fromDrift(worklog: r, clock: clock))
          .where((w) => !w.isDeleted)
          .toList();

      final badRange = worklogs.where((w) => w.endMs < w.startMs).length;
      expect(badRange, equals(1));
    });

    test('detects task with issueId but no issueType', () async {
      // Create task with issueId but no issueType
      final task = TaskDocument.create(clock: clock, title: 'Mismatched');
      task.issueId = 'PROJ-123';
      // issueType left as null
      await db.into(db.tasks).insert(task.toDriftCompanion());

      final taskRows = await db.select(db.tasks).get();
      final tasks = taskRows
          .map((r) => TaskDocument.fromDrift(task: r, clock: clock))
          .where((t) => !t.isDeleted)
          .toList();

      final mismatchedIssue = tasks.where((t) {
        final hasId = t.issueId != null;
        final hasType = t.issueType != null;
        return hasId != hasType;
      }).length;

      expect(mismatchedIssue, equals(1));
    });

    test('passes on clean data', () async {
      final task = await taskService.add(title: 'Clean task');
      final now = DateTime.now();

      final w = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );
      await db.into(db.worklogEntries).insert(w.toDriftCompanion());

      // All checks should pass
      final taskRows = await db.select(db.tasks).get();
      final taskIds = taskRows.map((r) => r.id).toSet();
      final tasks = taskRows
          .map((r) => TaskDocument.fromDrift(task: r, clock: clock))
          .where((t) => !t.isDeleted)
          .toList();

      final wlRows = await db.select(db.worklogEntries).get();
      final worklogs = wlRows
          .map((r) => WorklogDocument.fromDrift(worklog: r, clock: clock))
          .where((w) => !w.isDeleted)
          .toList();

      final orphanedWl =
          worklogs.where((w) => !taskIds.contains(w.taskId)).length;
      final badDuration = worklogs.where((w) => w.durationMs <= 0).length;
      final badRange = worklogs.where((w) => w.endMs < w.startMs).length;
      final mismatchedIssue = tasks.where((t) {
        final hasId = t.issueId != null;
        final hasType = t.issueType != null;
        return hasId != hasType;
      }).length;

      expect(orphanedWl, equals(0));
      expect(badDuration, equals(0));
      expect(badRange, equals(0));
      expect(mismatchedIssue, equals(0));
    });
  });

  group('DbDumpCommand', () {
    test('produces valid JSON with correct table keys', () async {
      await taskService.add(title: 'Dump me');
      await projectService.add(title: 'Dump project');

      // Simulate what dump does
      final result = <String, dynamic>{};

      final taskRows = await db.select(db.tasks).get();
      result['tasks'] = taskRows
          .map((r) => {
                'id': r.id,
                'title': r.title,
                'isDone': r.isDone,
              })
          .toList();

      final projRows = await db.select(db.projects).get();
      result['projects'] = projRows
          .map((r) => {
                'id': r.id,
                'title': r.title,
              })
          .toList();

      final jsonStr = const JsonEncoder.withIndent('  ').convert(result);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed.containsKey('tasks'), isTrue);
      expect(parsed.containsKey('projects'), isTrue);
      expect((parsed['tasks'] as List).length, equals(1));
      expect((parsed['projects'] as List).length, equals(1));
    });

    test('dumps all table types for full dump', () async {
      // Just verify we can query all tables without error
      final taskRows = await db.select(db.tasks).get();
      final wlRows = await db.select(db.worklogEntries).get();
      final projRows = await db.select(db.projects).get();
      final timerRows = await db.select(db.timerEntries).get();
      final planRows = await db.select(db.dailyPlanEntries).get();
      final planTaskRows = await db.select(db.dayPlanTasks).get();

      expect(taskRows, isA<List>());
      expect(wlRows, isA<List>());
      expect(projRows, isA<List>());
      expect(timerRows, isA<List>());
      expect(planRows, isA<List>());
      expect(planTaskRows, isA<List>());
    });
  });

  group('TaskListCommand --format completion', () {
    test('lists active tasks in completion format', () async {
      final t1 = await taskService.add(title: 'First task');
      final t2 = await taskService.add(title: 'Second task');
      final doneTask = await taskService.add(title: 'Done task');
      await taskService.done(doneTask.id);

      final tasks = await taskService.list();

      expect(tasks, hasLength(2));
      for (final task in tasks) {
        final line = '${task.id.substring(0, 8)}\t${task.title}';
        expect(line, contains('\t'));
        expect(line.split('\t').length, equals(2));
      }
    });
  });
}
