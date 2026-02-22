import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/services/plan_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late PlanService planService;
  late TaskService taskService;
  late WorklogService worklogService;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    planService = PlanService(db: db, clock: clock);
    taskService = TaskService(db: db, clock: clock);
    worklogService = WorklogService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
  });

  group('add', () {
    test('creates plan entry and returns it', () async {
      final plan = await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000, // 3h
        day: '2026-02-13',
      );

      expect(plan.category, equals('Working'));
      expect(plan.durationMs, equals(3 * 60 * 60 * 1000));
      expect(plan.day, equals('2026-02-13'));
    });

    test('defaults to today when day not provided', () async {
      final plan = await planService.add(
        category: 'Learning',
        durationMs: 2 * 60 * 60 * 1000,
      );

      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(plan.day, equals(today));
    });

    test('throws DuplicatePlanEntryException on same category+day', () async {
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000,
        day: '2026-02-13',
      );

      expect(
        () => planService.add(
          category: 'Working',
          durationMs: 1 * 60 * 60 * 1000,
          day: '2026-02-13',
        ),
        throwsA(isA<DuplicatePlanEntryException>()),
      );
    });

    test('allows same category on different days', () async {
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000,
        day: '2026-02-13',
      );

      final plan2 = await planService.add(
        category: 'Working',
        durationMs: 4 * 60 * 60 * 1000,
        day: '2026-02-14',
      );

      expect(plan2.day, equals('2026-02-14'));
    });
  });

  group('remove', () {
    test('soft-deletes plan entry', () async {
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000,
        day: '2026-02-13',
      );

      await planService.remove(category: 'Working', day: '2026-02-13');

      final entries = await planService.listForDay(day: '2026-02-13');
      expect(entries, isEmpty);
    });

    test('throws PlanEntryNotFoundException when not found', () async {
      expect(
        () => planService.remove(category: 'Working', day: '2026-02-13'),
        throwsA(isA<PlanEntryNotFoundException>()),
      );
    });

    test('allows re-add after remove', () async {
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000,
        day: '2026-02-13',
      );
      await planService.remove(category: 'Working', day: '2026-02-13');

      final plan = await planService.add(
        category: 'Working',
        durationMs: 4 * 60 * 60 * 1000,
        day: '2026-02-13',
      );

      expect(plan.durationMs, equals(4 * 60 * 60 * 1000));
    });
  });

  group('listForDay', () {
    test('returns entries for specific day', () async {
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000,
        day: '2026-02-13',
      );
      await planService.add(
        category: 'Learning',
        durationMs: 2 * 60 * 60 * 1000,
        day: '2026-02-13',
      );
      await planService.add(
        category: 'Working',
        durationMs: 4 * 60 * 60 * 1000,
        day: '2026-02-14',
      );

      final entries = await planService.listForDay(day: '2026-02-13');

      expect(entries, hasLength(2));
    });

    test('excludes deleted entries', () async {
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000,
        day: '2026-02-13',
      );
      await planService.add(
        category: 'Learning',
        durationMs: 2 * 60 * 60 * 1000,
        day: '2026-02-13',
      );
      await planService.remove(category: 'Working', day: '2026-02-13');

      final entries = await planService.listForDay(day: '2026-02-13');

      expect(entries, hasLength(1));
      expect(entries.first.category, equals('Learning'));
    });
  });

  group('summary', () {
    test('computes plan-vs-actual', () async {
      // Create a task with category
      final task = await taskService.add(
        title: 'Work task',
        category: 'Working',
      );

      // Log time on it
      await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 90, // 1h30m
      );

      // Create a plan
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000, // 3h planned
      );

      final summary = await planService.summary();

      expect(summary.categories, hasLength(1));
      final cat = summary.categories.first;
      expect(cat.category, equals('Working'));
      expect(cat.planned.inHours, equals(3));
      expect(cat.actual.inMinutes, equals(90));
      expect(cat.delta.inMinutes, equals(90 - 180)); // -90m
    });

    test('includes non-categorized bucket', () async {
      // Create a task without category
      final task = await taskService.add(title: 'Uncategorized task');

      // Log time on it
      await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 30,
      );

      final summary = await planService.summary();

      expect(summary.nonCategorized, isNotNull);
      expect(summary.nonCategorized!.actual.inMinutes, equals(30));
    });

    test('returns zero actual when no worklogs', () async {
      await planService.add(
        category: 'Learning',
        durationMs: 2 * 60 * 60 * 1000,
      );

      final summary = await planService.summary();

      expect(summary.categories, hasLength(1));
      expect(summary.categories.first.actual, equals(Duration.zero));
    });

    test('returns empty when no plan', () async {
      final summary = await planService.summary(day: '2026-02-13');

      expect(summary.categories, isEmpty);
      expect(summary.nonCategorized, isNull);
    });

    test('supports specific day parameter', () async {
      final task = await taskService.add(
        title: 'Work task',
        category: 'Working',
      );

      // Log on specific date
      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 15, 9, 0),
        duration: const Duration(hours: 2),
      );

      await planService.add(
        category: 'Working',
        durationMs: 4 * 60 * 60 * 1000,
        day: '2026-02-15',
      );

      final summary = await planService.summary(day: '2026-02-15');

      expect(summary.categories, hasLength(1));
      expect(summary.categories.first.planned.inHours, equals(4));
      expect(summary.categories.first.actual.inHours, equals(2));
    });

    test('shows unplanned categories with actual time', () async {
      // Create a task with a category that has no plan
      final task = await taskService.add(
        title: 'Side work',
        category: 'Side-project',
      );

      await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 45,
      );

      final summary = await planService.summary();

      // Should appear as a category with zero planned
      final sideProject = summary.categories.where(
          (c) => c.category == 'Side-project').toList();
      expect(sideProject, hasLength(1));
      expect(sideProject.first.planned, equals(Duration.zero));
      expect(sideProject.first.actual.inMinutes, equals(45));
    });
  });

  group('rangeSummary', () {
    test('aggregates across custom date range', () async {
      final task = await taskService.add(
        title: 'Dev task',
        category: 'Working',
      );

      // Two days of work in a 5-day range
      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 10, 9, 0),
        duration: const Duration(hours: 3),
      );
      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 13, 9, 0),
        duration: const Duration(hours: 2),
      );
      // Outside range
      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 15, 9, 0),
        duration: const Duration(hours: 10),
      );

      // Plan entries
      await planService.add(
        category: 'Working',
        durationMs: 4 * 60 * 60 * 1000,
        day: '2026-02-10',
      );
      await planService.add(
        category: 'Working',
        durationMs: 4 * 60 * 60 * 1000,
        day: '2026-02-13',
      );

      final summary = await planService.rangeSummary(
        from: DateTime(2026, 2, 10),
        to: DateTime(2026, 2, 14),
      );

      expect(summary.day, equals('2026-02-10'));
      final working = summary.categories
          .firstWhere((c) => c.category == 'Working');
      expect(working.planned.inHours, equals(8)); // 4+4
      expect(working.actual.inHours, equals(5)); // 3+2, not 10
    });
  });

  group('addTask', () {
    test('creates plan task entry and returns it', () async {
      final task = await taskService.add(title: 'Build login');
      final entry = await planService.addTask(
        taskId: task.id,
        estimateMs: 2 * 60 * 60 * 1000, // 2h
        day: '2026-02-19',
      );

      expect(entry.taskId, equals(task.id));
      expect(entry.estimateMs, equals(2 * 60 * 60 * 1000));
      expect(entry.day, equals('2026-02-19'));
    });

    test('defaults to today when day not provided', () async {
      final task = await taskService.add(title: 'Write tests');
      final entry = await planService.addTask(taskId: task.id);

      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(entry.day, equals(today));
    });

    test('defaults estimate to 0', () async {
      final task = await taskService.add(title: 'Quick task');
      final entry = await planService.addTask(
        taskId: task.id,
        day: '2026-02-19',
      );

      expect(entry.estimateMs, equals(0));
    });

    test('throws DuplicatePlanTaskException on same task+day', () async {
      final task = await taskService.add(title: 'Build login');
      await planService.addTask(taskId: task.id, day: '2026-02-19');

      expect(
        () => planService.addTask(taskId: task.id, day: '2026-02-19'),
        throwsA(isA<DuplicatePlanTaskException>()),
      );
    });

    test('allows same task on different days', () async {
      final task = await taskService.add(title: 'Build login');
      await planService.addTask(taskId: task.id, day: '2026-02-19');

      final entry2 = await planService.addTask(
        taskId: task.id,
        day: '2026-02-20',
      );

      expect(entry2.day, equals('2026-02-20'));
    });
  });

  group('removeTask', () {
    test('soft-deletes plan task entry', () async {
      final task = await taskService.add(title: 'Build login');
      await planService.addTask(taskId: task.id, day: '2026-02-19');

      await planService.removeTask(taskId: task.id, day: '2026-02-19');

      final entries = await planService.listTasksForDay(day: '2026-02-19');
      expect(entries, isEmpty);
    });

    test('throws PlanTaskNotFoundException when not found', () async {
      expect(
        () => planService.removeTask(taskId: 'nonexistent', day: '2026-02-19'),
        throwsA(isA<PlanTaskNotFoundException>()),
      );
    });

    test('allows re-add after remove', () async {
      final task = await taskService.add(title: 'Build login');
      await planService.addTask(
        taskId: task.id,
        estimateMs: 1 * 60 * 60 * 1000,
        day: '2026-02-19',
      );
      await planService.removeTask(taskId: task.id, day: '2026-02-19');

      final entry = await planService.addTask(
        taskId: task.id,
        estimateMs: 2 * 60 * 60 * 1000,
        day: '2026-02-19',
      );

      expect(entry.estimateMs, equals(2 * 60 * 60 * 1000));
    });
  });

  group('listTasksForDay', () {
    test('returns entries for specific day', () async {
      final task1 = await taskService.add(title: 'Task 1');
      final task2 = await taskService.add(title: 'Task 2');
      final task3 = await taskService.add(title: 'Task 3');

      await planService.addTask(taskId: task1.id, day: '2026-02-19');
      await planService.addTask(taskId: task2.id, day: '2026-02-19');
      await planService.addTask(taskId: task3.id, day: '2026-02-20');

      final entries = await planService.listTasksForDay(day: '2026-02-19');
      expect(entries, hasLength(2));
    });

    test('excludes deleted entries', () async {
      final task1 = await taskService.add(title: 'Task 1');
      final task2 = await taskService.add(title: 'Task 2');

      await planService.addTask(taskId: task1.id, day: '2026-02-19');
      await planService.addTask(taskId: task2.id, day: '2026-02-19');
      await planService.removeTask(taskId: task1.id, day: '2026-02-19');

      final entries = await planService.listTasksForDay(day: '2026-02-19');
      expect(entries, hasLength(1));
      expect(entries.first.taskId, equals(task2.id));
    });

    test('does not modify task due date', () async {
      final task = await taskService.add(
        title: 'Task with due',
        dueDay: '2026-03-01',
      );

      await planService.addTask(
        taskId: task.id,
        day: '2026-02-19',
      );

      // Re-fetch the task and verify dueDay unchanged
      final refreshed = await taskService.show(task.id);
      expect(refreshed.dueDay, equals('2026-03-01'));
    });
  });

  group('cancelTask', () {
    test('sets cancelled flag on plan task', () async {
      final task = await taskService.add(title: 'Build login');
      await planService.addTask(taskId: task.id, day: '2026-02-19');

      final entry =
          await planService.cancelTask(taskId: task.id, day: '2026-02-19');

      expect(entry.isCancelled, isTrue);
    });

    test('persists cancelled state after re-read', () async {
      final task = await taskService.add(title: 'Build login');
      await planService.addTask(taskId: task.id, day: '2026-02-19');
      await planService.cancelTask(taskId: task.id, day: '2026-02-19');

      final entries = await planService.listTasksForDay(day: '2026-02-19');
      expect(entries, hasLength(1));
      expect(entries.first.isCancelled, isTrue);
    });

    test('uncancelTask clears cancelled flag', () async {
      final task = await taskService.add(title: 'Build login');
      await planService.addTask(taskId: task.id, day: '2026-02-19');
      await planService.cancelTask(taskId: task.id, day: '2026-02-19');
      final entry =
          await planService.uncancelTask(taskId: task.id, day: '2026-02-19');

      expect(entry.isCancelled, isFalse);
    });

    test('uncancelTask persists after re-read', () async {
      final task = await taskService.add(title: 'Build login');
      await planService.addTask(taskId: task.id, day: '2026-02-19');
      await planService.cancelTask(taskId: task.id, day: '2026-02-19');
      await planService.uncancelTask(taskId: task.id, day: '2026-02-19');

      final entries = await planService.listTasksForDay(day: '2026-02-19');
      expect(entries, hasLength(1));
      expect(entries.first.isCancelled, isFalse);
    });

    test('throws PlanTaskNotFoundException when task not found', () async {
      expect(
        () => planService.cancelTask(
            taskId: 'nonexistent', day: '2026-02-19'),
        throwsA(isA<PlanTaskNotFoundException>()),
      );
    });

    test('throws PlanTaskNotFoundException on uncancel when not found',
        () async {
      expect(
        () => planService.uncancelTask(
            taskId: 'nonexistent', day: '2026-02-19'),
        throwsA(isA<PlanTaskNotFoundException>()),
      );
    });

    test('default is not cancelled', () async {
      final task = await taskService.add(title: 'Build login');
      final entry = await planService.addTask(
        taskId: task.id,
        day: '2026-02-19',
      );

      expect(entry.isCancelled, isFalse);
    });
  });

  group('weekSummary', () {
    test('returns empty when no plans or worklogs', () async {
      // Use a fixed Monday anchor
      final monday = DateTime(2026, 2, 16); // Monday
      final summary = await planService.weekSummary(anchor: monday);

      expect(summary.categories, isEmpty);
      expect(summary.nonCategorized, isNull);
      expect(summary.day, equals('2026-02-16'));
    });

    test('aggregates planned time across week days', () async {
      // Mon 2026-02-16 through Sun 2026-02-22
      await planService.add(
        category: 'Working',
        durationMs: 4 * 60 * 60 * 1000, // 4h
        day: '2026-02-16',
      );
      await planService.add(
        category: 'Working',
        durationMs: 3 * 60 * 60 * 1000, // 3h
        day: '2026-02-17',
      );
      await planService.add(
        category: 'Learning',
        durationMs: 2 * 60 * 60 * 1000, // 2h
        day: '2026-02-16',
      );

      final monday = DateTime(2026, 2, 16);
      final summary = await planService.weekSummary(anchor: monday);

      expect(summary.categories, hasLength(2));
      final working = summary.categories
          .firstWhere((c) => c.category == 'Working');
      expect(working.planned.inHours, equals(7)); // 4+3

      final learning = summary.categories
          .firstWhere((c) => c.category == 'Learning');
      expect(learning.planned.inHours, equals(2));
    });

    test('aggregates actual time from worklogs across the week', () async {
      final task = await taskService.add(
        title: 'Dev task',
        category: 'Working',
      );

      // Log on two different days within the week
      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 16, 9, 0), // Monday
        duration: const Duration(hours: 3),
      );
      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 18, 9, 0), // Wednesday
        duration: const Duration(hours: 2),
      );

      // Plan for comparison
      await planService.add(
        category: 'Working',
        durationMs: 8 * 60 * 60 * 1000, // 8h
        day: '2026-02-16',
      );

      final monday = DateTime(2026, 2, 16);
      final summary = await planService.weekSummary(anchor: monday);

      final working = summary.categories
          .firstWhere((c) => c.category == 'Working');
      expect(working.planned.inHours, equals(8));
      expect(working.actual.inHours, equals(5)); // 3+2
    });

    test('includes non-categorized worklogs', () async {
      final task = await taskService.add(title: 'No category task');

      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 16, 10, 0),
        duration: const Duration(hours: 1),
      );

      final monday = DateTime(2026, 2, 16);
      final summary = await planService.weekSummary(anchor: monday);

      expect(summary.nonCategorized, isNotNull);
      expect(summary.nonCategorized!.actual.inHours, equals(1));
    });

    test('excludes worklogs outside the week', () async {
      final task = await taskService.add(
        title: 'Dev task',
        category: 'Working',
      );

      // Worklog inside the week
      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 16, 9, 0), // Monday of target week
        duration: const Duration(hours: 2),
      );
      // Worklog outside the week (previous week)
      await worklogService.createWorklog(
        taskId: task.id,
        start: DateTime(2026, 2, 15, 9, 0), // Sunday before
        duration: const Duration(hours: 5),
      );

      final monday = DateTime(2026, 2, 16);
      final summary = await planService.weekSummary(anchor: monday);

      final working = summary.categories
          .firstWhere((c) => c.category == 'Working');
      expect(working.actual.inHours, equals(2)); // Only the in-week one
    });
  });
}
