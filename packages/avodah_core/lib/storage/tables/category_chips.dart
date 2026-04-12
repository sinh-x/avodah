import 'package:drift/drift.dart';

/// Category chips table for storing user-defined category chips.
///
/// Chips are organized by category (e.g., "Working", "Learning") with
/// a display label and sort order. This table replaces the previous
/// config.json storage for bidirectional sync between desktop and phone.
class CategoryChips extends Table {
  /// Unique chip identifier (UUID).
  TextColumn get id => text()();

  /// Category grouping for this chip (e.g., "Working", "Learning").
  TextColumn get category => text()();

  /// Display label for this chip.
  TextColumn get label => text()();

  /// Sort order within the category.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// CRDT clock timestamp (packed HLC).
  TextColumn get crdtClock => text().withDefault(const Constant(''))();

  /// CRDT state JSON for all field timestamps and values.
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}