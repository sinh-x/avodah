import 'package:flutter_test/flutter_test.dart';
import 'package:avodah_core/crdt/hlc.dart';

void main() {
  group('HybridTimestamp', () {
    test('creates timestamp with all fields', () {
      final ts = HybridTimestamp(
        physicalTime: 1000,
        counter: 5,
        nodeId: 'node-1',
      );

      expect(ts.physicalTime, 1000);
      expect(ts.counter, 5);
      expect(ts.nodeId, 'node-1');
    });

    test('creates zero timestamp', () {
      final ts = HybridTimestamp.zero('node-1');

      expect(ts.physicalTime, 0);
      expect(ts.counter, 0);
      expect(ts.nodeId, 'node-1');
    });

    test('packs and parses correctly', () {
      final original = HybridTimestamp(
        physicalTime: 1707400000000,
        counter: 42,
        nodeId: 'device-abc-123',
      );

      final packed = original.pack();
      final parsed = HybridTimestamp.parse(packed);

      expect(parsed.physicalTime, original.physicalTime);
      expect(parsed.counter, original.counter);
      expect(parsed.nodeId, original.nodeId);
    });

    test('handles nodeId with dashes', () {
      final ts = HybridTimestamp(
        physicalTime: 1000,
        counter: 0,
        nodeId: 'node-with-many-dashes',
      );

      final parsed = HybridTimestamp.parse(ts.pack());
      expect(parsed.nodeId, 'node-with-many-dashes');
    });

    test('throws on invalid format', () {
      expect(
        () => HybridTimestamp.parse('invalid'),
        throwsA(isA<FormatException>()),
      );
    });

    group('comparison', () {
      test('compares by physical time first', () {
        final ts1 = HybridTimestamp(physicalTime: 1000, counter: 0, nodeId: 'a');
        final ts2 = HybridTimestamp(physicalTime: 2000, counter: 0, nodeId: 'a');

        expect(ts1 < ts2, true);
        expect(ts2 > ts1, true);
        expect(ts1.compareTo(ts2), lessThan(0));
      });

      test('compares by counter when physical time equal', () {
        final ts1 = HybridTimestamp(physicalTime: 1000, counter: 1, nodeId: 'a');
        final ts2 = HybridTimestamp(physicalTime: 1000, counter: 2, nodeId: 'a');

        expect(ts1 < ts2, true);
        expect(ts2 > ts1, true);
      });

      test('compares by nodeId when time and counter equal', () {
        final ts1 = HybridTimestamp(physicalTime: 1000, counter: 1, nodeId: 'a');
        final ts2 = HybridTimestamp(physicalTime: 1000, counter: 1, nodeId: 'b');

        expect(ts1 < ts2, true);
        expect(ts2 > ts1, true);
      });

      test('equality works correctly', () {
        final ts1 = HybridTimestamp(physicalTime: 1000, counter: 1, nodeId: 'a');
        final ts2 = HybridTimestamp(physicalTime: 1000, counter: 1, nodeId: 'a');
        final ts3 = HybridTimestamp(physicalTime: 1000, counter: 2, nodeId: 'a');

        expect(ts1 == ts2, true);
        expect(ts1 == ts3, false);
        expect(ts1 <= ts2, true);
        expect(ts1 >= ts2, true);
      });
    });
  });

  group('HybridLogicalClock', () {
    test('generates monotonically increasing timestamps', () {
      var time = 1000;
      final clock = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time,
      );

      final ts1 = clock.now();
      final ts2 = clock.now();
      final ts3 = clock.now();

      expect(ts1 < ts2, true);
      expect(ts2 < ts3, true);
    });

    test('increments counter when physical time unchanged', () {
      var time = 1000;
      final clock = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time,
      );

      final ts1 = clock.now();
      final ts2 = clock.now();

      expect(ts1.physicalTime, ts2.physicalTime);
      expect(ts2.counter, ts1.counter + 1);
    });

    test('resets counter when physical time advances', () {
      var time = 1000;
      final clock = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time,
      );

      clock.now();
      clock.now();
      time = 2000;
      final ts = clock.now();

      expect(ts.physicalTime, 2000);
      expect(ts.counter, 0);
    });

    test('receive updates clock from remote timestamp', () {
      var time = 1000;
      final clock = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time,
      );

      final localTs = clock.now();

      // Remote timestamp is ahead
      final remoteTs = HybridTimestamp(
        physicalTime: 2000,
        counter: 5,
        nodeId: 'node-2',
      );

      clock.receive(remoteTs);
      final afterReceive = clock.now();

      expect(afterReceive > localTs, true);
      expect(afterReceive > remoteTs, true);
    });

    test('receive handles concurrent timestamps', () {
      var time = 1000;
      final clock = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time,
      );

      // Local and remote at same physical time
      clock.now(); // counter = 0
      clock.now(); // counter = 1

      final remoteTs = HybridTimestamp(
        physicalTime: 1000,
        counter: 3,
        nodeId: 'node-2',
      );

      clock.receive(remoteTs);
      final afterReceive = clock.now();

      expect(afterReceive.physicalTime, 1000);
      expect(afterReceive.counter, greaterThan(3));
    });

    test('throws on excessive local drift', () {
      var time = 5000;
      final clock = HybridLogicalClock(
        nodeId: 'node-1',
        maxDrift: 1000,
        physicalTimeFn: () => time,
      );

      // Generate a timestamp at time 5000
      clock.now();

      // Now simulate physical time going backwards (system clock adjusted)
      time = 1000;

      // Clock state is at 5000 but physical time is 1000
      // Drift = 5000 - 1000 = 4000 > maxDrift (1000)
      expect(() => clock.now(), throwsA(isA<ClockDriftException>()));
    });

    test('throws on excessive remote drift', () {
      var time = 1000;
      final clock = HybridLogicalClock(
        nodeId: 'node-1',
        maxDrift: 1000,
        physicalTimeFn: () => time,
      );

      final farFutureTs = HybridTimestamp(
        physicalTime: 100000,
        counter: 0,
        nodeId: 'node-2',
      );

      expect(
        () => clock.receive(farFutureTs),
        throwsA(isA<ClockDriftException>()),
      );
    });

    test('merge combines two clock states', () {
      var time1 = 1000;
      var time2 = 2000;

      final clock1 = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time1,
      );
      final clock2 = HybridLogicalClock(
        nodeId: 'node-2',
        physicalTimeFn: () => time2,
      );

      clock1.now();
      clock2.now();
      clock2.now();
      clock2.now();

      clock1.merge(clock2);

      final afterMerge = clock1.now();
      expect(afterMerge > clock2.lastTimestamp, true);
    });

    test('assigns correct nodeId to timestamps', () {
      final clock = HybridLogicalClock(nodeId: 'my-device');
      final ts = clock.now();

      expect(ts.nodeId, 'my-device');
    });
  });
}
