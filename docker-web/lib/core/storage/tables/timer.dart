import 'package:drift/drift.dart';

/// Timer entries table - tracks active timer state.
///
/// Only one row should exist (id = 'active-timer').
/// Used for crash recovery and cross-device sync.
class TimerEntries extends Table {
  /// Well-known ID: 'active-timer'
  TextColumn get id => text()();

  /// Task ID being timed (null for ad-hoc).
  TextColumn get taskId => text().nullable()();

  /// Task title (denormalized for display).
  TextColumn get taskTitle => text().withDefault(const Constant(''))();

  /// Project ID (null if no project).
  TextColumn get projectId => text().nullable()();

  /// Project title (denormalized for display).
  TextColumn get projectTitle => text().nullable()();

  /// When timer was started (Unix ms).
  IntColumn get startedAt => integer().withDefault(const Constant(0))();

  /// Whether timer is currently running.
  BoolColumn get isRunning => boolean().withDefault(const Constant(false))();

  /// When timer was paused (Unix ms, null if not paused).
  IntColumn get pausedAt => integer().nullable()();

  /// Time accumulated before pause (ms).
  IntColumn get accumulatedMs => integer().withDefault(const Constant(0))();

  /// Optional note about current work.
  TextColumn get note => text().nullable()();

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
