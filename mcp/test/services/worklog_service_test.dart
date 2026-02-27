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

  group('daySummary', () {
    test('returns empty summary for a day with no worklogs', () async {
      final summary = await service.daySummary('2026-02-15');

      expect(summary.total, equals(Duration.zero));
      expect(summary.tasks, isEmpty);
      expect(summary.date, equals('2026-02-15'));
    });

    test('returns summary for a specific past date', () async {
      final start = DateTime(2026, 2, 15, 9, 0);
      await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(hours: 2),
      );
      await service.createWorklog(
        taskId: 'task-2',
        start: DateTime(2026, 2, 15, 14, 0),
        duration: const Duration(hours: 1),
      );
      // Worklog on a different day — should not appear
      await service.createWorklog(
        taskId: 'task-3',
        start: DateTime(2026, 2, 16, 9, 0),
        duration: const Duration(hours: 1),
      );

      final summary = await service.daySummary('2026-02-15');

      expect(summary.date, equals('2026-02-15'));
      expect(summary.tasks, hasLength(2));
      expect(summary.total.inHours, equals(3));
    });

    test('todaySummary delegates to daySummary', () async {
      // Just verify todaySummary still works
      final summary = await service.todaySummary();
      expect(summary.total, equals(Duration.zero));
    });
  });

  group('rangeSummary', () {
    test('returns one summary per day in range', () async {
      final summaries = await service.rangeSummary(
        from: DateTime(2026, 2, 10),
        to: DateTime(2026, 2, 14),
      );

      expect(summaries, hasLength(5));
      expect(summaries.first.date, equals('2026-02-10'));
      expect(summaries.last.date, equals('2026-02-14'));
    });

    test('includes worklogs within range and excludes outside', () async {
      // Inside range
      await service.createWorklog(
        taskId: 'task-1',
        start: DateTime(2026, 2, 11, 9, 0),
        duration: const Duration(hours: 2),
      );
      // Outside range
      await service.createWorklog(
        taskId: 'task-2',
        start: DateTime(2026, 2, 15, 9, 0),
        duration: const Duration(hours: 3),
      );

      final summaries = await service.rangeSummary(
        from: DateTime(2026, 2, 10),
        to: DateTime(2026, 2, 14),
      );

      final totalMs = summaries.fold<int>(0, (s, d) => s + d.total.inMilliseconds);
      expect(Duration(milliseconds: totalMs).inHours, equals(2));
    });

    test('single day range works', () async {
      await service.createWorklog(
        taskId: 'task-1',
        start: DateTime(2026, 2, 12, 10, 0),
        duration: const Duration(hours: 1),
      );

      final summaries = await service.rangeSummary(
        from: DateTime(2026, 2, 12),
        to: DateTime(2026, 2, 12),
      );

      expect(summaries, hasLength(1));
      expect(summaries.first.total.inHours, equals(1));
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

  group('timeByTask', () {
    test('aggregates duration per task', () async {
      await service.manualLog(taskId: 'task-a', durationMinutes: 60);
      await service.manualLog(taskId: 'task-a', durationMinutes: 30);
      await service.manualLog(taskId: 'task-b', durationMinutes: 45);

      final result = await service.timeByTask();

      expect(result['task-a']!.inMinutes, equals(90));
      expect(result['task-b']!.inMinutes, equals(45));
    });

    test('excludes deleted worklogs', () async {
      final wl = await service.manualLog(taskId: 'task-a', durationMinutes: 60);
      await service.deleteWorklog(wl.id);

      final result = await service.timeByTask();

      expect(result['task-a'], isNull);
    });
  });

  group('show', () {
    test('finds worklog by exact ID', () async {
      final created = await service.manualLog(
        taskId: 'task-1',
        durationMinutes: 30,
      );

      final found = await service.show(created.id);

      expect(found.id, equals(created.id));
    });

    test('finds worklog by prefix', () async {
      final created = await service.manualLog(
        taskId: 'task-1',
        durationMinutes: 30,
      );

      final found = await service.show(created.id.substring(0, 8));

      expect(found.id, equals(created.id));
    });

    test('throws WorklogNotFoundException for unknown ID', () async {
      expect(
        () => service.show('nonexistent'),
        throwsA(isA<WorklogNotFoundException>()),
      );
    });
  });

  group('createWorklog', () {
    test('creates worklog with explicit start and duration', () async {
      final start = DateTime(2026, 2, 15, 9, 0);
      final duration = const Duration(hours: 1, minutes: 30);

      final worklog = await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: duration,
        comment: 'morning standup',
      );

      expect(worklog.taskId, equals('task-1'));
      expect(worklog.startMs, equals(start.millisecondsSinceEpoch));
      expect(worklog.endMs, equals(start.add(duration).millisecondsSinceEpoch));
      expect(worklog.durationMs, equals(duration.inMilliseconds));
      expect(worklog.date, equals('2026-02-15'));
      expect(worklog.comment, equals('morning standup'));
    });

    test('persists worklog to database', () async {
      final start = DateTime(2026, 2, 15, 14, 0);
      await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(minutes: 45),
      );

      final recent = await service.listRecent();
      expect(recent, hasLength(1));
      expect(recent.first.taskId, equals('task-1'));
    });

    test('creates worklog without comment', () async {
      final start = DateTime(2026, 2, 15, 10, 0);
      final worklog = await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(hours: 2),
      );

      expect(worklog.comment, isNull);
    });
  });

  group('editWorklog', () {
    test('updates comment only', () async {
      final start = DateTime(2026, 2, 15, 9, 0);
      final created = await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(hours: 1),
      );

      final updated = await service.editWorklog(
        created.id,
        comment: 'updated comment',
      );

      expect(updated.comment, equals('updated comment'));
      expect(updated.startMs, equals(created.startMs));
      expect(updated.durationMs, equals(created.durationMs));
    });

    test('updates start time and recalculates end', () async {
      final start = DateTime(2026, 2, 15, 9, 0);
      final created = await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(hours: 1),
      );

      final newStart = DateTime(2026, 2, 15, 10, 0);
      final updated = await service.editWorklog(
        created.id,
        start: newStart,
      );

      expect(updated.startMs, equals(newStart.millisecondsSinceEpoch));
      // Duration stays the same (1h)
      expect(updated.durationMs, equals(const Duration(hours: 1).inMilliseconds));
      // End = newStart + 1h
      expect(updated.endMs, equals(newStart.add(const Duration(hours: 1)).millisecondsSinceEpoch));
      expect(updated.date, equals('2026-02-15'));
    });

    test('updates duration and recalculates end', () async {
      final start = DateTime(2026, 2, 15, 9, 0);
      final created = await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(hours: 1),
      );

      final updated = await service.editWorklog(
        created.id,
        duration: const Duration(hours: 2),
      );

      expect(updated.durationMs, equals(const Duration(hours: 2).inMilliseconds));
      // End = original start + 2h
      expect(updated.endMs, equals(start.add(const Duration(hours: 2)).millisecondsSinceEpoch));
      // Start unchanged
      expect(updated.startMs, equals(start.millisecondsSinceEpoch));
    });

    test('updates start and duration together', () async {
      final start = DateTime(2026, 2, 15, 9, 0);
      final created = await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(hours: 1),
      );

      final newStart = DateTime(2026, 2, 15, 14, 0);
      final newDuration = const Duration(minutes: 30);
      final updated = await service.editWorklog(
        created.id,
        start: newStart,
        duration: newDuration,
      );

      expect(updated.startMs, equals(newStart.millisecondsSinceEpoch));
      expect(updated.durationMs, equals(newDuration.inMilliseconds));
      expect(updated.endMs, equals(newStart.add(newDuration).millisecondsSinceEpoch));
    });

    test('stamps updatedMs', () async {
      final start = DateTime(2026, 2, 15, 9, 0);
      final created = await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(hours: 1),
      );
      final beforeUpdate = DateTime.now().millisecondsSinceEpoch;

      final updated = await service.editWorklog(
        created.id,
        comment: 'edited',
      );

      expect(updated.updatedMs, greaterThanOrEqualTo(beforeUpdate));
    });

    test('throws WorklogNotFoundException for unknown ID', () async {
      expect(
        () => service.editWorklog('nonexistent', comment: 'nope'),
        throwsA(isA<WorklogNotFoundException>()),
      );
    });

    test('finds worklog by prefix', () async {
      final start = DateTime(2026, 2, 15, 9, 0);
      final created = await service.createWorklog(
        taskId: 'task-1',
        start: start,
        duration: const Duration(hours: 1),
      );

      final updated = await service.editWorklog(
        created.id.substring(0, 8),
        comment: 'prefix edit',
      );

      expect(updated.id, equals(created.id));
      expect(updated.comment, equals('prefix edit'));
    });
  });

  group('deleteWorklog', () {
    test('soft-deletes worklog', () async {
      final created = await service.manualLog(
        taskId: 'task-1',
        durationMinutes: 30,
      );

      final deleted = await service.deleteWorklog(created.id);

      expect(deleted.isDeleted, isTrue);
    });

    test('deleted worklog excluded from listRecent', () async {
      final created = await service.manualLog(
        taskId: 'task-1',
        durationMinutes: 30,
      );
      await service.deleteWorklog(created.id);

      final recent = await service.listRecent();
      expect(recent, isEmpty);
    });
  });

  group('worklogInfoForTask', () {
    test('returns zero for no worklogs', () async {
      final info = await service.worklogInfoForTask('nonexistent');

      expect(info.count, equals(0));
      expect(info.total, equals(Duration.zero));
    });

    test('returns correct count and total', () async {
      await service.createWorklog(
        taskId: 'task-1',
        start: DateTime(2026, 2, 15, 9, 0),
        duration: const Duration(minutes: 30),
      );
      await service.createWorklog(
        taskId: 'task-1',
        start: DateTime(2026, 2, 15, 14, 0),
        duration: const Duration(minutes: 10),
      );

      final info = await service.worklogInfoForTask('task-1');

      expect(info.count, equals(2));
      expect(info.total.inMinutes, equals(40));
    });

    test('excludes deleted worklogs', () async {
      final w1 = await service.createWorklog(
        taskId: 'task-1',
        start: DateTime(2026, 2, 15, 9, 0),
        duration: const Duration(minutes: 30),
      );
      await service.createWorklog(
        taskId: 'task-1',
        start: DateTime(2026, 2, 15, 14, 0),
        duration: const Duration(minutes: 20),
      );
      await service.deleteWorklog(w1.id);

      final info = await service.worklogInfoForTask('task-1');

      expect(info.count, equals(1));
      expect(info.total.inMinutes, equals(20));
    });

    test('scoped to taskId', () async {
      await service.createWorklog(
        taskId: 'task-1',
        start: DateTime(2026, 2, 15, 9, 0),
        duration: const Duration(minutes: 60),
      );
      await service.createWorklog(
        taskId: 'task-2',
        start: DateTime(2026, 2, 15, 10, 0),
        duration: const Duration(minutes: 45),
      );

      final info = await service.worklogInfoForTask('task-1');

      expect(info.count, equals(1));
      expect(info.total.inMinutes, equals(60));
    });
  });
}
