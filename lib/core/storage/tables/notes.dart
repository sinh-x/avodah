import 'package:drift/drift.dart';

/// Notes table - aligned with Super Productivity Note model
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()();

  // Content
  TextColumn get content => text()();
  TextColumn get imgUrl => text().nullable()();
  TextColumn get backgroundColor => text().nullable()();

  // Flags
  BoolColumn get isPinnedToToday => boolean().withDefault(const Constant(false))();
  BoolColumn get isLock => boolean().withDefault(const Constant(false))();

  // Timestamps
  IntColumn get created => integer()(); // Unix ms
  IntColumn get modified => integer()(); // Unix ms

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
