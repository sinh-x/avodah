import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/services/plan_service.dart';
import 'package:avodah_mcp/services/sync_snapshot_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late TimerService timerService;
  late TaskService taskService;
  late WorklogService worklogService;
  late PlanService planService;
  late SyncSnapshotService snapshotService;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    timerService = TimerService(db: db, clock: clock);
    taskService = TaskService(db: db, clock: clock);
    worklogService = WorklogService(db: db, clock: clock);
    planService = PlanService(db: db, clock: clock);
    snapshotService = SyncSnapshotService(
      timerService: timerService,
      taskService: taskService,
      worklogService: worklogService,
      planService: planService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  group('buildSnapshot', () {
    test('empty day produces valid structure', () async {
      final snapshot = await snapshotService.buildSnapshot();

      expect(snapshot['version'], equals(1));
      expect(snapshot['day'], equals(_today()));
      expect(snapshot['timestamp'], isA<String>());
      expect(snapshot['timer'], isNull);

      final plan = snapshot['plan'] as Map<String, dynamic>;
      expect(plan['totalPlannedMs'], equals(0));
      expect(plan['totalActualMs'], equals(0));
      expect(plan['categories'], isEmpty);

      expect(snapshot['plannedTasks'], isEmpty);

      final worklog = snapshot['worklogSummary'] as Map<String, dynamic>;
      expect(worklog['totalMs'], equals(0));
      expect(worklog['tasks'], isEmpty);
    });

    test('includes running timer', () async {
      final task = await taskService.add(title: 'Test task');
      await timerService.start(taskTitle: 'Test task', taskId: task.id);

      final snapshot = await snapshotService.buildSnapshot();

      final timer = snapshot['timer'] as Map<String, dynamic>;
      expect(timer['isRunning'], isTrue);
      expect(timer['isPaused'], isFalse);
      expect(timer['taskTitle'], equals('Test task'));
      expect(timer['taskId'], equals(task.id));
      expect(timer['startedAt'], isA<String>());
    });

    test('includes paused timer', () async {
      final task = await taskService.add(title: 'Paused task');
      await timerService.start(taskTitle: 'Paused task', taskId: task.id);
      await timerService.pause();

      final snapshot = await snapshotService.buildSnapshot();

      final timer = snapshot['timer'] as Map<String, dynamic>;
      expect(timer['isRunning'], isTrue);
      expect(timer['isPaused'], isTrue);
    });

    test('includes plan categories with plan-vs-actual', () async {
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000, // 3h
      );
      await planService.add(
        category: 'Learning',
        durationMs: 2 * 60 * 60 * 1000, // 2h
      );

      // Log some work
      final task = await taskService.add(
        title: 'Work task',
        category: 'Working',
      );
      await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 90,
      );

      final snapshot = await snapshotService.buildSnapshot();

      final plan = snapshot['plan'] as Map<String, dynamic>;
      expect(plan['totalPlannedMs'], equals(5 * 60 * 60 * 1000));
      expect(plan['totalPlanned'], equals('5h'));

      final categories =
          (plan['categories'] as List).cast<Map<String, dynamic>>();
      expect(categories.length, equals(2));

      final working =
          categories.firstWhere((c) => c['category'] == 'Working');
      expect(working['plannedMs'], equals(3 * 60 * 60 * 1000));
      expect(working['actualMs'], equals(90 * 60 * 1000));
    });

    test('includes planned tasks with estimates and logged time', () async {
      final task = await taskService.add(
        title: 'Planned task',
        category: 'Working',
      );
      await planService.addTask(
        taskId: task.id,
        estimateMs: 60 * 60 * 1000, // 1h
      );

      // Log 30 minutes
      await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 30,
      );

      final snapshot = await snapshotService.buildSnapshot();

      final tasks =
          (snapshot['plannedTasks'] as List).cast<Map<String, dynamic>>();
      expect(tasks.length, equals(1));

      final pt = tasks.first;
      expect(pt['taskId'], equals(task.id));
      expect(pt['title'], equals('Planned task'));
      expect(pt['category'], equals('Working'));
      expect(pt['estimateMs'], equals(60 * 60 * 1000));
      expect(pt['loggedMs'], equals(30 * 60 * 1000));
      expect(pt['isDone'], isFalse);
      expect(pt['isCancelled'], isFalse);
    });

    test('marks done tasks', () async {
      final task = await taskService.add(title: 'Done task');
      await taskService.done(task.id);
      await planService.addTask(taskId: task.id);

      final snapshot = await snapshotService.buildSnapshot();

      final tasks =
          (snapshot['plannedTasks'] as List).cast<Map<String, dynamic>>();
      expect(tasks.first['isDone'], isTrue);
    });

    test('marks cancelled planned tasks', () async {
      final task = await taskService.add(title: 'Cancel task');
      await planService.addTask(taskId: task.id);
      await planService.cancelTask(taskId: task.id);

      final snapshot = await snapshotService.buildSnapshot();

      final tasks =
          (snapshot['plannedTasks'] as List).cast<Map<String, dynamic>>();
      expect(tasks.first['isCancelled'], isTrue);
    });

    test('includes worklog summary', () async {
      final task = await taskService.add(title: 'Logged task');
      await worklogService.manualLog(taskId: task.id, durationMinutes: 45);
      await worklogService.manualLog(taskId: task.id, durationMinutes: 30);

      final snapshot = await snapshotService.buildSnapshot();

      final worklog = snapshot['worklogSummary'] as Map<String, dynamic>;
      expect(worklog['totalMs'], equals(75 * 60 * 1000));
      expect(worklog['total'], equals('1h 15m'));

      final wlTasks =
          (worklog['tasks'] as List).cast<Map<String, dynamic>>();
      expect(wlTasks.length, equals(1));
      expect(wlTasks.first['title'], equals('Logged task'));
    });

    test('handles deleted/unknown task in planned tasks gracefully',
        () async {
      // Plan a task that doesn't exist
      await planService.addTask(taskId: 'nonexistent-id');

      final snapshot = await snapshotService.buildSnapshot();

      final tasks =
          (snapshot['plannedTasks'] as List).cast<Map<String, dynamic>>();
      expect(tasks.length, equals(1));
      expect(tasks.first['title'], equals('(unknown)'));
    });

    test('non-categorized worklog shows in plan', () async {
      // Task without a category
      final task = await taskService.add(title: 'Uncategorized task');
      await worklogService.manualLog(taskId: task.id, durationMinutes: 20);

      final snapshot = await snapshotService.buildSnapshot();

      final plan = snapshot['plan'] as Map<String, dynamic>;
      expect(plan.containsKey('nonCategorized'), isTrue);
      final nonCat = plan['nonCategorized'] as Map<String, dynamic>;
      expect(nonCat['actualMs'], equals(20 * 60 * 1000));
    });

    test('includes issue ID when task has Jira link', () async {
      final task = await taskService.add(title: 'Jira task');
      // Set issueId directly on the document
      final taskDoc = await taskService.show(task.id);
      taskDoc.issueId = 'PROJ-42';
      await db
          .into(db.tasks)
          .insertOnConflictUpdate(taskDoc.toDriftCompanion());

      await planService.addTask(taskId: task.id);

      final snapshot = await snapshotService.buildSnapshot();

      final tasks =
          (snapshot['plannedTasks'] as List).cast<Map<String, dynamic>>();
      expect(tasks.first['issueId'], equals('PROJ-42'));
    });
  });
}
