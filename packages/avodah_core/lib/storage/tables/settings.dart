import 'package:drift/drift.dart';

/// Key-value settings table for server-side configuration storage.
///
/// Used to store settings that were previously in config.json but should
/// now be managed by the server to prevent config overwrites (e.g., category
/// chips). The server NEVER writes to config.json.
///
/// Key format: "categoryChips.<category>" (e.g., "categoryChips.Working")
/// Value format: JSON-encoded list of chip strings.
class Settings extends Table {
  /// Setting key (e.g., "categoryChips.Working").
  TextColumn get key => text()();

  /// JSON-encoded setting value.
  TextColumn get value => text()();

  /// Last update timestamp (Unix ms).
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}