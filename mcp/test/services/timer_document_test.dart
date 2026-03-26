import 'package:avodah_core/avodah_core.dart';
import 'package:test/test.dart';

void main() {
  group('TimerDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('category', () {
      test('start() accepts optional category', () {
        final timer = TimerDocument.start(
          clock: clock,
          taskTitle: 'Working',
          category: 'Working',
        );

        expect(timer.category, equals('Working'));
        expect(timer.taskTitle, equals('Working'));
        expect(timer.isRunning, isTrue);
      });

      test('start() without category leaves it null', () {
        final timer = TimerDocument.start(
          clock: clock,
          taskTitle: 'Some work',
        );

        expect(timer.category, isNull);
      });

      test('stop() clears category', () {
        final timer = TimerDocument.start(
          clock: clock,
          taskTitle: 'Working',
          category: 'Working',
        );

        expect(timer.category, equals('Working'));

        timer.stop();

        expect(timer.category, isNull);
        expect(timer.isRunning, isFalse);
      });

      test('category can be set and changed', () {
        final timer = TimerDocument.start(
          clock: clock,
          taskTitle: 'Some work',
        );

        expect(timer.category, isNull);

        timer.category = 'Learning';

        expect(timer.category, equals('Learning'));

        timer.category = 'Meetings';

        expect(timer.category, equals('Meetings'));
      });
    });

    group('toModel', () {
      test('toModel includes category', () {
        final timer = TimerDocument.start(
          clock: clock,
          taskTitle: 'Working',
          category: 'Working',
        );

        final model = timer.toModel();

        expect(model.category, equals('Working'));
        expect(model.taskTitle, equals('Working'));
        expect(model.isRunning, isTrue);
      });

      test('toModel includes category as null when not set', () {
        final timer = TimerDocument.start(
          clock: clock,
          taskTitle: 'Some work',
        );

        final model = timer.toModel();

        expect(model.category, isNull);
      });
    });
  });
}