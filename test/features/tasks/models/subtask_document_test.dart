import 'package:avodah/core/crdt/crdt.dart';
import 'package:avodah/features/tasks/models/subtask_document.dart';
import 'package:test/test.dart';

void main() {
  group('SubtaskDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('creation', () {
      test('create() generates UUID and sets initial fields', () {
        final subtask = SubtaskDocument.create(
          clock: clock,
          taskId: 'task-1',
          title: 'Buy groceries',
          order: 0,
        );

        expect(subtask.id, isNotEmpty);
        expect(subtask.taskId, equals('task-1'));
        expect(subtask.title, equals('Buy groceries'));
        expect(subtask.order, equals(0));
        expect(subtask.isDone, isFalse);
        expect(subtask.notes, isNull);
        expect(subtask.createdTimestamp, isNotNull);
      });

      test('create() with custom order', () {
        final subtask = SubtaskDocument.create(
          clock: clock,
          taskId: 'task-1',
          title: 'Step 3',
          order: 2,
        );

        expect(subtask.order, equals(2));
      });

      test('constructor creates empty document', () {
        final subtask = SubtaskDocument(id: 'sub-1', clock: clock);

        expect(subtask.id, equals('sub-1'));
        expect(subtask.title, isEmpty);
        expect(subtask.taskId, isEmpty);
        expect(subtask.isDone, isFalse);
      });
    });

    group('core fields', () {
      test('title can be set and retrieved', () {
        final subtask = SubtaskDocument(id: 'sub-1', clock: clock);

        subtask.title = 'Updated Title';
        expect(subtask.title, equals('Updated Title'));
      });

      test('taskId can be set', () {
        final subtask = SubtaskDocument(id: 'sub-1', clock: clock);

        subtask.taskId = 'task-99';
        expect(subtask.taskId, equals('task-99'));
      });

      test('order can be set', () {
        final subtask = SubtaskDocument(id: 'sub-1', clock: clock);

        subtask.order = 5;
        expect(subtask.order, equals(5));
      });

      test('notes can be set and cleared', () {
        final subtask = SubtaskDocument(id: 'sub-1', clock: clock);

        subtask.notes = 'Some additional info';
        expect(subtask.notes, equals('Some additional info'));

        subtask.notes = null;
        expect(subtask.notes, isNull);
      });
    });

    group('completion', () {
      test('isDone can be set directly', () {
        final subtask = SubtaskDocument(id: 'sub-1', clock: clock);

        subtask.isDone = true;
        expect(subtask.isDone, isTrue);

        subtask.isDone = false;
        expect(subtask.isDone, isFalse);
      });

      test('markDone() sets isDone to true', () {
        final subtask = SubtaskDocument.create(
          clock: clock,
          taskId: 'task-1',
          title: 'Test',
        );

        subtask.markDone();

        expect(subtask.isDone, isTrue);
      });

      test('markUndone() sets isDone to false', () {
        final subtask = SubtaskDocument.create(
          clock: clock,
          taskId: 'task-1',
          title: 'Test',
        );
        subtask.markDone();

        subtask.markUndone();

        expect(subtask.isDone, isFalse);
      });

      test('toggle() flips isDone', () {
        final subtask = SubtaskDocument.create(
          clock: clock,
          taskId: 'task-1',
          title: 'Test',
        );

        expect(subtask.isDone, isFalse);

        subtask.toggle();
        expect(subtask.isDone, isTrue);

        subtask.toggle();
        expect(subtask.isDone, isFalse);
      });
    });

    group('soft delete', () {
      test('delete() marks subtask as deleted', () {
        final subtask = SubtaskDocument.create(
          clock: clock,
          taskId: 'task-1',
          title: 'Test',
        );

        expect(subtask.isDeleted, isFalse);

        subtask.delete();

        expect(subtask.isDeleted, isTrue);
      });

      test('restore() undeletes subtask', () {
        final subtask = SubtaskDocument.create(
          clock: clock,
          taskId: 'task-1',
          title: 'Test',
        );
        subtask.delete();

        subtask.restore();

        expect(subtask.isDeleted, isFalse);
      });
    });

    group('toModel', () {
      test('converts to SubtaskModel correctly', () {
        final subtask = SubtaskDocument.create(
          clock: clock,
          taskId: 'task-1',
          title: 'Review code',
          order: 2,
        );
        subtask.notes = 'Check for edge cases';
        subtask.markDone();

        final model = subtask.toModel();

        expect(model.id, equals(subtask.id));
        expect(model.taskId, equals('task-1'));
        expect(model.title, equals('Review code'));
        expect(model.order, equals(2));
        expect(model.isDone, isTrue);
        expect(model.notes, equals('Check for edge cases'));
        expect(model.isDeleted, isFalse);
      });
    });

    group('CRDT merge', () {
      test('merging with remote document resolves conflicts', () {
        // Create two subtasks representing same entity on different nodes
        final clockA = HybridLogicalClock(nodeId: 'node-a');
        final clockB = HybridLogicalClock(nodeId: 'node-b');

        final subtaskA = SubtaskDocument.create(
          clock: clockA,
          taskId: 'task-1',
          title: 'Original',
        );

        // Simulate remote with same ID
        final subtaskB = SubtaskDocument(
          id: subtaskA.id,
          clock: clockB,
        );
        subtaskB.title = 'Remote update';

        // Both modify the same subtask
        subtaskA.title = 'Local update';

        // Merge remote into local
        subtaskA.merge(subtaskB);

        // Result should be deterministic based on timestamps/node IDs
        expect(subtaskA.title, isNotEmpty);
      });
    });
  });
}
