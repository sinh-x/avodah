import 'dart:convert';

import 'package:avodah_core/crdt/crdt.dart';
import 'package:test/test.dart';

/// Test implementation of CrdtDocument.
class TestDocument extends CrdtDocument<TestDocument> {
  TestDocument({required super.id, required super.clock});

  TestDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  // Typed field accessors
  String? get title => getString('title');
  set title(String? value) => setString('title', value);

  String? get description => getString('description');
  set description(String? value) => setString('description', value);

  int? get priority => getInt('priority');
  set priority(int? value) => setInt('priority', value);

  bool? get isDone => getBool('isDone');
  set isDone(bool? value) => setBool('isDone', value);

  double? get progress => getDouble('progress');
  set progress(double? value) => setDouble('progress', value);

  DateTime? get dueDate => getDateTime('dueDate');
  set dueDate(DateTime? value) => setDateTime('dueDate', value);

  List<String>? get tags => getList<String>('tags');
  set tags(List<String>? value) => setList('tags', value);

  Map<String, int>? get timeSpent => getMap<int>('timeSpent');
  set timeSpent(Map<String, int>? value) => setMap('timeSpent', value);

  @override
  TestDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return TestDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

void main() {
  group('CrdtDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('basic operations', () {
      test('creates document with ID', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        expect(doc.id, equals('doc-1'));
        expect(doc.isDeleted, isFalse);
      });

      test('sets and gets string field', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.title = 'My Task';
        expect(doc.title, equals('My Task'));
      });

      test('sets and gets int field', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.priority = 5;
        expect(doc.priority, equals(5));
      });

      test('sets and gets bool field', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.isDone = true;
        expect(doc.isDone, isTrue);
      });

      test('sets and gets double field', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.progress = 0.75;
        expect(doc.progress, equals(0.75));
      });

      test('sets and gets DateTime field', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);
        final due = DateTime(2026, 3, 15, 10, 30);

        doc.dueDate = due;
        expect(doc.dueDate, equals(due));
      });

      test('sets and gets list field', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.tags = ['urgent', 'work', 'flutter'];
        expect(doc.tags, equals(['urgent', 'work', 'flutter']));
      });

      test('sets and gets map field', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.timeSpent = {'2026-02-08': 3600, '2026-02-09': 1800};
        expect(doc.timeSpent, equals({'2026-02-08': 3600, '2026-02-09': 1800}));
      });

      test('returns null for unset fields', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        expect(doc.title, isNull);
        expect(doc.priority, isNull);
        expect(doc.isDone, isNull);
        expect(doc.progress, isNull);
        expect(doc.dueDate, isNull);
        expect(doc.tags, isNull);
        expect(doc.timeSpent, isNull);
      });

      test('tracks field keys', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.title = 'Task';
        doc.priority = 3;

        expect(doc.fieldKeys, containsAll(['title', 'priority']));
      });
    });

    group('soft delete', () {
      test('delete marks document as deleted', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        expect(doc.isDeleted, isFalse);
        doc.delete();
        expect(doc.isDeleted, isTrue);
      });

      test('restore undeletes document', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.delete();
        expect(doc.isDeleted, isTrue);

        doc.restore();
        expect(doc.isDeleted, isFalse);
      });
    });

    group('timestamps', () {
      test('tracks field timestamps', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        final ts = doc.setString('title', 'Task');

        expect(doc.getFieldTimestamp('title'), equals(ts));
      });

      test('updates modifiedAt on field change', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        doc.title = 'Task';
        final modified1 = doc.modifiedAt;

        doc.priority = 5;
        final modified2 = doc.modifiedAt;

        expect(modified2, isNotNull);
        expect(modified2! > modified1!, isTrue);
      });
    });

    group('merge operations', () {
      test('merge updates field with higher timestamp', () {
        final clock1 = HybridLogicalClock(nodeId: 'node-1');
        final clock2 = HybridLogicalClock(nodeId: 'node-2');

        final doc1 = TestDocument(id: 'doc-1', clock: clock1);
        final doc2 = TestDocument(id: 'doc-1', clock: clock2);

        // doc1 sets title first
        doc1.title = 'First Title';

        // doc2 sets title later (higher timestamp)
        doc2.title = 'Second Title';

        // Merge doc2 into doc1
        final updated = doc1.merge(doc2);

        expect(updated, contains('title'));
        expect(doc1.title, equals('Second Title'));
      });

      test('merge preserves field with higher local timestamp', () {
        // Use controlled time to ensure deterministic ordering
        var time1 = 1000000;
        var time2 = 1000000;
        final clock1 = HybridLogicalClock(
          nodeId: 'node-1',
          physicalTimeFn: () => time1,
        );
        final clock2 = HybridLogicalClock(
          nodeId: 'node-2',
          physicalTimeFn: () => time2,
        );

        final doc1 = TestDocument(id: 'doc-1', clock: clock1);
        final doc2 = TestDocument(id: 'doc-1', clock: clock2);

        // doc2 sets title at time 1000000
        doc2.title = 'Earlier Title';

        // doc1 sets title at time 2000000 (later)
        time1 = 2000000;
        doc1.title = 'Later Title';

        // Merge doc2 into doc1 - should keep doc1's value
        final updated = doc1.merge(doc2);

        // Title should not be updated (doc1 has higher timestamp)
        // But _modifiedAt might be different, so we just check title
        expect(updated.contains('title'), isFalse);
        expect(doc1.title, equals('Later Title'));
      });

      test('merge handles independent fields', () {
        final clock1 = HybridLogicalClock(nodeId: 'node-1');
        final clock2 = HybridLogicalClock(nodeId: 'node-2');

        final doc1 = TestDocument(id: 'doc-1', clock: clock1);
        final doc2 = TestDocument(id: 'doc-1', clock: clock2);

        doc1.title = 'Task';
        doc2.priority = 5;

        doc1.merge(doc2);

        expect(doc1.title, equals('Task'));
        expect(doc1.priority, equals(5));
      });

      test('merge throws for different IDs', () {
        final doc1 = TestDocument(id: 'doc-1', clock: clock);
        final doc2 = TestDocument(id: 'doc-2', clock: clock);

        expect(() => doc1.merge(doc2), throwsArgumentError);
      });

      test('mergeField updates single field', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);
        doc.title = 'Original';

        final remoteTs = HybridTimestamp(
          physicalTime: DateTime.now().millisecondsSinceEpoch + 10000,
          counter: 0,
          nodeId: 'remote',
        );

        final updated = doc.mergeField('title', value: 'Remote', timestamp: remoteTs);

        expect(updated, isTrue);
        expect(doc.title, equals('Remote'));
      });
    });

    group('serialization', () {
      test('toJson serializes document', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);
        doc.title = 'My Task';
        doc.priority = 3;

        final json = doc.toJson();

        expect(json['id'], equals('doc-1'));
        expect(json['fields'], isA<Map>());
        expect(json['fields']['title']['v'], equals('My Task'));
        expect(json['fields']['title']['t'], isA<String>());
        expect(json['fields']['priority']['v'], equals(3));
      });

      test('stateFromJson parses document state', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);
        doc.title = 'Task';
        doc.priority = 5;

        final json = doc.toJson();
        final state = CrdtDocument.stateFromJson(json);

        expect(state['title']?.value, equals('Task'));
        expect(state['title']?.timestamp, isNotNull);
        expect(state['priority']?.value, equals(5));
      });

      test('fromState creates document from state', () {
        final clock1 = HybridLogicalClock(nodeId: 'node-1');
        final clock2 = HybridLogicalClock(nodeId: 'node-2');

        final doc1 = TestDocument(id: 'doc-1', clock: clock1);
        doc1.title = 'Task';
        doc1.priority = 3;

        final json = doc1.toJson();
        final state = CrdtDocument.stateFromJson(json);

        final doc2 = TestDocument.fromState(
          id: json['id'] as String,
          clock: clock2,
          state: state,
        );

        expect(doc2.id, equals('doc-1'));
        expect(doc2.title, equals('Task'));
        expect(doc2.priority, equals(3));
      });

      test('toCrdtState returns compact JSON', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);
        doc.title = 'Task';

        final crdtState = doc.toCrdtState();
        final decoded = jsonDecode(crdtState) as Map<String, dynamic>;

        expect(decoded['title'], isA<Map>());
        expect(decoded['title']['v'], equals('Task'));
      });

      test('stateFromCrdtState parses compact JSON', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);
        doc.title = 'Task';
        doc.priority = 5;

        final crdtState = doc.toCrdtState();
        final state = CrdtDocument.stateFromCrdtState(crdtState);

        expect(state['title']?.value, equals('Task'));
        expect(state['priority']?.value, equals(5));
      });

      test('stateFromCrdtState handles empty state', () {
        final state = CrdtDocument.stateFromCrdtState('');
        expect(state, isEmpty);

        final state2 = CrdtDocument.stateFromCrdtState('{}');
        expect(state2, isEmpty);
      });
    });

    group('copyWith', () {
      test('creates copy with same ID', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);
        doc.title = 'Task';

        final copy = doc.copyWith();

        expect(copy.id, equals('doc-1'));
        expect(copy.title, isNull); // Copy starts fresh
      });

      test('creates copy with new ID', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);

        final copy = doc.copyWith(id: 'doc-2');

        expect(copy.id, equals('doc-2'));
      });

      test('mergeFrom copies all fields', () {
        final doc1 = TestDocument(id: 'doc-1', clock: clock);
        doc1.title = 'Task';
        doc1.priority = 3;

        final doc2 = doc1.copyWith();
        doc2.mergeFrom(doc1);

        expect(doc2.title, equals('Task'));
        expect(doc2.priority, equals(3));
      });
    });

    group('duplicate extension', () {
      test('creates duplicate with new ID', () {
        final doc = TestDocument(id: 'doc-1', clock: clock);
        doc.title = 'Original Task';
        doc.priority = 3;

        final dup = doc.duplicate('doc-2');

        expect(dup.id, equals('doc-2'));
        expect(dup.title, equals('Original Task'));
        expect(dup.priority, equals(3));
      });
    });

    group('equality', () {
      test('documents with same ID are equal', () {
        final doc1 = TestDocument(id: 'doc-1', clock: clock);
        final doc2 = TestDocument(id: 'doc-1', clock: clock);

        expect(doc1, equals(doc2));
        expect(doc1.hashCode, equals(doc2.hashCode));
      });

      test('documents with different IDs are not equal', () {
        final doc1 = TestDocument(id: 'doc-1', clock: clock);
        final doc2 = TestDocument(id: 'doc-2', clock: clock);

        expect(doc1, isNot(equals(doc2)));
      });
    });

    group('concurrent edits simulation', () {
      test('concurrent edits on different fields merge cleanly', () {
        // Simulate two devices editing the same document concurrently
        final clockA = HybridLogicalClock(nodeId: 'device-A');
        final clockB = HybridLogicalClock(nodeId: 'device-B');

        // Both start with same document
        final docA = TestDocument(id: 'shared-doc', clock: clockA);
        final docB = TestDocument(id: 'shared-doc', clock: clockB);

        // Device A edits title
        docA.title = 'Title from A';

        // Device B edits priority (different field)
        docB.priority = 10;

        // Sync: merge B into A
        docA.merge(docB);

        // Both changes should be present
        expect(docA.title, equals('Title from A'));
        expect(docA.priority, equals(10));

        // Sync: merge A into B
        docB.merge(docA);

        // B should have both too
        expect(docB.title, equals('Title from A'));
        expect(docB.priority, equals(10));
      });

      test('concurrent edits on same field - last writer wins', () {
        final clockA = HybridLogicalClock(nodeId: 'device-A');
        final clockB = HybridLogicalClock(nodeId: 'device-B');

        final docA = TestDocument(id: 'shared-doc', clock: clockA);
        final docB = TestDocument(id: 'shared-doc', clock: clockB);

        // Device A edits first
        docA.title = 'Title A';

        // Device B edits later (higher timestamp)
        docB.title = 'Title B';

        // Merge B into A
        docA.merge(docB);
        expect(docA.title, equals('Title B'));

        // Merge A into B (should be no-op, B already has latest)
        docB.merge(docA);
        expect(docB.title, equals('Title B'));
      });

      test('offline sync scenario - multiple fields', () {
        final clockA = HybridLogicalClock(nodeId: 'phone');
        final clockB = HybridLogicalClock(nodeId: 'laptop');

        // Start online - both have same state
        final docA = TestDocument(id: 'task-1', clock: clockA);
        docA.title = 'Buy groceries';
        docA.isDone = false;
        docA.tags = ['shopping'];

        // Serialize and "send" to laptop
        final jsonA = docA.toJson();
        final stateA = CrdtDocument.stateFromJson(jsonA);
        final docB = TestDocument.fromState(
          id: jsonA['id'] as String,
          clock: clockB,
          state: stateA,
        );

        // Go offline - phone marks done
        docA.isDone = true;

        // Laptop adds tag (offline)
        docB.tags = ['shopping', 'urgent'];

        // Come back online - sync both ways
        docA.merge(docB);
        docB.merge(docA);

        // Both should have: isDone=true, tags=['shopping', 'urgent']
        expect(docA.isDone, isTrue);
        expect(docA.tags, equals(['shopping', 'urgent']));
        expect(docB.isDone, isTrue);
        expect(docB.tags, equals(['shopping', 'urgent']));
      });
    });
  });
}
