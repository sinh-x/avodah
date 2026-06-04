import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late SyncApiService syncApi;
  late TaskService taskService;
  late TimerService timerService;
  late WorklogService worklogService;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'desktop-1');
    syncApi = SyncApiService(db: db, clock: clock);
    taskService = TaskService(db: db, clock: clock);
    timerService = TimerService(db: db, clock: clock);
    worklogService = WorklogService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
  });

  group('delta extraction', () {
    test('returns empty list when database is empty', () async {
      final since = HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
      final deltas = await syncApi.extractDeltas(since);

      expect(deltas, isEmpty);
    });

    test('returns task deltas after watermark', () async {
      // Create a task
      await taskService.add(title: 'Test task');

      // Extract deltas from beginning
      final since = HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
      final deltas = await syncApi.extractDeltas(since);

      expect(deltas, hasLength(1));
      expect(deltas[0]['type'], equals(SyncDocType.task));
      expect(deltas[0]['id'], isNotEmpty);
      expect(deltas[0]['fields'], isA<Map>());

      // Verify fields contain title
      final fields = deltas[0]['fields'] as Map<String, dynamic>;
      expect(fields['title'], isNotNull);
      final titleField = fields['title'] as Map<String, dynamic>;
      expect(titleField['v'], equals('Test task'));
      expect(titleField['t'], isNotNull);
    });

    test('filters by watermark — excludes older documents', () async {
      await taskService.add(title: 'Old task');

      // Capture watermark after first task
      final watermark = clock.lastTimestamp;

      await taskService.add(title: 'New task');

      final deltas = await syncApi.extractDeltas(watermark);

      // Should only include the new task
      expect(deltas, hasLength(1));
      final fields = deltas[0]['fields'] as Map<String, dynamic>;
      expect((fields['title'] as Map)['v'], equals('New task'));
    });

    test('includes multiple document types', () async {
      await taskService.add(title: 'A task');
      await timerService.start(taskTitle: 'Working');

      final since = HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
      final deltas = await syncApi.extractDeltas(since);

      final types = deltas.map((d) => d['type']).toSet();
      expect(types, contains(SyncDocType.task));
      expect(types, contains(SyncDocType.timer));
    });
  });

  group('delta merge', () {
    test('merges a new task from remote', () async {
      // Simulate a delta from a remote node
      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'phone-1',
      );

      final delta = {
        'type': SyncDocType.task,
        'id': 'remote-task-1',
        'fields': {
          'title': {'v': 'Remote task', 't': remoteTs.pack()},
          'isDone': {'v': false, 't': remoteTs.pack()},
          'created': {
            'v': DateTime.now().millisecondsSinceEpoch,
            't': remoteTs.pack(),
          },
          'timeSpent': {'v': 0, 't': remoteTs.pack()},
          'timeEstimate': {'v': 0, 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      // Verify task was created
      final tasks = await db.select(db.tasks).get();
      expect(tasks, hasLength(1));
      expect(tasks[0].id, equals('remote-task-1'));
      expect(tasks[0].title, equals('Remote task'));
    });

    test('merges remote changes into existing task (LWW)', () async {
      // Create a local task
      final task = await taskService.add(title: 'Local title');

      // Remote update with a later timestamp
      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch + 1000,
        counter: 0,
        nodeId: 'phone-1',
      );

      final delta = {
        'type': SyncDocType.task,
        'id': task.id,
        'fields': {
          'title': {'v': 'Updated from phone', 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      // Remote wins (later timestamp)
      final rows = await db.select(db.tasks).get();
      expect(rows[0].title, equals('Updated from phone'));
    });

    test('local wins when local timestamp is newer', () async {
      // Create a local task with current clock
      final task = await taskService.add(title: 'Local title');

      // Remote update with an OLD timestamp
      final remoteTs = HybridTimestamp(
        physicalTime: 1000, // very old
        counter: 0,
        nodeId: 'phone-1',
      );

      final delta = {
        'type': SyncDocType.task,
        'id': task.id,
        'fields': {
          'title': {'v': 'Old remote title', 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      // Local wins (later timestamp)
      final rows = await db.select(db.tasks).get();
      expect(rows[0].title, equals('Local title'));
    });

    test('merges worklog from remote', () async {
      // Create a task first
      final task = await taskService.add(title: 'Work task');

      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'phone-1',
      );

      final start = DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch;
      final end = DateTime.now().millisecondsSinceEpoch;

      final delta = {
        'type': SyncDocType.worklog,
        'id': 'remote-worklog-1',
        'fields': {
          'taskId': {'v': task.id, 't': remoteTs.pack()},
          'start': {'v': start, 't': remoteTs.pack()},
          'end': {'v': end, 't': remoteTs.pack()},
          'duration': {'v': end - start, 't': remoteTs.pack()},
          'date': {'v': '2026-03-17', 't': remoteTs.pack()},
          'created': {'v': start, 't': remoteTs.pack()},
          'updated': {'v': end, 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      final worklogs = await db.select(db.worklogEntries).get();
      expect(worklogs, hasLength(1));
      expect(worklogs[0].id, equals('remote-worklog-1'));
    });

    test('merges timer state from remote', () async {
      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'phone-1',
      );

      final delta = {
        'type': SyncDocType.timer,
        'id': activeTimerId,
        'fields': {
          'taskTitle': {'v': 'Phone timer', 't': remoteTs.pack()},
          'isRunning': {'v': true, 't': remoteTs.pack()},
          'startedAt': {
            'v': DateTime.now().millisecondsSinceEpoch,
            't': remoteTs.pack(),
          },
          'accumulatedMs': {'v': 0, 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      final timers = await db.select(db.timerEntries).get();
      expect(timers, hasLength(1));
      expect(timers[0].taskTitle, equals('Phone timer'));
      expect(timers[0].isRunning, isTrue);
    });

    test('merges categoryChip from remote', () async {
      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'phone-1',
      );

      final delta = {
        'type': SyncDocType.categoryChip,
        'id': 'remote-chip-1',
        'fields': {
          'category': {'v': 'Working', 't': remoteTs.pack()},
          'label': {'v': 'standup', 't': remoteTs.pack()},
          'sortOrder': {'v': 0, 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      final chips = await db.select(db.categoryChips).get();
      expect(chips, hasLength(1));
      expect(chips[0].id, equals('remote-chip-1'));
      expect(chips[0].category, equals('Working'));
      expect(chips[0].label, equals('standup'));
      expect(chips[0].sortOrder, equals(0));
    });

    test('merges remote changes into existing categoryChip (LWW)', () async {
      // Create a local chip
      final localChip = CategoryChipDocument.create(
        clock: clock,
        category: 'Working',
        label: 'local-label',
      );
      await db.into(db.categoryChips).insert(localChip.toDriftCompanion());

      // Remote update with a later timestamp
      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch + 1000,
        counter: 0,
        nodeId: 'phone-1',
      );

      final delta = {
        'type': SyncDocType.categoryChip,
        'id': localChip.id,
        'fields': {
          'label': {'v': 'Updated from phone', 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      // Remote wins (later timestamp)
      final rows = await db.select(db.categoryChips).get();
      expect(rows[0].label, equals('Updated from phone'));
    });

    test('local wins when local timestamp is newer for categoryChip', () async {
      // Create a local chip with current clock
      final localChip = CategoryChipDocument.create(
        clock: clock,
        category: 'Working',
        label: 'Local label',
      );
      await db.into(db.categoryChips).insert(localChip.toDriftCompanion());

      // Remote update with an OLD timestamp
      final remoteTs = HybridTimestamp(
        physicalTime: 1000, // very old
        counter: 0,
        nodeId: 'phone-1',
      );

      final delta = {
        'type': SyncDocType.categoryChip,
        'id': localChip.id,
        'fields': {
          'label': {'v': 'Old remote label', 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      // Local wins (later timestamp)
      final rows = await db.select(db.categoryChips).get();
      expect(rows[0].label, equals('Local label'));
    });

    test('merges categoryChip sortOrder from remote', () async {
      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'phone-1',
      );

      final delta = {
        'type': SyncDocType.categoryChip,
        'id': 'chip-sort-test',
        'fields': {
          'category': {'v': 'Learning', 't': remoteTs.pack()},
          'label': {'v': 'course', 't': remoteTs.pack()},
          'sortOrder': {'v': 5, 't': remoteTs.pack()},
        },
      };

      await syncApi.mergeDelta(delta);

      final chips = await db.select(db.categoryChips).get();
      expect(chips, hasLength(1));
      expect(chips[0].sortOrder, equals(5));
    });
  });

  group('watermark tracking', () {
    test('getWatermark returns "0" when no watermark stored', () async {
      final wm = await syncApi.getWatermark('phone-1');
      expect(wm, equals('0'));
    });

    test('setWatermark stores and getWatermark retrieves it', () async {
      const nodeId = 'phone-1';
      const hlc = '1741234567890-0-phone-1';

      await syncApi.setWatermark(nodeId, hlc, direction: 'received');

      final wm = await syncApi.getWatermark(nodeId, direction: 'received');
      expect(wm, equals(hlc));
    });

    test('setWatermark upserts — updating existing watermark', () async {
      const nodeId = 'phone-1';
      const hlc1 = '1741234567890-0-phone-1';
      const hlc2 = '1741234567999-1-phone-1';

      await syncApi.setWatermark(nodeId, hlc1);
      await syncApi.setWatermark(nodeId, hlc2);

      final wm = await syncApi.getWatermark(nodeId);
      expect(wm, equals(hlc2));
    });

    test('received and sent directions are tracked independently', () async {
      const nodeId = 'phone-1';
      const receivedHlc = '1741234567890-0-phone-1';
      const sentHlc = '1741234568000-0-desktop-1';

      await syncApi.setWatermark(nodeId, receivedHlc, direction: 'received');
      await syncApi.setWatermark(nodeId, sentHlc, direction: 'sent');

      expect(await syncApi.getWatermark(nodeId, direction: 'received'),
          equals(receivedHlc));
      expect(await syncApi.getWatermark(nodeId, direction: 'sent'),
          equals(sentHlc));
    });

    test('getAllWatermarks returns all stored entries', () async {
      await syncApi.setWatermark('phone-1', '1000-0-phone-1',
          direction: 'received');
      await syncApi.setWatermark('phone-1', '2000-0-desktop-1',
          direction: 'sent');
      await syncApi.setWatermark('phone-2', '1500-0-phone-2',
          direction: 'received');

      final all = await syncApi.getAllWatermarks();
      expect(all, hasLength(3));
      final nodeIds = all.map((e) => e['nodeId']).toSet();
      expect(nodeIds, containsAll(['phone-1', 'phone-2']));
    });

    test('syncDiagnostics uses most recent phone-* received watermark',
        () async {
      await syncApi.setWatermark('phone-older', '1000-0-phone-older',
          direction: 'received');
      await Future<void>.delayed(const Duration(milliseconds: 1));
      await syncApi.setWatermark('phone-newer', '2000-0-phone-newer',
          direction: 'received');

      final diagnostics = await syncApi.syncDiagnostics();

      expect(diagnostics['phoneWatermark'], equals('2000-0-phone-newer'));
      expect(diagnostics['lastPhoneSync'], isA<int>());
    });
  });

  group('mergePushBatch + onDeltasMerged propagation', () {
    test('callback is invoked with merged count', () async {
      var callbackCount = 0;
      var callbackArg = 0;
      final svcWithCb = SyncApiService(
        db: db,
        clock: clock,
        onDeltasMerged: (count) {
          callbackCount++;
          callbackArg = count;
        },
      );

      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'phone-1',
      );

      final result = await svcWithCb.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [
          {
            'type': SyncDocType.task,
            'id': 'phone-task-1',
            'fields': {
              'title': {'v': 'Phone task', 't': remoteTs.pack()},
              'isDone': {'v': false, 't': remoteTs.pack()},
              'created': {
                'v': DateTime.now().millisecondsSinceEpoch,
                't': remoteTs.pack()
              },
              'timeSpent': {'v': 0, 't': remoteTs.pack()},
              'timeEstimate': {'v': 0, 't': remoteTs.pack()},
            },
          },
        ],
      );

      expect(result.merged, equals(1));
      expect(result.errors, isEmpty);
      expect(result.watermark, isNotEmpty);
      expect(callbackCount, equals(1));
      expect(callbackArg, equals(1));
    });

    test('callback not invoked when no deltas merge successfully', () async {
      var callbackCount = 0;
      final svcWithCb = SyncApiService(
        db: db,
        clock: clock,
        onDeltasMerged: (_) => callbackCount++,
      );

      // Send a delta with an unknown type — should fail and not trigger callback
      final result = await svcWithCb.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [
          {'type': 'unknownType', 'id': 'x', 'fields': {}},
        ],
      );

      expect(result.merged, equals(0));
      expect(result.errors, hasLength(1));
      expect(callbackCount, equals(0));
    });

    test('records received watermark for remote node', () async {
      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'phone-1',
      );

      await syncApi.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [
          {
            'type': SyncDocType.timer,
            'id': activeTimerId,
            'fields': {
              'taskTitle': {'v': 'Phone timer', 't': remoteTs.pack()},
              'isRunning': {'v': true, 't': remoteTs.pack()},
              'startedAt': {
                'v': DateTime.now().millisecondsSinceEpoch,
                't': remoteTs.pack()
              },
              'accumulatedMs': {'v': 0, 't': remoteTs.pack()},
            },
          },
        ],
      );

      // Watermark should now be stored for phone-1
      final wm = await syncApi.getWatermark('phone-1', direction: 'received');
      expect(wm, isNot(equals('0')));
    });

    test('merges multiple delta types in one batch', () async {
      final task = await taskService.add(title: 'Existing task');

      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch + 1000,
        counter: 0,
        nodeId: 'phone-1',
      );

      final result = await syncApi.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [
          // Task update (toggle done)
          {
            'type': SyncDocType.task,
            'id': task.id,
            'fields': {
              'isDone': {'v': true, 't': remoteTs.pack()},
            },
          },
          // New timer
          {
            'type': SyncDocType.timer,
            'id': activeTimerId,
            'fields': {
              'taskTitle': {'v': 'Phone work', 't': remoteTs.pack()},
              'isRunning': {'v': true, 't': remoteTs.pack()},
              'startedAt': {
                'v': DateTime.now().millisecondsSinceEpoch,
                't': remoteTs.pack()
              },
              'accumulatedMs': {'v': 0, 't': remoteTs.pack()},
            },
          },
        ],
      );

      expect(result.merged, equals(2));
      expect(result.errors, isEmpty);

      final tasks = await db.select(db.tasks).get();
      expect(tasks.first.isDone, isTrue);

      final timers = await db.select(db.timerEntries).get();
      expect(timers.first.taskTitle, equals('Phone work'));
    });
  });

  group('round-trip sync', () {
    test('extract → merge recreates documents on remote', () async {
      // Create data on "desktop" — timer start also creates a task
      final task = await taskService.add(title: 'Sync test task');
      await timerService.start(taskTitle: 'Timer test', taskId: task.id);

      // Extract all deltas
      final since = HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
      final deltas = await syncApi.extractDeltas(since);

      // Create a "remote" database and merge
      final remoteDb = openMemoryDatabase();
      final remoteClock = HybridLogicalClock(nodeId: 'phone-1');
      final remoteSyncApi = SyncApiService(db: remoteDb, clock: remoteClock);

      for (final delta in deltas) {
        await remoteSyncApi.mergeDelta(delta);
      }

      // Verify remote has the same data
      final remoteTasks = await remoteDb.select(remoteDb.tasks).get();
      expect(remoteTasks, hasLength(1));
      expect(remoteTasks[0].title, equals('Sync test task'));

      final remoteTimers = await remoteDb.select(remoteDb.timerEntries).get();
      expect(remoteTimers, hasLength(1));
      expect(remoteTimers[0].taskTitle, equals('Timer test'));

      await remoteDb.close();
    });
  });

  group('stale timer detection', () {
    test('returns null when no phone watermark exists', () async {
      final warning = await syncApi.checkStaleTimer();
      expect(warning, isNull);
    });

    test('returns null when last sync is recent', () async {
      await syncApi.setWatermark('phone-1', '1000-0-phone-1',
          direction: 'received');

      final warning = await syncApi.checkStaleTimer();
      expect(warning, isNull);
    });

    test('returns null when timer is not running', () async {
      final staleTs =
          DateTime.now().millisecondsSinceEpoch - (avoStaleTimerMinutes + 1) * 60 * 1000;
      await syncApi.setWatermark(
        'phone-old',
        '1000-0-phone-old',
        direction: 'received',
        staleOverride: staleTs,
      );

      final warning = await syncApi.checkStaleTimer();
      expect(warning, isNull);
    });

    test('emits warning when timer is running and sync is stale', () async {
      await timerService.start(taskTitle: 'Running task');

      final staleTs =
          DateTime.now().millisecondsSinceEpoch - (avoStaleTimerMinutes + 1) * 60 * 1000;
      await syncApi.setWatermark(
        'phone-old',
        '1000-0-phone-old',
        direction: 'received',
        staleOverride: staleTs,
      );

      final warning = await syncApi.checkStaleTimer();
      expect(warning, isNotNull);
      expect(warning, contains('WARNING'));
      expect(warning, contains('avo sync diff'));
    });
  });

  group('timer reconciliation', () {
    test('phone stop wins when desktop timer is running and startedAt matches',
        () async {
      await timerService.start(taskTitle: 'Desktop timer');
      final desktopTimers = await db.select(db.timerEntries).get();
      final desktopStartedAt = desktopTimers.first.startedAt;

      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch + 1000,
        counter: 0,
        nodeId: 'phone-1',
      );

      await syncApi.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [
          {
            'type': SyncDocType.timer,
            'id': activeTimerId,
            'fields': {
              'isRunning': {
                'v': false,
                't': remoteTs.pack(),
              },
              'startedAt': {
                'v': desktopStartedAt,
                't': remoteTs.pack(),
              },
              'taskTitle': {
                'v': 'Desktop timer',
                't': remoteTs.pack(),
              },
            },
          },
        ],
      );

      final timers = await db.select(db.timerEntries).get();
      expect(timers.first.isRunning, isFalse);
      expect(timers.first.startedAt, equals(0));
      expect(timers.first.accumulatedMs, equals(0));
    });

    test('skips reconciliation when startedAt is outside window', () async {
      await timerService.start(taskTitle: 'Desktop timer');
      final desktopTimers = await db.select(db.timerEntries).get();
      final desktopStartedAt = desktopTimers.first.startedAt;

      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch + 1000,
        counter: 0,
        nodeId: 'phone-1',
      );

      // Phone startedAt is 10 minutes different from desktop
      final farStartedAt =
          desktopStartedAt + (avoTimerReconciliationWindowMs + 60000);

      await syncApi.mergePushBatch(
        remoteNode: 'phone-1',
        deltas: [
          {
            'type': SyncDocType.timer,
            'id': activeTimerId,
            'fields': {
              'isRunning': {
                'v': false,
                't': remoteTs.pack(),
              },
              'startedAt': {
                'v': farStartedAt,
                't': remoteTs.pack(),
              },
              'taskTitle': {
                'v': 'Desktop timer',
                't': remoteTs.pack(),
              },
            },
          },
        ],
      );

      // Timer state is LWW-merged from phone (isRunning=false wins)
      // but reconciliation-specific reset does not happen
      final timers = await db.select(db.timerEntries).get();
      expect(timers.first.isRunning, isFalse);
    });

    test('non-phone node merge does not trigger reconciliation', () async {
      await timerService.start(taskTitle: 'Desktop timer');

      final remoteTs = HybridTimestamp(
        physicalTime: DateTime.now().millisecondsSinceEpoch + 1000,
        counter: 0,
        nodeId: 'laptop-1',
      );

      await syncApi.mergePushBatch(
        remoteNode: 'laptop-1',
        deltas: [
          {
            'type': SyncDocType.timer,
            'id': activeTimerId,
            'fields': {
              'isRunning': {
                'v': false,
                't': remoteTs.pack(),
              },
              'taskTitle': {
                'v': 'Desktop timer',
                't': remoteTs.pack(),
              },
            },
          },
        ],
      );

      // No reconciliation for non-phone nodes — LWW merge only
      final timers = await db.select(db.timerEntries).get();
      expect(timers.first.isRunning, isFalse);
    });
  });
}
