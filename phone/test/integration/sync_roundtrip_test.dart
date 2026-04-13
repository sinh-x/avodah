/// Phase 4: Server-to-phone timer sync integration test.
///
/// Simulates the full flow from server timer start to phone Dashboard display:
///
///   1. Server starts a timer (TimerDocument.start)
///   2. Phone pulls deltas from server via extractDeltas()
///   3. Phone merges timer delta into local DB via _mergeTimer()
///   4. Phone queries local DB via _queryActiveTimer()
///   5. Assert: active timer is found, isRunning=true, taskTitle matches
///
/// This verifies AC1: Start timer on server → phone Dashboard shows running timer.
///
/// The test uses drift NativeDatabase.memory() directly since the phone app
/// does not have access to avodah_mcp (only avodah_core). Server-side services
/// (SyncApiService, TimerService) are inlined here with identical logic.
library;

import 'package:avodah_core/avodah_core.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Document type string for timer — mirrors SyncDocType.timer from mcp.
const _timerDocType = 'timer';

/// Opens an in-memory database for testing — mirrors database_opener.dart.
AppDatabase _openMemoryDatabase() {
  final database = NativeDatabase.memory();
  return AppDatabase(database);
}

void main() {
  // Suppress drift's multi-database warning since we intentionally create
  // separate in-memory databases per test for isolation.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('server-to-phone timer sync', () {
    test(
        'server timer start syncs to phone — phone queries local DB after merge',
        () async {
      // ─── Server (desktop) setup ─────────────────────────────────────────
      final serverDb = _openMemoryDatabase();
      final serverClock = HybridLogicalClock(nodeId: 'desktop-server');
      final serverTimer = _ServerTimerService(db: serverDb, clock: serverClock);

      // ─── Phone setup ────────────────────────────────────────────────────
      final phoneDb = _openMemoryDatabase();
      final phoneClock = HybridLogicalClock(nodeId: 'phone-1');

      // ─── Step 1: Server starts a timer ──────────────────────────────────
      await serverTimer.start(taskTitle: 'Server-side sync test');

      // Verify timer is running on server
      final serverTimers = await serverDb.select(serverDb.timerEntries).get();
      expect(serverTimers, hasLength(1));
      expect(serverTimers[0].isRunning, isTrue);
      expect(serverTimers[0].taskTitle, equals('Server-side sync test'));

      // The clock was already advanced during start() when timer fields were set.

      // ─── Step 2: Phone pulls deltas from server ─────────────────────────
      // In real flow, phone calls GET /api/sync/deltas?since=0
      // Here we inline extractDeltas: query all timer entries with CRDT state
      final deltas = await _extractDeltas(serverDb, serverClock);

      expect(deltas, isNotEmpty);
      final timerDeltas =
          deltas.where((d) => d['type'] == _timerDocType).toList();
      expect(timerDeltas, hasLength(1),
          reason: 'Server timer delta must be in deltas response');

      // Verify the timer delta has correct field values
      final isRunningField = timerDeltas[0]['fields'] as Map<String, dynamic>;
      expect(isRunningField['isRunning']['v'], isTrue,
          reason: 'Timer delta must indicate isRunning=true');

      // ─── Step 3: Phone merges timer delta into local DB ─────────────────
      // This mirrors what CrdtSyncService._mergeTimer() does in the phone app
      for (final delta in deltas) {
        await _mergeDelta(phoneDb, phoneClock, delta);
      }

      // ─── Step 4: Phone queries local DB for active timer ────────────────
      // This mirrors what LocalDashboardProvider._queryActiveTimer() does
      final phoneTimers = await (phoneDb.select(phoneDb.timerEntries)
            ..where((t) => t.id.equals(activeTimerId)))
          .get();

      // ─── Step 5: Assert timer is found and correct ───────────────────────
      expect(phoneTimers, hasLength(1),
          reason:
              'Phone DB must have exactly one timer entry (active-timer singleton)');

      final phoneTimer = phoneTimers[0];
      expect(phoneTimer.isRunning, isTrue,
          reason: 'Active timer on phone must be running');
      expect(phoneTimer.taskTitle, equals('Server-side sync test'),
          reason: 'Timer taskTitle must match what server set');
      expect(phoneTimer.startedAt, greaterThan(0),
          reason: 'Timer must have a startedAt timestamp');

      // Cleanup
      await serverDb.close();
      await phoneDb.close();
    });

    test('server timer stop syncs to phone — timer becomes idle', () async {
      // ─── Server (desktop) setup ─────────────────────────────────────────
      final serverDb = _openMemoryDatabase();
      final serverClock = HybridLogicalClock(nodeId: 'desktop-server');
      final serverTimer = _ServerTimerService(db: serverDb, clock: serverClock);

      // ─── Phone setup ────────────────────────────────────────────────────
      final phoneDb = _openMemoryDatabase();
      final phoneClock = HybridLogicalClock(nodeId: 'phone-1');

      // Server starts timer
      await serverTimer.start(taskTitle: 'Timer stop test');

      // Phone pulls and merges
      var deltas = await _extractDeltas(serverDb, serverClock);
      for (final delta in deltas) {
        await _mergeDelta(phoneDb, phoneClock, delta);
      }

      // Verify phone has running timer
      var phoneTimers = await (phoneDb.select(phoneDb.timerEntries)
            ..where((t) => t.id.equals(activeTimerId)))
          .get();
      expect(phoneTimers[0].isRunning, isTrue);

      // Server stops the timer
      await serverTimer.stop();

      // Phone pulls updated deltas
      deltas = await _extractDeltas(serverDb, serverClock);
      for (final delta in deltas) {
        await _mergeDelta(phoneDb, phoneClock, delta);
      }

      // Phone queries — timer should no longer be running
      phoneTimers = await (phoneDb.select(phoneDb.timerEntries)
            ..where((t) => t.id.equals(activeTimerId)))
          .get();
      expect(phoneTimers[0].isRunning, isFalse,
          reason: 'Timer must be stopped after server stop delta');

      await serverDb.close();
      await phoneDb.close();
    });

    test('local dashboard provider query finds merged timer', () async {
      // Simulates the full LocalDashboardProvider flow end-to-end:
      // 1. Server creates timer
      // 2. Phone merges via _mergeDelta
      // 3. Phone calls _queryActiveTimer() (mirrors LocalDashboardProvider)
      // 4. Document converted to TimerDocument and checked with isIdle

      final serverDb = _openMemoryDatabase();
      final serverClock = HybridLogicalClock(nodeId: 'desktop-server');
      final serverTimer = _ServerTimerService(db: serverDb, clock: serverClock);

      final phoneDb = _openMemoryDatabase();
      final phoneClock = HybridLogicalClock(nodeId: 'phone-1');

      // Server starts timer
      await serverTimer.start(taskTitle: 'Dashboard display test');

      // Phone syncs
      final deltas = await _extractDeltas(serverDb, serverClock);
      for (final delta in deltas) {
        await _mergeDelta(phoneDb, phoneClock, delta);
      }

      // Phone queries active timer (mirrors _queryActiveTimer)
      final rows = await (phoneDb.select(phoneDb.timerEntries)
            ..where((t) => t.id.equals(activeTimerId)))
          .get();

      expect(rows, hasLength(1));

      // Convert to TimerDocument and check isIdle (mirrors _buildSnapshot)
      final doc = TimerDocument.fromDrift(timer: rows.first, clock: phoneClock);
      expect(doc.isIdle, isFalse,
          reason: 'Timer must NOT be idle after server sync');
      expect(doc.isRunning, isTrue);
      expect(doc.taskTitle, equals('Dashboard display test'));

      await serverDb.close();
      await phoneDb.close();
    });
  });
}

// ============================================================
// Server-side inlined services (mirrors mcp/services/)
// ============================================================

/// Inlined TimerService for testing — mirrors mcp/services/timer_service.dart.
/// Uses drift NativeDatabase.memory() directly.
class _ServerTimerService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  _ServerTimerService({required this.db, required this.clock});

  /// Starts a new timer — mirrors TimerService.start().
  Future<void> start({
    required String taskTitle,
    String? taskId,
    String? projectId,
    String? projectTitle,
    String? note,
    String? category,
  }) async {
    final doc = TimerDocument(
      id: activeTimerId,
      clock: clock,
    );
    doc.taskId = taskId;
    doc.taskTitle = taskTitle;
    doc.projectId = projectId;
    doc.projectTitle = projectTitle;
    doc.note = note;
    doc.category = category;
    doc.startedAtMs = DateTime.now().millisecondsSinceEpoch;
    doc.isRunning = true;
    doc.pausedAtMs = null;
    doc.accumulatedMs = 0;

    await db.into(db.timerEntries).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  /// Stops the active timer — mirrors TimerService.stop().
  Future<int> stop() async {
    final rows = await (db.select(db.timerEntries)
          ..where((t) => t.id.equals(activeTimerId)))
        .get();
    if (rows.isEmpty) return 0;

    final doc = TimerDocument.fromDrift(timer: rows.first, clock: clock);
    final totalMs = doc.elapsed.inMilliseconds;
    doc.stop();

    await db.into(db.timerEntries).insertOnConflictUpdate(doc.toDriftCompanion());
    return totalMs;
  }
}

// ============================================================
// Delta extraction (mirrors SyncApiService.extractDeltas)
// ============================================================

/// Extracts all CRDT deltas since the given watermark.
/// Mirrors SyncApiService.extractDeltas() in mcp.
Future<List<Map<String, dynamic>>> _extractDeltas(
  AppDatabase db,
  HybridLogicalClock clock,
) async {
  final since = HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
  final deltas = <Map<String, dynamic>>[];

  // Extract timer deltas — mirrors SyncApiService._extractDocDeltas
  final timerRows = await db.select(db.timerEntries).get();
  for (final row in timerRows) {
    final doc = TimerDocument.fromDrift(timer: row, clock: clock);
    // Skip idle timers (stopped — isRunning=false and startedAtMs=null)
    // But do include them if they've been modified since the watermark,
    // because the phone needs to know about the stop event.
    if (doc.isIdle) {
      // Still include if doc has meaningful CRDT state (non-empty field keys)
      // because the stop event needs to propagate
      if (doc.fieldKeys.isEmpty) continue;
    }

    // Check if doc has been updated since watermark
    final lastModified = doc.modifiedAt;
    if (lastModified != null && lastModified < since) continue;

    final json = doc.toJson();
    json['type'] = _timerDocType;
    deltas.add(json);
  }

  return deltas;
}

// ============================================================
// Delta merge (mirrors CrdtSyncService._mergeDelta / _mergeTimer)
// ============================================================

/// Merges a CRDT delta into the local phone database.
/// Mirrors CrdtSyncService._mergeDelta() and _mergeTimer().
Future<void> _mergeDelta(
  AppDatabase db,
  HybridLogicalClock clock,
  Map<String, dynamic> delta,
) async {
  final type = delta['type'] as String;
  final id = delta['id'] as String;

  if (type == _timerDocType) {
    await _mergeTimer(db, clock, id, delta);
  }
}

/// Merges a timer delta — mirrors CrdtSyncService._mergeTimer().
Future<void> _mergeTimer(
  AppDatabase db,
  HybridLogicalClock clock,
  String id,
  Map<String, dynamic> delta,
) async {
  final state = CrdtDocument.stateFromJson(delta);

  // Advance clock for remote timestamps (mirrors _mergeDelta)
  for (final entry in state.entries) {
    final ts = entry.value.timestamp;
    if (ts != null) {
      try {
        clock.receive(ts);
      } catch (_) {}
    }
  }

  // Load existing or create new timer document
  final rows = await (db.select(db.timerEntries)
        ..where((t) => t.id.equals(id)))
      .get();

  final doc = rows.isNotEmpty
      ? TimerDocument.fromDrift(timer: rows.first, clock: clock)
      : TimerDocument.fromState(id: id, clock: clock, state: {});

  // Apply CRDT state via LWW merge
  for (final entry in state.entries) {
    doc.mergeField(
      entry.key,
      value: entry.value.value,
      timestamp: entry.value.timestamp,
    );
  }

  // Persist to local DB (mirrors insertOnConflictUpdate)
  await db.into(db.timerEntries).insertOnConflictUpdate(doc.toDriftCompanion());
}