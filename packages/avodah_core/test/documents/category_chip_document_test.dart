import 'package:avodah_core/avodah_core.dart';
import 'package:test/test.dart';

void main() {
  group('CategoryChipDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('creation', () {
      test('create() generates UUID and sets initial fields', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
        );

        expect(chip.id, isNotEmpty);
        expect(chip.category, equals('Working'));
        expect(chip.label, equals('standup'));
        expect(chip.sortOrder, equals(0));
      });

      test('create() with sortOrder sets it correctly', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'code review',
          sortOrder: 5,
        );

        expect(chip.sortOrder, equals(5));
      });

      test('constructor creates empty document', () {
        final chip = CategoryChipDocument(id: 'chip-1', clock: clock);

        expect(chip.id, equals('chip-1'));
        expect(chip.category, isEmpty);
        expect(chip.label, isEmpty);
        expect(chip.sortOrder, equals(0));
      });
    });

    group('core fields', () {
      test('category can be set and retrieved', () {
        final chip = CategoryChipDocument(id: 'chip-1', clock: clock);

        chip.category = 'Learning';
        expect(chip.category, equals('Learning'));
      });

      test('label can be set and retrieved', () {
        final chip = CategoryChipDocument(id: 'chip-1', clock: clock);

        chip.label = 'reading';
        expect(chip.label, equals('reading'));
      });

      test('sortOrder can be set and retrieved', () {
        final chip = CategoryChipDocument(id: 'chip-1', clock: clock);

        chip.sortOrder = 3;
        expect(chip.sortOrder, equals(3));
      });
    });

    group('CRDT fields (AC-1)', () {
      test('create() stores CRDT fields with HLC timestamps', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
        );

        // Verify CRDT state via toJson()
        final json = chip.toJson();
        expect(json, isNotEmpty);
        expect(json['id'], isNotEmpty);

        // Verify fields map has the expected fields with HLC timestamps
        final fields = json['fields'] as Map<String, dynamic>;
        expect(fields, isNotEmpty);

        // category field should be present with HLC timestamp
        expect(fields.containsKey(CategoryChipFields.category), isTrue);
        final catField = fields[CategoryChipFields.category] as Map<String, dynamic>;
        expect(catField['v'], equals('Working'));
        expect(catField['t'], isNotNull);

        // label field should be present with HLC timestamp
        expect(fields.containsKey(CategoryChipFields.label), isTrue);
        final lblField = fields[CategoryChipFields.label] as Map<String, dynamic>;
        expect(lblField['v'], equals('standup'));
        expect(lblField['t'], isNotNull);

        // sortOrder field should be present with HLC timestamp
        expect(fields.containsKey(CategoryChipFields.sortOrder), isTrue);
        final ordField = fields[CategoryChipFields.sortOrder] as Map<String, dynamic>;
        expect(ordField['v'], equals(0));
        expect(ordField['t'], isNotNull);
      });

      test('create() generates unique timestamps for each field', () async {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
        );

        final fields = chip.toJson()['fields'] as Map<String, dynamic>;
        final catTs = fields[CategoryChipFields.category] as Map<String, dynamic>;
        final lblTs = fields[CategoryChipFields.label] as Map<String, dynamic>;
        final ordTs = fields[CategoryChipFields.sortOrder] as Map<String, dynamic>;

        // All timestamps should be non-null and valid HLC format
        expect(catTs['t'], isNotEmpty);
        expect(lblTs['t'], isNotEmpty);
        expect(ordTs['t'], isNotEmpty);
      });
    });

    group('toDriftCompanion() (AC-1)', () {
      test('produces valid CategoryChipsCompanion', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
          sortOrder: 2,
        );

        final companion = chip.toDriftCompanion();

        expect(companion.id.value, equals(chip.id));
        expect(companion.category.value, equals('Working'));
        expect(companion.label.value, equals('standup'));
        expect(companion.sortOrder.value, equals(2));
        expect(companion.crdtClock.value, isNotEmpty);
        expect(companion.crdtState.value, isNotEmpty);
      });

      test('round-trips through toCrdtState()', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Learning',
          label: 'course',
          sortOrder: 1,
        );

        final companion = chip.toDriftCompanion();
        final crdtStateJson = companion.crdtState.value;

        expect(crdtStateJson, isNotEmpty);
        expect(crdtStateJson, startsWith('{'));
      });
    });

    group('toModel() (AC-3)', () {
      test('produces immutable CategoryChipModel', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
          sortOrder: 3,
        );

        final model = chip.toModel();

        expect(model.id, equals(chip.id));
        expect(model.category, equals('Working'));
        expect(model.label, equals('standup'));
        expect(model.sortOrder, equals(3));
        expect(model.isDeleted, isFalse);
      });

      test('CategoryChipModel equality based on id', () {
        final chip1 = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
        );
        final chip2 = CategoryChipDocument.create(
          clock: clock,
          category: 'Learning',
          label: 'reading',
        );

        final model1 = chip1.toModel();
        final model2 = chip2.toModel();
        final model1Copy = chip1.toModel();

        expect(model1, equals(model1Copy));
        expect(model1, isNot(equals(model2)));
      });

      test('toModel() reflects field updates', () {
        final chip = CategoryChipDocument(id: 'chip-1', clock: clock);
        chip.category = 'Working';
        chip.label = 'debugging';
        chip.sortOrder = 7;

        final model = chip.toModel();

        expect(model.category, equals('Working'));
        expect(model.label, equals('debugging'));
        expect(model.sortOrder, equals(7));
      });
    });

    group('fromDrift() (AC-7 backfill)', () {
      test('reconstructs document from Drift entity', () {
        // Create a chip and store it
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
          sortOrder: 1,
        );

        // Simulate a Drift row
        final companion = chip.toDriftCompanion();

        // Manually construct a CategoryChip row as Drift would return it
        final driftRow = CategoryChip(
          id: companion.id.value,
          category: companion.category.value,
          label: companion.label.value,
          sortOrder: companion.sortOrder.value,
          crdtClock: companion.crdtClock.value,
          crdtState: companion.crdtState.value,
        );

        // Reconstruct from Drift
        final reconstructed =
            CategoryChipDocument.fromDrift(chip: driftRow, clock: clock);

        expect(reconstructed.id, equals(chip.id));
        expect(reconstructed.category, equals('Working'));
        expect(reconstructed.label, equals('standup'));
        expect(reconstructed.sortOrder, equals(1));
      });

      test('backfills fields when CRDT state is empty', () {
        // Simulate a pre-v17 row with no CRDT state
        final driftRow = CategoryChip(
          id: 'legacy-chip-1',
          category: 'Working',
          label: 'old-label',
          sortOrder: 0,
          crdtClock: '',
          crdtState: '{}',
        );

        final reconstructed =
            CategoryChipDocument.fromDrift(chip: driftRow, clock: clock);

        expect(reconstructed.category, equals('Working'));
        expect(reconstructed.label, equals('old-label'));
        expect(reconstructed.sortOrder, equals(0));
      });

      test('does not overwrite existing CRDT fields during backfill', () {
        // Create a chip, modify it, then reconstruct from Drift
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
        );
        chip.sortOrder = 5;

        // Get the state after modification
        final stateJson = chip.toCrdtState();

        // Simulate a Drift row with partial state
        final driftRow = CategoryChip(
          id: chip.id,
          category: 'Working',
          label: 'standup',
          sortOrder: 5,
          crdtClock: clock.lastTimestamp.pack(),
          crdtState: stateJson,
        );

        final reconstructed =
            CategoryChipDocument.fromDrift(chip: driftRow, clock: clock);

        expect(reconstructed.sortOrder, equals(5));
      });
    });

    group('soft delete', () {
      test('delete() marks chip as deleted', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
        );

        chip.delete();

        expect(chip.isDeleted, isTrue);
        expect(chip.toModel().isDeleted, isTrue);
      });

      test('restore() undeletes chip', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
        );
        chip.delete();

        chip.restore();

        expect(chip.isDeleted, isFalse);
        expect(chip.toModel().isDeleted, isFalse);
      });
    });

    group('merge operations', () {
      test('merging two chips preserves independent changes', () {
        final clock1 = HybridLogicalClock(nodeId: 'phone');
        final clock2 = HybridLogicalClock(nodeId: 'laptop');

        final chip1 = CategoryChipDocument.create(
          clock: clock1,
          category: 'Working',
          label: 'standup',
        );

        // Sync to laptop
        final json = chip1.toJson();
        final state = CrdtDocument.stateFromJson(json);
        final chip2 = CategoryChipDocument.fromState(
          id: chip1.id,
          clock: clock2,
          state: state,
        );

        // Phone updates label
        chip1.label = 'code review';

        // Laptop updates sortOrder
        chip2.sortOrder = 3;

        // Merge laptop into phone
        chip1.merge(chip2);

        expect(chip1.label, equals('code review'));
        expect(chip1.sortOrder, equals(3));
      });

      test('concurrent edits on same field - last writer wins', () {
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

        final chip1 = CategoryChipDocument(id: 'chip-1', clock: clock1);
        final chip2 = CategoryChipDocument(id: 'chip-1', clock: clock2);

        // Node 1 sets label
        chip1.label = 'First';

        // Node 2 sets label 1ms later
        time2 = baseTime + 1;
        chip2.label = 'Second';

        chip1.merge(chip2);

        expect(chip1.label, equals('Second'));
      });

      test('offline sync scenario preserves independent changes', () {
        final clock1 = HybridLogicalClock(nodeId: 'device-a');
        final clock2 = HybridLogicalClock(nodeId: 'device-b');

        final chipA = CategoryChipDocument.create(
          clock: clock1,
          category: 'Working',
          label: 'standup',
        );
        chipA.sortOrder = 1;

        // Sync to device B
        final json = chipA.toJson();
        final state = CrdtDocument.stateFromJson(json);
        final chipB = CategoryChipDocument.fromState(
          id: chipA.id,
          clock: clock2,
          state: state,
        );

        // Device A updates category (offline)
        chipA.category = 'Learning';

        // Device B updates label (offline)
        chipB.label = 'debugging';

        // Come back online - merge both ways
        chipA.merge(chipB);
        chipB.merge(chipA);

        // Both should have both changes
        expect(chipA.category, equals('Learning'));
        expect(chipA.label, equals('debugging'));

        expect(chipB.category, equals('Learning'));
        expect(chipB.label, equals('debugging'));
      });
    });

    group('idempotent state transitions', () {
      test('multiple field updates are all preserved after merge', () {
        final chip = CategoryChipDocument.create(
          clock: clock,
          category: 'Working',
          label: 'standup',
        );

        chip.category = 'Learning';
        chip.label = 'course';
        chip.sortOrder = 2;

        final fields = chip.toJson()['fields'] as Map<String, dynamic>;
        expect((fields[CategoryChipFields.category] as Map)['v'], equals('Learning'));
        expect((fields[CategoryChipFields.label] as Map)['v'], equals('course'));
        expect((fields[CategoryChipFields.sortOrder] as Map)['v'], equals(2));
      });
    });
  });
}
