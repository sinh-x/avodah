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
      final remoteSyncApi =
          SyncApiService(db: remoteDb, clock: remoteClock);

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
}
