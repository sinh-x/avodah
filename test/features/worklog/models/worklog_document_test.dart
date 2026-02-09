import 'package:avodah/core/crdt/crdt.dart';
import 'package:avodah/features/worklog/models/worklog_document.dart';
import 'package:test/test.dart';

void main() {
  group('WorklogDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('creation', () {
      test('create() generates UUID and sets all fields', () {
        final start = DateTime.now().subtract(const Duration(hours: 1));
        final end = DateTime.now();

        final worklog = WorklogDocument.create(
          clock: clock,
          taskId: 'task-1',
          start: start.millisecondsSinceEpoch,
          end: end.millisecondsSinceEpoch,
          comment: 'Working on feature',
        );

        expect(worklog.id, isNotEmpty);
        expect(worklog.taskId, equals('task-1'));
        expect(worklog.startMs, equals(start.millisecondsSinceEpoch));
        expect(worklog.endMs, equals(end.millisecondsSinceEpoch));
        expect(worklog.durationMs, equals(end.millisecondsSinceEpoch - start.millisecondsSinceEpoch));
        expect(worklog.comment, equals('Working on feature'));
        expect(worklog.date, isNotEmpty);
        expect(worklog.createdMs, greaterThan(0));
      });

      test('fromTimer() creates from DateTime objects', () {
        final start = DateTime(2026, 2, 9, 10, 0);
        final end = DateTime(2026, 2, 9, 11, 30);

        final worklog = WorklogDocument.fromTimer(
          clock: clock,
          taskId: 'task-1',
          start: start,
          end: end,
        );

        expect(worklog.startTime.hour, equals(10));
        expect(worklog.endTime.hour, equals(11));
        expect(worklog.duration.inMinutes, equals(90));
      });

      test('constructor creates empty document', () {
        final worklog = WorklogDocument(id: 'wl-1', clock: clock);

        expect(worklog.id, equals('wl-1'));
        expect(worklog.taskId, isEmpty);
        expect(worklog.durationMs, equals(0));
      });
    });

    group('duration helpers', () {
      test('duration returns Duration object', () {
        final worklog = WorklogDocument(id: 'wl-1', clock: clock);
        worklog.durationMs = 3600000; // 1 hour

        expect(worklog.duration, equals(const Duration(hours: 1)));
      });

      test('formattedDuration formats hours and minutes', () {
        final worklog = WorklogDocument(id: 'wl-1', clock: clock);

        worklog.durationMs = 5400000; // 1.5 hours
        expect(worklog.formattedDuration, equals('1h 30m'));

        worklog.durationMs = 1800000; // 30 minutes
        expect(worklog.formattedDuration, equals('30m'));

        worklog.durationMs = 7200000; // 2 hours
        expect(worklog.formattedDuration, equals('2h 0m'));
      });

      test('hoursDecimal returns decimal hours', () {
        final worklog = WorklogDocument(id: 'wl-1', clock: clock);
        worklog.durationMs = 5400000; // 1.5 hours

        expect(worklog.hoursDecimal, equals(1.5));
      });

      test('updateEnd recalculates duration', () {
        final start = DateTime(2026, 2, 9, 10, 0);
        final end = DateTime(2026, 2, 9, 11, 0);

        final worklog = WorklogDocument.fromTimer(
          clock: clock,
          taskId: 'task-1',
          start: start,
          end: end,
        );

        expect(worklog.duration.inHours, equals(1));

        final newEnd = DateTime(2026, 2, 9, 12, 0);
        worklog.updateEnd(newEnd);

        expect(worklog.duration.inHours, equals(2));
      });
    });

    group('date handling', () {
      test('date is extracted from start time', () {
        final start = DateTime(2026, 2, 9, 14, 30);
        final end = DateTime(2026, 2, 9, 15, 30);

        final worklog = WorklogDocument.fromTimer(
          clock: clock,
          taskId: 'task-1',
          start: start,
          end: end,
        );

        expect(worklog.date, equals('2026-02-09'));
      });
    });

    group('Jira integration', () {
      test('isSyncedToJira returns false when no jiraWorklogId', () {
        final worklog = WorklogDocument(id: 'wl-1', clock: clock);

        expect(worklog.isSyncedToJira, isFalse);
        expect(worklog.jiraWorklogId, isNull);
      });

      test('linkToJira sets jiraWorklogId and updates timestamp', () {
        final worklog = WorklogDocument(id: 'wl-1', clock: clock);

        worklog.linkToJira('jira-12345');

        expect(worklog.isSyncedToJira, isTrue);
        expect(worklog.jiraWorklogId, equals('jira-12345'));
      });

      test('unlinkFromJira clears jiraWorklogId', () {
        final worklog = WorklogDocument(id: 'wl-1', clock: clock);
        worklog.linkToJira('jira-12345');

        worklog.unlinkFromJira();

        expect(worklog.isSyncedToJira, isFalse);
        expect(worklog.jiraWorklogId, isNull);
      });
    });

    group('soft delete', () {
      test('delete() marks worklog as deleted', () {
        final worklog = WorklogDocument.create(
          clock: clock,
          taskId: 'task-1',
          start: DateTime.now().millisecondsSinceEpoch - 3600000,
          end: DateTime.now().millisecondsSinceEpoch,
        );

        expect(worklog.isDeleted, isFalse);

        worklog.delete();

        expect(worklog.isDeleted, isTrue);
      });

      test('restore() undeletes worklog', () {
        final worklog = WorklogDocument.create(
          clock: clock,
          taskId: 'task-1',
          start: DateTime.now().millisecondsSinceEpoch - 3600000,
          end: DateTime.now().millisecondsSinceEpoch,
        );
        worklog.delete();

        worklog.restore();

        expect(worklog.isDeleted, isFalse);
      });
    });

    group('toModel', () {
      test('converts to WorklogModel correctly', () {
        final start = DateTime(2026, 2, 9, 10, 0);
        final end = DateTime(2026, 2, 9, 11, 30);

        final worklog = WorklogDocument.fromTimer(
          clock: clock,
          taskId: 'task-1',
          start: start,
          end: end,
          comment: 'Test comment',
        );
        worklog.linkToJira('jira-123');

        final model = worklog.toModel();

        expect(model.id, equals(worklog.id));
        expect(model.taskId, equals('task-1'));
        expect(model.duration.inMinutes, equals(90));
        expect(model.comment, equals('Test comment'));
        expect(model.isSyncedToJira, isTrue);
        expect(model.isDeleted, isFalse);
        expect(model.formattedDuration, equals('1h 30m'));
      });
    });
  });
}
