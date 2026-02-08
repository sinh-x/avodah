import 'package:flutter_test/flutter_test.dart';
import 'package:avodah/core/crdt/g_counter.dart';

void main() {
  group('GCounter', () {
    test('starts at zero', () {
      final counter = GCounter(nodeId: 'node-1');

      expect(counter.value, 0);
      expect(counter.localValue, 0);
    });

    test('increment increases value', () {
      final counter = GCounter(nodeId: 'node-1');

      counter.increment();

      expect(counter.value, 1);
      expect(counter.localValue, 1);
    });

    test('increment by amount', () {
      final counter = GCounter(nodeId: 'node-1');

      counter.increment(5);
      counter.increment(3);

      expect(counter.value, 8);
    });

    test('throws on negative increment', () {
      final counter = GCounter(nodeId: 'node-1');

      expect(
        () => counter.increment(-1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('merge combines counters from different nodes', () {
      final counter1 = GCounter(nodeId: 'node-1');
      final counter2 = GCounter(nodeId: 'node-2');

      counter1.increment(5);
      counter2.increment(3);

      counter1.merge(counter2);

      expect(counter1.value, 8); // 5 + 3
      expect(counter1.localValue, 5);
    });

    test('merge takes max of each node', () {
      final counter1 = GCounter(nodeId: 'node-1');
      final counter2 = GCounter(nodeId: 'node-2');

      counter1.increment(10);
      counter2.increment(5);

      // counter2 also has outdated view of node-1
      final counter2WithStale = GCounter.fromState(
        nodeId: 'node-2',
        state: {'node-1': 3, 'node-2': 5},
      );

      counter1.merge(counter2WithStale);

      // node-1 should keep its higher value (10), take node-2's value (5)
      expect(counter1.value, 15);
    });

    test('merge is commutative', () {
      final counter1 = GCounter(nodeId: 'node-1');
      final counter2 = GCounter(nodeId: 'node-2');

      counter1.increment(5);
      counter2.increment(3);

      final copy1 = counter1.copy();
      final copy2 = counter2.copy();

      counter1.merge(counter2);
      copy2.merge(copy1);

      expect(counter1.value, copy2.value);
    });

    test('merge is associative', () {
      final a = GCounter(nodeId: 'a');
      final b = GCounter(nodeId: 'b');
      final c = GCounter(nodeId: 'c');

      a.increment(1);
      b.increment(2);
      c.increment(3);

      // (a merge b) merge c
      final ab = a.copy();
      ab.merge(b);
      ab.merge(c);

      // a merge (b merge c)
      final bc = b.copy();
      bc.merge(c);
      final result = a.copy();
      result.merge(bc);

      expect(ab.value, result.value);
    });

    test('merge is idempotent', () {
      final counter1 = GCounter(nodeId: 'node-1');
      final counter2 = GCounter(nodeId: 'node-2');

      counter1.increment(5);
      counter2.increment(3);

      counter1.merge(counter2);
      final afterFirst = counter1.value;

      counter1.merge(counter2);
      final afterSecond = counter1.value;

      expect(afterFirst, afterSecond);
    });

    test('merge returns true when value changes', () {
      final counter1 = GCounter(nodeId: 'node-1');
      final counter2 = GCounter(nodeId: 'node-2');

      counter2.increment(5);

      final changed = counter1.merge(counter2);

      expect(changed, true);
    });

    test('merge returns false when value unchanged', () {
      final counter1 = GCounter(nodeId: 'node-1');
      final counter2 = GCounter(nodeId: 'node-2');

      counter1.increment(5);

      final changed = counter1.merge(counter2);

      expect(changed, false);
    });

    test('mergeState works with raw map', () {
      final counter = GCounter(nodeId: 'node-1');
      counter.increment(2);

      final changed = counter.mergeState({'node-2': 5, 'node-3': 3});

      expect(changed, true);
      expect(counter.value, 10); // 2 + 5 + 3
    });

    test('toState returns immutable copy', () {
      final counter = GCounter(nodeId: 'node-1');
      counter.increment(5);

      final state = counter.toState();

      expect(state['node-1'], 5);
      expect(() => state['node-1'] = 10, throwsA(anything));
    });

    test('copy creates independent counter', () {
      final counter1 = GCounter(nodeId: 'node-1');
      counter1.increment(5);

      final counter2 = counter1.copy();
      counter1.increment(3);

      expect(counter1.value, 8);
      expect(counter2.value, 5);
    });

    test('fromState initializes correctly', () {
      final counter = GCounter.fromState(
        nodeId: 'node-1',
        state: {'node-1': 5, 'node-2': 3, 'node-3': 2},
      );

      expect(counter.value, 10);
      expect(counter.localValue, 5);
    });

    test('fromState ensures node entry exists', () {
      final counter = GCounter.fromState(
        nodeId: 'node-new',
        state: {'node-1': 5},
      );

      counter.increment(1);
      expect(counter.localValue, 1);
      expect(counter.value, 6);
    });
  });

  group('PNCounter', () {
    test('starts at zero', () {
      final counter = PNCounter(nodeId: 'node-1');

      expect(counter.value, 0);
    });

    test('increment increases value', () {
      final counter = PNCounter(nodeId: 'node-1');

      counter.increment(5);

      expect(counter.value, 5);
    });

    test('decrement decreases value', () {
      final counter = PNCounter(nodeId: 'node-1');

      counter.increment(10);
      counter.decrement(3);

      expect(counter.value, 7);
    });

    test('can go negative', () {
      final counter = PNCounter(nodeId: 'node-1');

      counter.decrement(5);

      expect(counter.value, -5);
    });

    test('throws on negative increment', () {
      final counter = PNCounter(nodeId: 'node-1');

      expect(() => counter.increment(-1), throwsA(isA<ArgumentError>()));
    });

    test('throws on negative decrement', () {
      final counter = PNCounter(nodeId: 'node-1');

      expect(() => counter.decrement(-1), throwsA(isA<ArgumentError>()));
    });

    test('merge combines counters', () {
      final counter1 = PNCounter(nodeId: 'node-1');
      final counter2 = PNCounter(nodeId: 'node-2');

      counter1.increment(10);
      counter1.decrement(2);
      counter2.increment(5);
      counter2.decrement(1);

      counter1.merge(counter2);

      // (10-2) + (5-1) = 8 + 4 = 12
      expect(counter1.value, 12);
    });

    test('merge is commutative', () {
      final counter1 = PNCounter(nodeId: 'node-1');
      final counter2 = PNCounter(nodeId: 'node-2');

      counter1.increment(10);
      counter1.decrement(3);
      counter2.increment(5);
      counter2.decrement(1);

      final copy1 = counter1.copy();
      final copy2 = counter2.copy();

      counter1.merge(counter2);
      copy2.merge(copy1);

      expect(counter1.value, copy2.value);
    });

    test('merge returns true when value changes', () {
      final counter1 = PNCounter(nodeId: 'node-1');
      final counter2 = PNCounter(nodeId: 'node-2');

      counter2.increment(5);

      final changed = counter1.merge(counter2);

      expect(changed, true);
    });

    test('merge returns false when value unchanged', () {
      final counter1 = PNCounter(nodeId: 'node-1');
      final counter2 = PNCounter(nodeId: 'node-2');

      counter1.increment(5);

      final changed = counter1.merge(counter2);

      expect(changed, false);
    });

    test('mergeState works with raw maps', () {
      final counter = PNCounter(nodeId: 'node-1');
      counter.increment(5);

      final changed = counter.mergeState(
        positive: {'node-2': 10},
        negative: {'node-2': 2},
      );

      expect(changed, true);
      expect(counter.value, 13); // 5 + (10-2)
    });

    test('toState returns both positive and negative', () {
      final counter = PNCounter(nodeId: 'node-1');
      counter.increment(10);
      counter.decrement(3);

      final state = counter.toState();

      expect(state.positive['node-1'], 10);
      expect(state.negative['node-1'], 3);
    });

    test('copy creates independent counter', () {
      final counter1 = PNCounter(nodeId: 'node-1');
      counter1.increment(10);

      final counter2 = counter1.copy();
      counter1.decrement(5);

      expect(counter1.value, 5);
      expect(counter2.value, 10);
    });

    test('fromState initializes correctly', () {
      final counter = PNCounter.fromState(
        nodeId: 'node-1',
        positive: {'node-1': 10, 'node-2': 5},
        negative: {'node-1': 2, 'node-2': 1},
      );

      // (10+5) - (2+1) = 15 - 3 = 12
      expect(counter.value, 12);
    });

    test('concurrent increments and decrements merge correctly', () {
      final counter1 = PNCounter(nodeId: 'node-1');
      final counter2 = PNCounter(nodeId: 'node-2');

      // Concurrent operations
      counter1.increment(100);
      counter2.decrement(30);

      counter1.merge(counter2);
      counter2.merge(counter1);

      // Both should have same final value
      expect(counter1.value, 70);
      expect(counter2.value, 70);
    });
  });
}
