/// Phase 10: Timer round-trip test — verifies sync latency < 5 seconds.
///
/// Simulates the full bidirectional CRDT sync flow between a desktop node
/// and a phone node using in-memory databases (no HTTP server required).
///
/// Flow:
///   1. Desktop creates a timer (start)
///   2. Phone pulls deltas from desktop (extractDeltas)
///   3. Phone stops the timer locally (local mutation)
///   4. Phone pushes delta to desktop (mergePushBatch)
///   5. Desktop verifies the stopped timer was merged
///   6. Total elapsed time must be < 5 seconds
library;

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  group('timer round-trip sync', () {
    test('desktop → phone → desktop timer update completes in < 5s', () async {
      final stopwatch = Stopwatch()..start();

      // ─── Desktop setup ────────────────────────────────────────────────────
      final desktopDb = openMemoryDatabase();
      final desktopClock = HybridLogicalClock(nodeId: 'desktop-1');
      final desktopSync = SyncApiService(db: desktopDb, clock: desktopClock);
      final desktopTimer = TimerService(db: desktopDb, clock: desktopClock);

      // ─── Phone setup ──────────────────────────────────────────────────────
      final phoneDb = openMemoryDatabase();
      final phoneClock = HybridLogicalClock(nodeId: 'phone-1');
      final phoneSync = SyncApiService(db: phoneDb, clock: phoneClock);

      // Step 1: Desktop starts a timer
      await desktopTimer.start(taskTitle: 'Phase 10 round-trip');

      // Verify timer is running on desktop
      final desktopTimers = await desktopDb.select(desktopDb.timerEntries).get();
      expect(desktopTimers, hasLength(1));
      expect(desktopTimers[0].isRunning, isTrue);
      expect(desktopTimers[0].taskTitle, equals('Phase 10 round-trip'));

      // Step 2: Phone pulls all deltas from desktop (initial sync)
      final since = HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
      final deltas = await desktopSync.extractDeltas(since);

      expect(deltas, isNotEmpty);
      final timerDeltas = deltas.where((d) => d['type'] == SyncDocType.timer).toList();
      expect(timerDeltas, hasLength(1));
      expect(
        (timerDeltas[0]['fields'] as Map)['isRunning']['v'],
        isTrue,
        reason: 'Phone should see running timer',
      );

      // Phone merges desktop deltas into its local DB
      for (final delta in deltas) {
        await phoneSync.mergeDelta(delta);
      }

      final phoneTimers = await phoneDb.select(phoneDb.timerEntries).get();
      expect(phoneTimers, hasLength(1));
      expect(phoneTimers[0].isRunning, isTrue,
          reason: 'Phone local DB should have running timer');

      // Step 3: Phone stops the timer locally (creates a CRDT delta)
      final phoneStopTs = phoneClock.now();
      final stopDelta = {
        'type': SyncDocType.timer,
        'id': activeTimerId,
        'fields': {
          'isRunning': {'v': false, 't': phoneStopTs.pack()},
          'accumulatedMs': {'v': 1000, 't': phoneStopTs.pack()},
        },
      };

      // Apply locally on phone
      await phoneSync.mergeDelta(stopDelta);

      final phoneTimersAfterStop = await phoneDb.select(phoneDb.timerEntries).get();
      expect(phoneTimersAfterStop[0].isRunning, isFalse,
          reason: 'Phone should have stopped timer locally');

      // Step 4: Phone pushes the stop delta to desktop
      final pushResult = await desktopSync.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [stopDelta],
      );

      expect(pushResult.merged, equals(1));
      expect(pushResult.errors, isEmpty);

      // Step 5: Desktop verifies the stopped timer was merged
      final desktopTimersAfterMerge =
          await desktopDb.select(desktopDb.timerEntries).get();
      expect(desktopTimersAfterMerge, hasLength(1));
      expect(desktopTimersAfterMerge[0].isRunning, isFalse,
          reason: 'Desktop should see timer stopped by phone');
      expect(desktopTimersAfterMerge[0].taskTitle, equals('Phase 10 round-trip'),
          reason: 'Timer title should be preserved after merge');

      // Step 6: Assert total round-trip time < 5 seconds
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
        reason: 'Full sync round-trip must complete in < 5 seconds '
            '(took ${stopwatch.elapsedMilliseconds}ms)',
      );

      await desktopDb.close();
      await phoneDb.close();
    });

    test('phone-initiated timer start syncs to desktop', () async {
      final stopwatch = Stopwatch()..start();

      // ─── Desktop setup ────────────────────────────────────────────────────
      final desktopDb = openMemoryDatabase();
      final desktopClock = HybridLogicalClock(nodeId: 'desktop-1');
      final desktopSync = SyncApiService(db: desktopDb, clock: desktopClock);

      // ─── Phone setup ──────────────────────────────────────────────────────
      final phoneClock = HybridLogicalClock(nodeId: 'phone-1');

      // Phone starts a timer locally
      final phoneStartTs = phoneClock.now();
      final startDelta = {
        'type': SyncDocType.timer,
        'id': activeTimerId,
        'fields': {
          'taskTitle': {'v': 'Phone-started work', 't': phoneStartTs.pack()},
          'isRunning': {'v': true, 't': phoneStartTs.pack()},
          'startedAt': {
            'v': DateTime.now().millisecondsSinceEpoch,
            't': phoneStartTs.pack(),
          },
          'accumulatedMs': {'v': 0, 't': phoneStartTs.pack()},
        },
      };

      // Phone pushes to desktop
      final pushResult = await desktopSync.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [startDelta],
      );

      expect(pushResult.merged, equals(1));
      expect(pushResult.errors, isEmpty);

      // Desktop verifies timer is running
      final timers = await desktopDb.select(desktopDb.timerEntries).get();
      expect(timers, hasLength(1));
      expect(timers[0].taskTitle, equals('Phone-started work'));
      expect(timers[0].isRunning, isTrue);

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
        reason: 'Phone→desktop timer push must complete in < 5 seconds '
            '(took ${stopwatch.elapsedMilliseconds}ms)',
      );

      await desktopDb.close();
    });

    test('watermarks are updated after bidirectional sync', () async {
      final desktopDb = openMemoryDatabase();
      final desktopClock = HybridLogicalClock(nodeId: 'desktop-1');
      final desktopSync = SyncApiService(db: desktopDb, clock: desktopClock);
      final desktopTimer = TimerService(db: desktopDb, clock: desktopClock);

      final phoneDb = openMemoryDatabase();
      final phoneClock = HybridLogicalClock(nodeId: 'phone-1');
      final phoneSync = SyncApiService(db: phoneDb, clock: phoneClock);

      // Desktop creates timer
      await desktopTimer.start(taskTitle: 'Watermark test');

      // Phone pulls
      final since = HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
      final deltas = await desktopSync.extractDeltas(since);
      for (final d in deltas) {
        await phoneSync.mergeDelta(d);
      }

      // Phone stops and pushes
      final phoneTs = phoneClock.now();
      await desktopSync.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [
          {
            'type': SyncDocType.timer,
            'id': activeTimerId,
            'fields': {
              'isRunning': {'v': false, 't': phoneTs.pack()},
              'accumulatedMs': {'v': 500, 't': phoneTs.pack()},
            },
          },
        ],
      );

      // Desktop should have stored a watermark for phone-1
      final wm = await desktopSync.getWatermark('phone-1', direction: 'received');
      expect(wm, isNot(equals('0')),
          reason: 'Desktop should record watermark for phone after push');

      await desktopDb.close();
      await phoneDb.close();
    });
  });
}
