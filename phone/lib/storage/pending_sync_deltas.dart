import 'package:drift/drift.dart';

class PendingSyncDeltas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deltaJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
