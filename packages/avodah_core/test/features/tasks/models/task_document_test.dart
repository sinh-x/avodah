import 'package:avodah_core/avodah_core.dart';
import 'package:test/test.dart';

void main() {
  group('TaskDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('creation', () {
      test('create() generates UUID and sets initial fields', () {
        final task = TaskDocument.create(
          clock: clock,
          title: 'My Task',
          projectId: 'project-1',
        );

        expect(task.id, isNotEmpty);
        expect(task.title, equals('My Task'));
        expect(task.projectId, equals('project-1'));
        expect(task.isDone, isFalse);
        expect(task.timeSpent, equals(0));
        expect(task.timeEstimate, equals(0));
        expect(task.createdTimestamp, isNotNull);
      });

      test('create() without projectId sets it to null', () {
        final task = TaskDocument.create(
          clock: clock,
          title: 'Task without project',
        );

        expect(task.projectId, isNull);
      });

      test('constructor creates empty document', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        expect(task.id, equals('task-1'));
        expect(task.title, isEmpty);
        expect(task.isDone, isFalse);
      });
    });

    group('core fields', () {
      test('title can be set and retrieved', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        task.title = 'Updated Title';
        expect(task.title, equals('Updated Title'));
      });

      test('projectId can be set and cleared', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        task.projectId = 'proj-1';
        expect(task.projectId, equals('proj-1'));

        task.projectId = null;
        expect(task.projectId, isNull);
      });

      test('isDone setter also sets doneOn', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        expect(task.doneOn, isNull);

        task.isDone = true;

        expect(task.isDone, isTrue);
        expect(task.doneOn, isNotNull);
      });

      test('markDone() sets isDone and doneOn', () {
        final task = TaskDocument.create(clock: clock, title: 'Test');

        task.markDone();

        expect(task.isDone, isTrue);
        expect(task.doneOn, isNotNull);
      });

      test('markUndone() clears isDone and doneOn', () {
        final task = TaskDocument.create(clock: clock, title: 'Test');
        task.markDone();

        task.markUndone();

        expect(task.isDone, isFalse);
        expect(task.doneOn, isNull);
      });
    });

    group('time tracking', () {
      test('timeSpent and timeEstimate default to 0', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        expect(task.timeSpent, equals(0));
        expect(task.timeEstimate, equals(0));
      });

      test('timeSpent can be set', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        task.timeSpent = 3600000; // 1 hour
        expect(task.timeSpent, equals(3600000));
      });

      test('timeSpentOnDay tracks time per day', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        task.timeSpentOnDay = {'2026-02-08': 3600000, '2026-02-09': 1800000};

        expect(task.timeSpentOnDay['2026-02-08'], equals(3600000));
        expect(task.timeSpentOnDay['2026-02-09'], equals(1800000));
      });

      test('addTimeOnDay adds time and updates total', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.timeSpent = 1000;

        task.addTimeOnDay('2026-02-09', 500);

        expect(task.timeSpentOnDay['2026-02-09'], equals(500));
        expect(task.timeSpent, equals(1500));

        task.addTimeOnDay('2026-02-09', 300);
        expect(task.timeSpentOnDay['2026-02-09'], equals(800));
        expect(task.timeSpent, equals(1800));
      });
    });

    group('due dates', () {
      test('dueWithTime can be set', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        final due = DateTime(2026, 3, 15, 14, 30);

        task.dueWithTime = due;

        expect(task.dueWithTime, equals(due));
      });

      test('dueDay can be set as string', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        task.dueDay = '2026-03-15';

        expect(task.dueDay, equals('2026-03-15'));
      });

      test('setDueDate formats date correctly', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        task.setDueDate(DateTime(2026, 3, 5));

        expect(task.dueDay, equals('2026-03-05'));
      });

      test('isOverdue returns true for past due dates', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.dueDay = '2020-01-01'; // Past date

        expect(task.isOverdue, isTrue);
      });

      test('isOverdue returns false for future due dates', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.dueDay = '2030-12-31'; // Future date

        expect(task.isOverdue, isFalse);
      });

      test('isOverdue returns false for done tasks', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.dueDay = '2020-01-01'; // Past date
        task.isDone = true;

        expect(task.isOverdue, isFalse);
      });

      test('isOverdue returns false for tasks without due date', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        expect(task.isOverdue, isFalse);
      });
    });

    group('tags', () {
      test('tagIds defaults to empty list', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        expect(task.tagIds, isEmpty);
      });

      test('tagIds can be set', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        task.tagIds = ['tag-1', 'tag-2'];

        expect(task.tagIds, equals(['tag-1', 'tag-2']));
      });

      test('addTag adds new tag', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.tagIds = ['tag-1'];

        task.addTag('tag-2');

        expect(task.tagIds, equals(['tag-1', 'tag-2']));
      });

      test('addTag does not duplicate existing tag', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.tagIds = ['tag-1'];

        task.addTag('tag-1');

        expect(task.tagIds, equals(['tag-1']));
      });

      test('removeTag removes tag', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.tagIds = ['tag-1', 'tag-2'];

        task.removeTag('tag-1');

        expect(task.tagIds, equals(['tag-2']));
      });
    });

    group('reminders', () {
      test('remindAt can be set', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        final remind = DateTime(2026, 3, 15, 9, 0);

        task.remindAt = remind;
        task.reminderId = 'reminder-1';

        expect(task.remindAt, equals(remind));
        expect(task.reminderId, equals('reminder-1'));
      });
    });

    group('repeats', () {
      test('isRepeating returns false by default', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        expect(task.isRepeating, isFalse);
      });

      test('isRepeating returns true when repeatCfgId is set', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.repeatCfgId = 'repeat-cfg-1';

        expect(task.isRepeating, isTrue);
      });
    });

    group('issue integration', () {
      test('hasIssueLink returns false by default', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        expect(task.hasIssueLink, isFalse);
      });

      test('linkToIssue sets all issue fields', () {
        final task = TaskDocument(id: 'task-1', clock: clock);

        task.linkToIssue(
          issueId: 'JIRA-123',
          providerId: 'jira-integration-1',
          type: IssueType.jira,
          points: 5,
        );

        expect(task.issueId, equals('JIRA-123'));
        expect(task.issueProviderId, equals('jira-integration-1'));
        expect(task.issueType, equals(IssueType.jira));
        expect(task.issuePoints, equals(5));
        expect(task.issueLastUpdated, isNotNull);
        expect(task.hasIssueLink, isTrue);
      });

      test('unlinkIssue clears all issue fields', () {
        final task = TaskDocument(id: 'task-1', clock: clock);
        task.linkToIssue(
          issueId: 'GH-456',
          providerId: 'github-1',
          type: IssueType.github,
        );

        task.unlinkIssue();

        expect(task.issueId, isNull);
        expect(task.issueProviderId, isNull);
        expect(task.issueType, isNull);
        expect(task.hasIssueLink, isFalse);
      });

      test('IssueType enum converts correctly', () {
        expect(IssueType.jira.toValue(), equals('JIRA'));
        expect(IssueType.github.toValue(), equals('GITHUB'));

        expect(IssueType.fromValue('JIRA'), equals(IssueType.jira));
        expect(IssueType.fromValue('GITHUB'), equals(IssueType.github));
        expect(IssueType.fromValue(null), isNull);
        expect(IssueType.fromValue('UNKNOWN'), isNull);
      });
    });

    group('merge operations', () {
      test('merging tasks updates fields with higher timestamp', () {
        final clock1 = HybridLogicalClock(nodeId: 'phone');
        final clock2 = HybridLogicalClock(nodeId: 'laptop');

        final task1 = TaskDocument.create(
          clock: clock1,
          title: 'Original',
        );

        // Serialize and recreate on "laptop"
        final json = task1.toJson();
        final state = CrdtDocument.stateFromJson(json);
        final task2 = TaskDocument.fromState(
          id: task1.id,
          clock: clock2,
          state: state,
        );

        // Phone changes title
        task1.title = 'Phone Title';

        // Laptop changes projectId (different field)
        task2.projectId = 'laptop-project';

        // Merge laptop into phone
        task1.merge(task2);

        expect(task1.title, equals('Phone Title'));
        expect(task1.projectId, equals('laptop-project'));
      });

      test('concurrent edits on same field - last writer wins', () {
        // Use realistic timestamps close to each other
        final baseTime = DateTime.now().millisecondsSinceEpoch;
        var time1 = baseTime;
        var time2 = baseTime;
        final clock1 = HybridLogicalClock(
          nodeId: 'node-1',
          physicalTimeFn: () => time1,
        );
        final clock2 = HybridLogicalClock(
          nodeId: 'node-2',
          physicalTimeFn: () => time2,
        );

        final task1 = TaskDocument(id: 'task-1', clock: clock1);
        final task2 = TaskDocument(id: 'task-1', clock: clock2);

        // Task1 sets title at baseTime
        task1.title = 'First';

        // Task2 sets title 1 second later (within drift tolerance)
        time2 = baseTime + 1000;
        task2.title = 'Second';

        // Merge task2 into task1
        task1.merge(task2);

        expect(task1.title, equals('Second'));
      });

      test('offline sync scenario preserves independent changes', () {
        final clock1 = HybridLogicalClock(nodeId: 'device-a');
        final clock2 = HybridLogicalClock(nodeId: 'device-b');

        // Create task on device A
        final taskA = TaskDocument.create(
          clock: clock1,
          title: 'Shared Task',
        );
        taskA.timeEstimate = 3600000;

        // Sync to device B
        final json = taskA.toJson();
        final state = CrdtDocument.stateFromJson(json);
        final taskB = TaskDocument.fromState(
          id: taskA.id,
          clock: clock2,
          state: state,
        );

        // Device A marks done (offline)
        taskA.markDone();

        // Device B adds tags (offline)
        taskB.addTag('urgent');
        taskB.addTag('work');

        // Come back online - merge both ways
        taskA.merge(taskB);
        taskB.merge(taskA);

        // Both should have: isDone=true, tags=['urgent', 'work']
        expect(taskA.isDone, isTrue);
        expect(taskA.tagIds, containsAll(['urgent', 'work']));

        expect(taskB.isDone, isTrue);
        expect(taskB.tagIds, containsAll(['urgent', 'work']));
      });
    });

    group('toModel()', () {
      test('converts to TaskModel correctly', () {
        final task = TaskDocument.create(
          clock: clock,
          title: 'Test Task',
          projectId: 'proj-1',
        );
        task.timeSpent = 1800000; // 30 min
        task.timeEstimate = 3600000; // 1 hour
        task.tagIds = ['tag-1'];
        task.dueDay = '2030-12-31';

        final model = task.toModel();

        expect(model.id, equals(task.id));
        expect(model.title, equals('Test Task'));
        expect(model.projectId, equals('proj-1'));
        expect(model.isDone, isFalse);
        expect(model.isDeleted, isFalse);
        expect(model.timeSpent, equals(const Duration(minutes: 30)));
        expect(model.timeEstimate, equals(const Duration(hours: 1)));
        expect(model.tagIds, equals(['tag-1']));
        expect(model.isOverdue, isFalse);
        expect(model.progress, equals(0.5));
      });

      test('TaskModel.dueDate returns effective due date', () {
        final task = TaskDocument.create(clock: clock, title: 'Test');
        task.dueDay = '2026-03-15';

        final model = task.toModel();

        expect(model.dueDate, equals(DateTime(2026, 3, 15)));
      });

      test('TaskModel.progress returns correct percentage', () {
        final task = TaskDocument.create(clock: clock, title: 'Test');
        task.timeEstimate = 1000;

        expect(task.toModel().progress, equals(0.0));

        task.timeSpent = 500;
        expect(task.toModel().progress, equals(0.5));

        task.timeSpent = 1500; // Over estimate
        expect(task.toModel().progress, equals(1.0)); // Clamped to 1.0
      });
    });

    group('toDriftCompanion()', () {
      test('converts to TasksCompanion correctly', () {
        final task = TaskDocument.create(
          clock: clock,
          title: 'Test',
          projectId: 'proj-1',
        );
        task.tagIds = ['tag-1'];
        task.dueDay = '2026-03-15';

        final companion = task.toDriftCompanion();

        expect(companion.id.value, equals(task.id));
        expect(companion.title.value, equals('Test'));
        expect(companion.projectId.value, equals('proj-1'));
        expect(companion.isDone.value, isFalse);
        expect(companion.tagIds.value, equals('["tag-1"]'));
        expect(companion.dueDay.value, equals('2026-03-15'));
        expect(companion.crdtState.value, isNotEmpty);
      });
    });

    group('soft delete', () {
      test('delete() marks task as deleted', () {
        final task = TaskDocument.create(clock: clock, title: 'Test');

        task.delete();

        expect(task.isDeleted, isTrue);
        expect(task.toModel().isDeleted, isTrue);
      });

      test('restore() undeletes task', () {
        final task = TaskDocument.create(clock: clock, title: 'Test');
        task.delete();

        task.restore();

        expect(task.isDeleted, isFalse);
      });
    });
  });
}
