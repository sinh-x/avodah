import 'package:drift/drift.dart';

/// Pending captures table — stores shared content from Android share intents.
///
/// Phone-local only (not synced via CRDT). Used by the quick capture flow
/// to hold captures until they can be synced to the PA system (P2 sync service).
class PendingCaptures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get url => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get category =>
      text().withDefault(const Constant('learning'))();
  TextColumn get sharedText => text().nullable()();
  IntColumn get createdAt => integer()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}