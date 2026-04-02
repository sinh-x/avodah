import 'package:drift/drift.dart';

/// Sync watermark table — tracks per-node HLC watermarks for delta sync.
///
/// Each row records the last HLC watermark seen from (or sent to) a remote
/// node, so repeated syncs only exchange new deltas.
///
/// Used by [SyncApiService] to:
/// - Record the last HLC received FROM a remote node after a push
/// - Record the last HLC sent TO a remote node after a pull
class SyncWatermarks extends Table {
  /// Remote node ID (e.g. "phone-1", "desktop-1").
  TextColumn get nodeId => text()();

  /// Packed HLC watermark string (e.g. "1741234567890-0-phone-1").
  /// Represents the last HLC timestamp exchanged with this node.
  TextColumn get lastHlc => text().withDefault(const Constant(''))();

  /// Whether this watermark is for data received FROM the node ("received")
  /// or data sent TO the node ("sent").
  TextColumn get direction =>
      text().withDefault(const Constant('received'))();

  /// When this watermark was last updated (Unix ms).
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {nodeId, direction};
}
