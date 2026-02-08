import 'package:flutter_test/flutter_test.dart';
import 'package:avodah/core/crdt/hlc.dart';
import 'package:avodah/core/crdt/lww_set.dart';

void main() {
  group('LWWSet', () {
    late HybridLogicalClock clock;

    setUp(() {
      var time = 1000;
      clock = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time++,
      );
    });

    test('starts empty', () {
      final set = LWWSet<String>(clock: clock);

      expect(set.isEmpty, true);
      expect(set.isNotEmpty, false);
      expect(set.length, 0);
      expect(set.elements, isEmpty);
    });

    test('add inserts element', () {
      final set = LWWSet<String>(clock: clock);

      set.add('a');

      expect(set.contains('a'), true);
      expect(set.length, 1);
      expect(set.elements, {'a'});
    });

    test('add returns timestamp', () {
      final set = LWWSet<String>(clock: clock);

      final ts = set.add('item');

      expect(ts, isNotNull);
      expect(set.getElementState('item')?.add, ts);
    });

    test('remove removes element', () {
      final set = LWWSet<String>(clock: clock);

      set.add('a');
      set.remove('a');

      expect(set.contains('a'), false);
      expect(set.isEmpty, true);
    });

    test('add after remove re-adds element', () {
      final set = LWWSet<String>(clock: clock);

      set.add('a');
      set.remove('a');
      set.add('a');

      expect(set.contains('a'), true);
    });

    test('addAll adds multiple elements', () {
      final set = LWWSet<String>(clock: clock);

      set.addAll(['a', 'b', 'c']);

      expect(set.elements, {'a', 'b', 'c'});
    });

    test('removeAll removes multiple elements', () {
      final set = LWWSet<String>(clock: clock);

      set.addAll(['a', 'b', 'c']);
      set.removeAll(['a', 'c']);

      expect(set.elements, {'b'});
    });

    test('merge combines add operations', () {
      var time1 = 1000;
      var time2 = 1000;

      final clock1 = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time1++,
      );
      final clock2 = HybridLogicalClock(
        nodeId: 'node-2',
        physicalTimeFn: () => time2++,
      );

      final set1 = LWWSet<String>(clock: clock1);
      final set2 = LWWSet<String>(clock: clock2);

      set1.add('a');
      set2.add('b');

      set1.merge(set2);

      expect(set1.elements, {'a', 'b'});
    });

    test('merge handles concurrent add and remove', () {
      var time1 = 1000;
      var time2 = 2000; // Node 2 is ahead

      final clock1 = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time1++,
      );
      final clock2 = HybridLogicalClock(
        nodeId: 'node-2',
        physicalTimeFn: () => time2++,
      );

      final set1 = LWWSet<String>(clock: clock1);
      final set2 = LWWSet<String>(clock: clock2);

      // Node 1 adds
      set1.add('item');
      // Node 2 removes (with later timestamp)
      set2.add('item');
      set2.remove('item');

      set1.merge(set2);

      // Remove wins because it has later timestamp
      expect(set1.contains('item'), false);
    });

    test('merge add wins over earlier remove', () {
      var time1 = 2000; // Node 1 is ahead
      var time2 = 1000;

      final clock1 = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time1++,
      );
      final clock2 = HybridLogicalClock(
        nodeId: 'node-2',
        physicalTimeFn: () => time2++,
      );

      final set1 = LWWSet<String>(clock: clock1);
      final set2 = LWWSet<String>(clock: clock2);

      // Node 2 removes first (earlier timestamp)
      set2.add('item');
      set2.remove('item');
      // Node 1 adds later
      set1.add('item');

      set1.merge(set2);

      // Add wins because it has later timestamp
      expect(set1.contains('item'), true);
    });

    test('merge returns changed elements', () {
      var time1 = 1000;
      var time2 = 2000;

      final clock1 = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time1++,
      );
      final clock2 = HybridLogicalClock(
        nodeId: 'node-2',
        physicalTimeFn: () => time2++,
      );

      final set1 = LWWSet<String>(clock: clock1);
      final set2 = LWWSet<String>(clock: clock2);

      set1.add('existing');
      set2.add('new');

      final changed = set1.merge(set2);

      expect(changed, {'new'});
    });

    test('mergeElement updates single element', () {
      final set = LWWSet<String>(clock: clock);

      final addTs = HybridTimestamp(
        physicalTime: 2000,
        counter: 0,
        nodeId: 'node-2',
      );

      final changed = set.mergeElement('item', addTimestamp: addTs);

      expect(changed, true);
      expect(set.contains('item'), true);
    });

    test('toState and fromState round-trip', () {
      final set1 = LWWSet<String>(clock: clock);

      set1.add('a');
      set1.add('b');
      set1.remove('b');
      set1.add('c');

      final state = set1.toState();
      final set2 = LWWSet<String>.fromState(clock: clock, state: state);

      expect(set2.elements, set1.elements);
      expect(set2.contains('a'), true);
      expect(set2.contains('b'), false);
      expect(set2.contains('c'), true);
    });

    test('copy creates independent set', () {
      final set1 = LWWSet<String>(clock: clock);

      set1.add('a');
      final set2 = set1.copy();
      set1.add('b');

      expect(set1.elements, {'a', 'b'});
      expect(set2.elements, {'a'});
    });

    test('getElementState returns timestamps', () {
      final set = LWWSet<String>(clock: clock);

      set.add('item');
      final state = set.getElementState('item');

      expect(state?.add, isNotNull);
      expect(state?.remove, isNull);

      set.remove('item');
      final stateAfterRemove = set.getElementState('item');

      expect(stateAfterRemove?.add, isNotNull);
      expect(stateAfterRemove?.remove, isNotNull);
    });

    test('works with integer elements', () {
      final set = LWWSet<int>(clock: clock);

      set.addAll([1, 2, 3, 4, 5]);
      set.remove(3);

      expect(set.elements, {1, 2, 4, 5});
    });

    test('concurrent adds to same element from different nodes', () {
      var time = 1000;

      final clock1 = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time,
      );
      final clock2 = HybridLogicalClock(
        nodeId: 'node-2',
        physicalTimeFn: () => time,
      );

      final set1 = LWWSet<String>(clock: clock1);
      final set2 = LWWSet<String>(clock: clock2);

      // Both add the same element at the same time
      set1.add('shared');
      set2.add('shared');

      set1.merge(set2);

      // Element should be present
      expect(set1.contains('shared'), true);
    });
  });
}
