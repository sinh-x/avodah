import 'package:drift/drift.dart';

import 'pending_captures.dart';
import 'pending_sync_deltas.dart';

part 'phone_database.g.dart';

/// Phone-local database for tables not synced via CRDT.
///
/// These tables are specific to the Flutter viewer app and are not
/// part of the shared avodah_core schema.
@DriftDatabase(tables: [PendingCaptures, PendingSyncDeltas])
class PhoneDatabase extends _$PhoneDatabase {
  PhoneDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          try {
            await m.addColumn(pendingCaptures, pendingCaptures.project);
          } on Exception catch (_) {}
        }
        if (from < 3) {
          try {
            await m.createTable(pendingSyncDeltas);
          } on Exception catch (_) {}
        }
      },
    );
  }
}