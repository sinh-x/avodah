import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late TimerService service;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    service = TimerService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
  });

  group('start without taskId', () {
    test('creates a new task when no matching title exists', () async {
      final timer = await service.start(taskTitle: 'New work item');

      expect(timer.taskId, isNotNull);
      expect(timer.taskId, isNotEmpty);
      expect(timer.taskTitle, equals('New work item'));
      expect(timer.isRunning, isTrue);

      // Verify a task was actually created in the database
      final rows = await db.select(db.tasks).get();
      expect(rows, hasLength(1));
      final task = TaskDocument.fromDrift(task: rows.first, clock: clock);
      expect(task.title, equals('New work item'));
      expect(task.id, equals(timer.taskId));
    });

    test('reuses existing task when title matches', () async {
      // Pre-create a task
      final existing = TaskDocument.create(clock: clock, title: 'Existing task');
      await db.into(db.tasks).insertOnConflictUpdate(existing.toDriftCompanion());

      final timer = await service.start(taskTitle: 'Existing task');

      expect(timer.taskId, equals(existing.id));

      // Should still be only one task in the database
      final rows = await db.select(db.tasks).get();
      expect(rows, hasLength(1));
    });
  });

  group('start with taskId', () {
    test('uses provided taskId directly', () async {
      final timer = await service.start(
        taskTitle: 'With explicit ID',
        taskId: 'explicit-task-id',
      );

      expect(timer.taskId, equals('explicit-task-id'));

      // Should NOT create a task in the database
      final rows = await db.select(db.tasks).get();
      expect(rows, isEmpty);
    });
  });

  group('stop', () {
    test('creates worklog with real task UUID', () async {
      final timer = await service.start(taskTitle: 'Track this');
      final taskId = timer.taskId!;

      // Small delay so elapsed > 0
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await service.stop();

      expect(result.taskId, equals(taskId));
      expect(result.taskTitle, equals('Track this'));
      expect(result.worklogId, isNotEmpty);

      // Verify worklog was persisted with the real task ID
      final worklogs = await db.select(db.worklogEntries).get();
      expect(worklogs, hasLength(1));
      final wl = WorklogDocument.fromDrift(worklog: worklogs.first, clock: clock);
      expect(wl.taskId, equals(taskId));
    });

    test('throws when no timer is running', () async {
      expect(
        () => service.stop(),
        throwsA(isA<NoTimerRunningException>()),
      );
    });
  });

  group('_resolveOrCreateTask skips deleted tasks', () {
    test('does not match a deleted task by title', () async {
      // Create then soft-delete a task
      final deleted = TaskDocument.create(clock: clock, title: 'Deleted task');
      deleted.delete();
      await db.into(db.tasks).insertOnConflictUpdate(deleted.toDriftCompanion());

      // Start timer with same title — should create a NEW task
      final timer = await service.start(taskTitle: 'Deleted task');

      expect(timer.taskId, isNot(equals(deleted.id)));

      // Two rows in DB: the deleted one + the new one
      final rows = await db.select(db.tasks).get();
      expect(rows, hasLength(2));
    });
  });
}
