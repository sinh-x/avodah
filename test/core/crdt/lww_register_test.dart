import 'package:flutter_test/flutter_test.dart';
import 'package:avodah_core/crdt/hlc.dart';
import 'package:avodah_core/crdt/lww_register.dart';

void main() {
  group('LWWRegister', () {
    late HybridLogicalClock clock;

    setUp(() {
      var time = 1000;
      clock = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time++,
      );
    });

    test('starts with null value', () {
      final register = LWWRegister<String>(clock: clock);

      expect(register.value, isNull);
      expect(register.timestamp, isNull);
      expect(register.hasValue, false);
    });

    test('set updates value and timestamp', () {
      final register = LWWRegister<String>(clock: clock);

      final ts = register.set('hello');

      expect(register.value, 'hello');
      expect(register.timestamp, ts);
      expect(register.hasValue, true);
    });

    test('set overwrites previous value', () {
      final register = LWWRegister<String>(clock: clock);

      register.set('first');
      register.set('second');

      expect(register.value, 'second');
    });

    test('merge takes value with higher timestamp', () {
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

      final reg1 = LWWRegister<String>(clock: clock1);
      final reg2 = LWWRegister<String>(clock: clock2);

      reg1.set('old');
      reg2.set('new');

      final changed = reg1.merge(reg2);

      expect(changed, true);
      expect(reg1.value, 'new');
    });

    test('merge keeps local value when timestamp higher', () {
      var time1 = 2000;
      var time2 = 1000;

      final clock1 = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time1++,
      );
      final clock2 = HybridLogicalClock(
        nodeId: 'node-2',
        physicalTimeFn: () => time2++,
      );

      final reg1 = LWWRegister<String>(clock: clock1);
      final reg2 = LWWRegister<String>(clock: clock2);

      reg1.set('newer');
      reg2.set('older');

      final changed = reg1.merge(reg2);

      expect(changed, false);
      expect(reg1.value, 'newer');
    });

    test('merge from empty register does nothing', () {
      final reg1 = LWWRegister<String>(clock: clock);
      final reg2 = LWWRegister<String>(clock: clock);

      reg1.set('value');
      final changed = reg1.merge(reg2);

      expect(changed, false);
      expect(reg1.value, 'value');
    });

    test('merge into empty register takes value', () {
      var time = 1000;
      final clock2 = HybridLogicalClock(
        nodeId: 'node-2',
        physicalTimeFn: () => time++,
      );

      final reg1 = LWWRegister<String>(clock: clock);
      final reg2 = LWWRegister<String>(clock: clock2);

      reg2.set('value');
      final changed = reg1.merge(reg2);

      expect(changed, true);
      expect(reg1.value, 'value');
    });

    test('mergeState works with raw values', () {
      final register = LWWRegister<int>(clock: clock);

      final remoteTs = HybridTimestamp(
        physicalTime: 5000,
        counter: 0,
        nodeId: 'node-2',
      );

      final changed = register.mergeState(value: 42, timestamp: remoteTs);

      expect(changed, true);
      expect(register.value, 42);
      expect(register.timestamp, remoteTs);
    });

    test('copy creates independent register', () {
      final reg1 = LWWRegister<String>(clock: clock);
      reg1.set('original');

      final reg2 = reg1.copy();
      reg1.set('modified');

      expect(reg2.value, 'original');
    });

    test('works with complex types', () {
      final register = LWWRegister<List<int>>(clock: clock);

      register.set([1, 2, 3]);

      expect(register.value, [1, 2, 3]);
    });
  });

  group('LWWMap', () {
    late HybridLogicalClock clock;

    setUp(() {
      var time = 1000;
      clock = HybridLogicalClock(
        nodeId: 'node-1',
        physicalTimeFn: () => time++,
      );
    });

    test('starts empty', () {
      final map = LWWMap<String, dynamic>(clock: clock);

      expect(map.get('key'), isNull);
      expect(map.containsKey('key'), false);
      expect(map.keys, isEmpty);
    });

    test('set and get work correctly', () {
      final map = LWWMap<String, dynamic>(clock: clock);

      map.set('name', 'Alice');
      map.set('age', 30);

      expect(map.get('name'), 'Alice');
      expect(map.get('age'), 30);
      expect(map.containsKey('name'), true);
      expect(map.keys.toSet(), {'name', 'age'});
    });

    test('set returns timestamp', () {
      final map = LWWMap<String, int>(clock: clock);

      final ts = map.set('count', 5);

      expect(ts, isNotNull);
      expect(map.getTimestamp('count'), ts);
    });

    test('mergeField updates field from remote', () {
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

      final map = LWWMap<String, String>(clock: clock1);
      map.set('field', 'old');

      final remoteTs = clock2.now();
      final changed = map.mergeField(
        'field',
        value: 'new',
        timestamp: remoteTs,
      );

      expect(changed, true);
      expect(map.get('field'), 'new');
    });

    test('merge combines two maps', () {
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

      final map1 = LWWMap<String, String>(clock: clock1);
      final map2 = LWWMap<String, String>(clock: clock2);

      map1.set('a', 'from-1');
      map1.set('b', 'from-1');
      map2.set('b', 'from-2'); // Will win due to higher time
      map2.set('c', 'from-2');

      final updated = map1.merge(map2);

      expect(map1.get('a'), 'from-1');
      expect(map1.get('b'), 'from-2');
      expect(map1.get('c'), 'from-2');
      expect(updated, contains('b'));
      expect(updated, contains('c'));
    });

    test('toState returns all field states', () {
      final map = LWWMap<String, int>(clock: clock);

      map.set('x', 1);
      map.set('y', 2);

      final state = map.toState();

      expect(state.length, 2);
      expect(state['x']?.value, 1);
      expect(state['y']?.value, 2);
    });

    test('independent fields do not conflict', () {
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

      final map1 = LWWMap<String, String>(clock: clock1);
      final map2 = LWWMap<String, String>(clock: clock2);

      // Concurrent edits to different fields
      map1.set('title', 'My Task');
      map2.set('done', 'true');

      map1.merge(map2);

      // Both updates preserved
      expect(map1.get('title'), 'My Task');
      expect(map1.get('done'), 'true');
    });
  });
}
