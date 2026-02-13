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
}
