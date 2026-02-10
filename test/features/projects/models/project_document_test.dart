import 'package:avodah_core/crdt/crdt.dart';
import 'package:avodah/features/projects/models/project_document.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('creation', () {
      test('create() generates UUID and sets initial fields', () {
        final project = ProjectDocument.create(
          clock: clock,
          title: 'My Project',
          icon: '📁',
        );

        expect(project.id, isNotEmpty);
        expect(project.title, equals('My Project'));
        expect(project.icon, equals('📁'));
        expect(project.isArchived, isFalse);
        expect(project.isHiddenFromMenu, isFalse);
        expect(project.isEnableBacklog, isFalse);
        expect(project.createdTimestamp, isNotNull);
      });

      test('create() without icon sets it to null', () {
        final project = ProjectDocument.create(
          clock: clock,
          title: 'Project without icon',
        );

        expect(project.icon, isNull);
      });

      test('constructor creates empty document', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        expect(project.id, equals('proj-1'));
        expect(project.title, isEmpty);
        expect(project.isArchived, isFalse);
      });
    });

    group('core fields', () {
      test('title can be set and retrieved', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.title = 'Updated Title';
        expect(project.title, equals('Updated Title'));
      });

      test('isArchived can be set', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.isArchived = true;
        expect(project.isArchived, isTrue);
      });

      test('isHiddenFromMenu can be set', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.isHiddenFromMenu = true;
        expect(project.isHiddenFromMenu, isTrue);
      });

      test('isEnableBacklog can be set', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.isEnableBacklog = true;
        expect(project.isEnableBacklog, isTrue);
      });
    });

    group('task lists', () {
      test('taskIds default to empty list', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        expect(project.taskIds, isEmpty);
      });

      test('addTask adds to taskIds', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.addTask('task-1');
        project.addTask('task-2');

        expect(project.taskIds, equals(['task-1', 'task-2']));
      });

      test('addTask with toBacklog adds to backlogTaskIds', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.addTask('task-1', toBacklog: true);

        expect(project.taskIds, isEmpty);
        expect(project.backlogTaskIds, equals(['task-1']));
      });

      test('addTask does not add duplicates', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.addTask('task-1');
        project.addTask('task-1');

        expect(project.taskIds, equals(['task-1']));
      });

      test('removeTask removes from both lists', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.addTask('task-1');
        project.addTask('task-2', toBacklog: true);

        project.removeTask('task-1');
        project.removeTask('task-2');

        expect(project.taskIds, isEmpty);
        expect(project.backlogTaskIds, isEmpty);
      });

      test('moveTaskToBacklog moves task from main to backlog', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.addTask('task-1');
        expect(project.taskIds, contains('task-1'));

        project.moveTaskToBacklog('task-1');

        expect(project.taskIds, isEmpty);
        expect(project.backlogTaskIds, contains('task-1'));
      });

      test('moveTaskFromBacklog moves task from backlog to main', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.addTask('task-1', toBacklog: true);
        expect(project.backlogTaskIds, contains('task-1'));

        project.moveTaskFromBacklog('task-1');

        expect(project.backlogTaskIds, isEmpty);
        expect(project.taskIds, contains('task-1'));
      });
    });

    group('theme', () {
      test('theme defaults to empty map', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        expect(project.theme, isEmpty);
      });

      test('primaryColor can be set via theme', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.primaryColor = '#FF5722';

        expect(project.primaryColor, equals('#FF5722'));
        expect(project.theme['primary'], equals('#FF5722'));
      });

      test('primaryColor can be cleared', () {
        final project = ProjectDocument(id: 'proj-1', clock: clock);

        project.primaryColor = '#FF5722';
        project.primaryColor = null;

        expect(project.primaryColor, isNull);
        expect(project.theme.containsKey('primary'), isFalse);
      });
    });

    group('soft delete', () {
      test('delete() marks project as deleted', () {
        final project = ProjectDocument.create(clock: clock, title: 'Test');

        expect(project.isDeleted, isFalse);

        project.delete();

        expect(project.isDeleted, isTrue);
      });

      test('restore() undeletes project', () {
        final project = ProjectDocument.create(clock: clock, title: 'Test');
        project.delete();

        project.restore();

        expect(project.isDeleted, isFalse);
      });
    });

    group('toModel', () {
      test('converts to ProjectModel correctly', () {
        final project = ProjectDocument.create(
          clock: clock,
          title: 'Test Project',
          icon: '🚀',
        );
        project.primaryColor = '#4CAF50';
        project.addTask('task-1');
        project.addTask('task-2');
        project.addTask('task-3', toBacklog: true);

        final model = project.toModel();

        expect(model.id, equals(project.id));
        expect(model.title, equals('Test Project'));
        expect(model.icon, equals('🚀'));
        expect(model.primaryColor, equals('#4CAF50'));
        expect(model.taskCount, equals(2));
        expect(model.backlogCount, equals(1));
        expect(model.totalTaskCount, equals(3));
        expect(model.isDeleted, isFalse);
      });
    });
  });
}
