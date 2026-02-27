import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late TaskService service;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    service = TaskService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
  });

  group('add', () {
    test('creates task with title and returns it', () async {
      final task = await service.add(title: 'Buy groceries');

      expect(task.id, isNotEmpty);
      expect(task.title, equals('Buy groceries'));
      expect(task.isDone, isFalse);
      expect(task.createdTimestamp, isNotNull);
    });

    test('creates task with projectId', () async {
      final task = await service.add(
        title: 'Fix bug',
        projectId: 'proj-1',
      );

      expect(task.projectId, equals('proj-1'));
    });

    test('persists task to database', () async {
      final task = await service.add(title: 'Persist me');

      final fetched = await service.show(task.id);
      expect(fetched.title, equals('Persist me'));
    });
  });

  group('list', () {
    test('returns active tasks by default', () async {
      await service.add(title: 'Task 1');
      await service.add(title: 'Task 2');

      final tasks = await service.list();

      expect(tasks, hasLength(2));
    });

    test('excludes completed tasks by default', () async {
      final task = await service.add(title: 'Will be done');
      await service.add(title: 'Still active');
      await service.done(task.id);

      final tasks = await service.list();

      expect(tasks, hasLength(1));
      expect(tasks.first.title, equals('Still active'));
    });

    test('includes completed tasks with includeCompleted', () async {
      final task = await service.add(title: 'Will be done');
      await service.add(title: 'Still active');
      await service.done(task.id);

      final tasks = await service.list(includeCompleted: true);

      expect(tasks, hasLength(2));
    });

    test('excludes deleted tasks', () async {
      final task = await service.add(title: 'Will be deleted');
      await service.add(title: 'Still active');

      // Delete the task directly via document
      final doc = await service.show(task.id);
      doc.delete();
      await db
          .into(db.tasks)
          .insertOnConflictUpdate(doc.toDriftCompanion());

      final tasks = await service.list(includeCompleted: true);

      expect(tasks, hasLength(1));
      expect(tasks.first.title, equals('Still active'));
    });

    test('returns empty list when no tasks', () async {
      final tasks = await service.list();

      expect(tasks, isEmpty);
    });
  });

  group('show', () {
    test('finds task by exact ID', () async {
      final created = await service.add(title: 'Find me');

      final found = await service.show(created.id);

      expect(found.id, equals(created.id));
      expect(found.title, equals('Find me'));
    });

    test('finds task by prefix', () async {
      final created = await service.add(title: 'Find by prefix');

      final found = await service.show(created.id.substring(0, 8));

      expect(found.id, equals(created.id));
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.show('nonexistent-id'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('throws AmbiguousTaskIdException for ambiguous prefix', () async {
      // Create two tasks — they'll have different UUIDs but we need
      // to test the ambiguity logic. We'll use a very short prefix
      // that's likely to match both.
      await service.add(title: 'Task A');
      await service.add(title: 'Task B');

      // Using empty prefix matches all — should be ambiguous
      expect(
        () => service.show(''),
        throwsA(isA<AmbiguousTaskIdException>()),
      );
    });
  });

  group('done', () {
    test('marks task as done', () async {
      final created = await service.add(title: 'Complete me');

      final done = await service.done(created.id);

      expect(done.isDone, isTrue);
      expect(done.doneOn, isNotNull);
    });

    test('persists done state', () async {
      final created = await service.add(title: 'Complete me');
      await service.done(created.id);

      final fetched = await service.show(created.id);
      expect(fetched.isDone, isTrue);
    });

    test('works with prefix', () async {
      final created = await service.add(title: 'Done by prefix');

      final done = await service.done(created.id.substring(0, 8));

      expect(done.isDone, isTrue);
    });

    test('throws TaskAlreadyDoneException for completed task', () async {
      final created = await service.add(title: 'Already done');
      await service.done(created.id);

      expect(
        () => service.done(created.id),
        throwsA(isA<TaskAlreadyDoneException>()),
      );
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.done('nonexistent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('soft-deletes task', () async {
      final created = await service.add(title: 'Delete me');

      final deleted = await service.delete(created.id);

      expect(deleted.isDeleted, isTrue);
    });

    test('deleted task excluded from list', () async {
      final created = await service.add(title: 'Delete me');
      await service.delete(created.id);

      final tasks = await service.list();
      expect(tasks, isEmpty);
    });

    test('works with prefix', () async {
      final created = await service.add(title: 'Delete by prefix');

      final deleted = await service.delete(created.id.substring(0, 8));

      expect(deleted.isDeleted, isTrue);
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.delete('nonexistent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('setDue', () {
    test('sets due date on a task', () async {
      final created = await service.add(title: 'Due task');

      final updated = await service.setDue(created.id, '2026-03-15');

      expect(updated.dueDay, equals('2026-03-15'));
    });

    test('persists due date', () async {
      final created = await service.add(title: 'Due task');
      await service.setDue(created.id, '2026-03-15');

      final fetched = await service.show(created.id);
      expect(fetched.dueDay, equals('2026-03-15'));
    });

    test('clears due date with null', () async {
      final created = await service.add(title: 'Due task', dueDay: '2026-03-15');

      final updated = await service.setDue(created.id, null);

      expect(updated.dueDay, isNull);
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.setDue('nonexistent', '2026-03-15'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('setCategory', () {
    test('sets category on a task', () async {
      final created = await service.add(title: 'Cat task');

      final updated = await service.setCategory(created.id, 'Working');

      expect(updated.category, equals('Working'));
    });

    test('persists category', () async {
      final created = await service.add(title: 'Cat task');
      await service.setCategory(created.id, 'Learning');

      final fetched = await service.show(created.id);
      expect(fetched.category, equals('Learning'));
    });

    test('clears category with null', () async {
      final created = await service.add(title: 'Cat task', category: 'Working');

      final updated = await service.setCategory(created.id, null);

      expect(updated.category, isNull);
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.setCategory('nonexistent', 'Working'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('add with optional params', () {
    test('creates task with dueDay', () async {
      final task = await service.add(title: 'Due task', dueDay: '2026-04-01');

      expect(task.dueDay, equals('2026-04-01'));
    });

    test('creates task with category', () async {
      final task = await service.add(title: 'Cat task', category: 'Learning');

      expect(task.category, equals('Learning'));
    });

    test('creates task with both dueDay and category', () async {
      final task = await service.add(
        title: 'Full task',
        dueDay: '2026-04-01',
        category: 'Working',
      );

      expect(task.dueDay, equals('2026-04-01'));
      expect(task.category, equals('Working'));
    });
  });

  group('overdue', () {
    test('returns overdue tasks', () async {
      await service.add(title: 'Past due', dueDay: '2020-01-01');
      await service.add(title: 'Future due', dueDay: '2099-12-31');
      await service.add(title: 'No due');

      final overdueTasks = await service.overdue();

      expect(overdueTasks, hasLength(1));
      expect(overdueTasks.first.title, equals('Past due'));
    });

    test('excludes completed overdue tasks', () async {
      final task = await service.add(title: 'Past due', dueDay: '2020-01-01');
      await service.done(task.id);

      final overdueTasks = await service.overdue();

      expect(overdueTasks, isEmpty);
    });

    test('returns empty when no overdue tasks', () async {
      await service.add(title: 'Future due', dueDay: '2099-12-31');

      final overdueTasks = await service.overdue();

      expect(overdueTasks, isEmpty);
    });
  });

  group('undone', () {
    test('marks done task as active', () async {
      final created = await service.add(title: 'Undone me');
      await service.done(created.id);

      final undone = await service.undone(created.id);

      expect(undone.isDone, isFalse);
      expect(undone.doneOn, isNull);
    });

    test('persists undone state', () async {
      final created = await service.add(title: 'Persist undone');
      await service.done(created.id);
      await service.undone(created.id);

      final fetched = await service.show(created.id);
      expect(fetched.isDone, isFalse);
    });

    test('undone task reappears in list', () async {
      final created = await service.add(title: 'Reappear');
      await service.done(created.id);

      var tasks = await service.list();
      expect(tasks, isEmpty);

      await service.undone(created.id);
      tasks = await service.list();
      expect(tasks, hasLength(1));
      expect(tasks.first.title, equals('Reappear'));
    });

    test('works with prefix', () async {
      final created = await service.add(title: 'Undone by prefix');
      await service.done(created.id);

      final undone = await service.undone(created.id.substring(0, 8));

      expect(undone.isDone, isFalse);
    });

    test('throws TaskNotDoneException for active task', () async {
      final created = await service.add(title: 'Not done');

      expect(
        () => service.undone(created.id),
        throwsA(isA<TaskNotDoneException>()),
      );
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.undone('nonexistent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('undelete', () {
    test('restores deleted task to active', () async {
      final created = await service.add(title: 'Restore me');
      await service.delete(created.id);

      final restored = await service.undelete(created.id);

      expect(restored.isDeleted, isFalse);
    });

    test('persists restored state', () async {
      final created = await service.add(title: 'Persist restore');
      await service.delete(created.id);
      await service.undelete(created.id);

      final fetched = await service.show(created.id);
      expect(fetched.isDeleted, isFalse);
    });

    test('restored task reappears in list', () async {
      final created = await service.add(title: 'Reappear after restore');
      await service.delete(created.id);

      var tasks = await service.list();
      expect(tasks, isEmpty);

      await service.undelete(created.id);
      tasks = await service.list();
      expect(tasks, hasLength(1));
      expect(tasks.first.title, equals('Reappear after restore'));
    });

    test('works with prefix', () async {
      final created = await service.add(title: 'Restore by prefix');
      await service.delete(created.id);

      final restored = await service.undelete(created.id.substring(0, 8));

      expect(restored.isDeleted, isFalse);
    });

    test('throws TaskNotDeletedException for active task', () async {
      final created = await service.add(title: 'Not deleted');

      expect(
        () => service.undelete(created.id),
        throwsA(isA<TaskNotDeletedException>()),
      );
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.undelete('nonexistent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('setDescription', () {
    test('sets description on a task', () async {
      final created = await service.add(title: 'Noted task');

      final updated = await service.setDescription(created.id, 'My notes');

      expect(updated.description, equals('My notes'));
    });

    test('persists description', () async {
      final created = await service.add(title: 'Noted task');
      await service.setDescription(created.id, 'Persisted notes');

      final fetched = await service.show(created.id);
      expect(fetched.description, equals('Persisted notes'));
    });

    test('clears description with null', () async {
      final created = await service.add(title: 'Noted task');
      await service.setDescription(created.id, 'Some notes');

      final updated = await service.setDescription(created.id, null);

      expect(updated.description, isNull);
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.setDescription('nonexistent', 'notes'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('appendNote', () {
    test('appends to empty description', () async {
      final created = await service.add(title: 'Append task');

      final updated = await service.appendNote(created.id, 'First note');

      expect(updated.description, contains('First note'));
      // Should have timestamp prefix
      expect(updated.description, matches(RegExp(r'_\d{4}-\d{2}-\d{2} \d{2}:\d{2}_')));
    });

    test('appends to existing description with separator', () async {
      final created = await service.add(title: 'Append task');
      await service.setDescription(created.id, 'Existing content');

      final updated = await service.appendNote(created.id, 'Second note');

      expect(updated.description, startsWith('Existing content'));
      expect(updated.description, contains('---'));
      expect(updated.description, contains('Second note'));
    });

    test('persists appended note', () async {
      final created = await service.add(title: 'Persist append');
      await service.appendNote(created.id, 'Persisted note');

      final fetched = await service.show(created.id);
      expect(fetched.description, contains('Persisted note'));
    });

    test('works with prefix match', () async {
      final created = await service.add(title: 'Prefix append');

      final updated = await service.appendNote(
          created.id.substring(0, 8), 'Prefix note');

      expect(updated.description, contains('Prefix note'));
    });

    test('throws TaskNotFoundException for unknown ID', () async {
      expect(
        () => service.appendNote('nonexistent', 'note'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('listDeleted', () {
    test('returns only deleted tasks', () async {
      await service.add(title: 'Active');
      final toDelete = await service.add(title: 'Deleted');
      await service.delete(toDelete.id);

      final deleted = await service.listDeleted();

      expect(deleted, hasLength(1));
      expect(deleted.first.title, equals('Deleted'));
    });

    test('returns empty when no deleted tasks', () async {
      await service.add(title: 'Active');

      final deleted = await service.listDeleted();

      expect(deleted, isEmpty);
    });

    test('includes done+deleted tasks', () async {
      final task = await service.add(title: 'Done then deleted');
      await service.done(task.id);
      await service.delete(task.id);

      final deleted = await service.listDeleted();

      expect(deleted, hasLength(1));
      expect(deleted.first.isDone, isTrue);
      expect(deleted.first.isDeleted, isTrue);
    });
  });
}
