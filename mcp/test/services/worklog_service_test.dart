import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late WorklogService service;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    service = WorklogService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
  });

  group('todaySummary', () {
    test('returns empty summary when no worklogs', () async {
      final summary = await service.todaySummary();

      expect(summary.total, equals(Duration.zero));
      expect(summary.tasks, isEmpty);
    });

    test('returns summary with multiple worklogs', () async {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Create worklogs for today
      final w1 = WorklogDocument.create(
        clock: clock,
        taskId: 'task-1',
        start: now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        end: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      );
      final w2 = WorklogDocument.create(
        clock: clock,
        taskId: 'task-2',
        start: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );

      await db
          .into(db.worklogEntries)
          .insert(w1.toDriftCompanion());
      await db
          .into(db.worklogEntries)
          .insert(w2.toDriftCompanion());

      final summary = await service.todaySummary();

      expect(summary.date, equals(today));
      expect(summary.tasks, hasLength(2));
      expect(summary.total.inMinutes, greaterThan(0));
    });

    test('groups worklogs by taskId', () async {
      final now = DateTime.now();

      // Two worklogs for same task
      final w1 = WorklogDocument.create(
        clock: clock,
        taskId: 'task-1',
        start: now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
        end: now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      );
      final w2 = WorklogDocument.create(
        clock: clock,
        taskId: 'task-1',
        start: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );

      await db
          .into(db.worklogEntries)
          .insert(w1.toDriftCompanion());
      await db
          .into(db.worklogEntries)
          .insert(w2.toDriftCompanion());

      final summary = await service.todaySummary();

      expect(summary.tasks, hasLength(1));
      expect(summary.tasks.first.taskId, equals('task-1'));
      // ~2 hours total
      expect(summary.tasks.first.total.inMinutes, greaterThanOrEqualTo(119));
    });
  });

  group('weekSummary', () {
    test('returns 7 day summaries', () async {
      final summaries = await service.weekSummary();

      expect(summaries, hasLength(7));
    });

    test('includes worklogs across days', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final w1 = WorklogDocument.create(
        clock: clock,
        taskId: 'task-1',
        start: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );
      final w2 = WorklogDocument.create(
        clock: clock,
        taskId: 'task-1',
        start: yesterday
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        end: yesterday.millisecondsSinceEpoch,
      );

      await db
          .into(db.worklogEntries)
          .insert(w1.toDriftCompanion());
      await db
          .into(db.worklogEntries)
          .insert(w2.toDriftCompanion());

      final summaries = await service.weekSummary();
      final nonEmpty =
          summaries.where((s) => s.total.inMilliseconds > 0).toList();

      expect(nonEmpty.length, greaterThanOrEqualTo(1));
    });
  });

  group('manualLog', () {
    test('creates valid worklog', () async {
      final worklog = await service.manualLog(
        taskId: 'task-1',
        durationMinutes: 90,
        comment: 'Code review',
      );

      expect(worklog.id, isNotEmpty);
      expect(worklog.taskId, equals('task-1'));
      expect(worklog.durationMs, equals(90 * 60 * 1000));
      expect(worklog.comment, equals('Code review'));
    });

    test('persists worklog to database', () async {
      await service.manualLog(
        taskId: 'task-1',
        durationMinutes: 30,
      );

      final recent = await service.listRecent();
      expect(recent, hasLength(1));
      expect(recent.first.taskId, equals('task-1'));
    });
  });

  group('listRecent', () {
    test('returns empty list when no worklogs', () async {
      final recent = await service.listRecent();

      expect(recent, isEmpty);
    });

    test('respects limit', () async {
      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        final w = WorklogDocument.create(
          clock: clock,
          taskId: 'task-$i',
          start:
              now.subtract(Duration(hours: i + 1)).millisecondsSinceEpoch,
          end: now.subtract(Duration(hours: i)).millisecondsSinceEpoch,
        );
        await db
            .into(db.worklogEntries)
            .insert(w.toDriftCompanion());
      }

      final recent = await service.listRecent(limit: 3);

      expect(recent, hasLength(3));
    });

    test('returns most recent first', () async {
      final now = DateTime.now();
      final w1 = WorklogDocument.create(
        clock: clock,
        taskId: 'old',
        start: now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
        end: now.subtract(const Duration(hours: 4)).millisecondsSinceEpoch,
      );
      // Manually set an older createdMs
      w1.createdMs = now.subtract(const Duration(hours: 4)).millisecondsSinceEpoch;

      final w2 = WorklogDocument.create(
        clock: clock,
        taskId: 'new',
        start: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );
      // Ensure newer createdMs
      w2.createdMs = now.millisecondsSinceEpoch;

      await db
          .into(db.worklogEntries)
          .insert(w1.toDriftCompanion());
      await db
          .into(db.worklogEntries)
          .insert(w2.toDriftCompanion());

      final recent = await service.listRecent();

      expect(recent.first.taskId, equals('new'));
      expect(recent.last.taskId, equals('old'));
    });
  });
}
