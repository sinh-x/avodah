import 'package:avodah/core/crdt/crdt.dart';
import 'package:avodah/features/tags/models/tag_document.dart';
import 'package:test/test.dart';

void main() {
  group('TagDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('creation', () {
      test('create() generates UUID and sets initial fields', () {
        final tag = TagDocument.create(
          clock: clock,
          title: 'Urgent',
          icon: '🔴',
          color: '#F44336',
        );

        expect(tag.id, isNotEmpty);
        expect(tag.title, equals('Urgent'));
        expect(tag.icon, equals('🔴'));
        expect(tag.primaryColor, equals('#F44336'));
        expect(tag.createdTimestamp, isNotNull);
      });

      test('create() without icon or color sets them correctly', () {
        final tag = TagDocument.create(
          clock: clock,
          title: 'Simple Tag',
        );

        expect(tag.icon, isNull);
        expect(tag.primaryColor, isNull);
      });

      test('constructor creates empty document', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        expect(tag.id, equals('tag-1'));
        expect(tag.title, isEmpty);
        expect(tag.taskCount, equals(0));
      });
    });

    group('core fields', () {
      test('title can be set and retrieved', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        tag.title = 'Updated Title';
        expect(tag.title, equals('Updated Title'));
      });

      test('icon can be set and cleared', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        tag.icon = '⭐';
        expect(tag.icon, equals('⭐'));

        tag.icon = null;
        expect(tag.icon, isNull);
      });
    });

    group('task list', () {
      test('taskIds default to empty list', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        expect(tag.taskIds, isEmpty);
        expect(tag.taskCount, equals(0));
      });

      test('addTask adds to taskIds', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        tag.addTask('task-1');
        tag.addTask('task-2');

        expect(tag.taskIds, equals(['task-1', 'task-2']));
        expect(tag.taskCount, equals(2));
      });

      test('addTask does not add duplicates', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        tag.addTask('task-1');
        tag.addTask('task-1');

        expect(tag.taskIds, equals(['task-1']));
      });

      test('removeTask removes from list', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        tag.addTask('task-1');
        tag.addTask('task-2');

        tag.removeTask('task-1');

        expect(tag.taskIds, equals(['task-2']));
      });
    });

    group('theme', () {
      test('theme defaults to empty map', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        expect(tag.theme, isEmpty);
      });

      test('primaryColor can be set via theme', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        tag.primaryColor = '#2196F3';

        expect(tag.primaryColor, equals('#2196F3'));
        expect(tag.theme['primary'], equals('#2196F3'));
      });

      test('primaryColor can be cleared', () {
        final tag = TagDocument(id: 'tag-1', clock: clock);

        tag.primaryColor = '#2196F3';
        tag.primaryColor = null;

        expect(tag.primaryColor, isNull);
        expect(tag.theme.containsKey('primary'), isFalse);
      });
    });

    group('soft delete', () {
      test('delete() marks tag as deleted', () {
        final tag = TagDocument.create(clock: clock, title: 'Test');

        expect(tag.isDeleted, isFalse);

        tag.delete();

        expect(tag.isDeleted, isTrue);
      });

      test('restore() undeletes tag', () {
        final tag = TagDocument.create(clock: clock, title: 'Test');
        tag.delete();

        tag.restore();

        expect(tag.isDeleted, isFalse);
      });
    });

    group('toModel', () {
      test('converts to TagModel correctly', () {
        final tag = TagDocument.create(
          clock: clock,
          title: 'Priority',
          icon: '⚡',
          color: '#FFC107',
        );
        tag.addTask('task-1');
        tag.addTask('task-2');

        final model = tag.toModel();

        expect(model.id, equals(tag.id));
        expect(model.title, equals('Priority'));
        expect(model.icon, equals('⚡'));
        expect(model.primaryColor, equals('#FFC107'));
        expect(model.taskCount, equals(2));
        expect(model.isDeleted, isFalse);
      });
    });
  });
}
