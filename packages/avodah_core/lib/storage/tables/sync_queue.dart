import 'package:drift/drift.dart';

/// Sync queue table — persists unsent CRDT deltas for retry.
///
/// Stores deltas that failed to push to the desktop and need to be
/// retried on the next sync cycle. Entries are processed in FIFO order
/// (oldest first) with exponential backoff on repeated failures.
///
/// Used by [CrdtSyncService] to:
/// - Enqueue deltas when push fails or server is offline
/// - Process pending deltas before each pull cycle
/// - Auto-purge entries older than 7 days with status=failed
class SyncQueue extends Table {
  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// JSON-encoded CRDT delta to push.
  /// Structure: `{"type":"<docType>","id":"<docId>","fields":{...}}`
  TextColumn get deltaJson => text()();

  /// Unix timestamp (ms) when this entry was created.
  IntColumn get createdAt => integer()();

  /// Number of push attempts made (0 = first attempt not yet made).
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Current status: `pending` or `failed`.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
}