/// CRDT delta sync API service for device-to-device synchronization.
///
/// Provides HTTP endpoints for pulling and pushing CRDT deltas:
/// - `GET /api/sync/deltas?since=<hlc-packed>` — pull changes since watermark
/// - `POST /api/sync/deltas` — push deltas from remote node
///
/// All document types (tasks, worklogs, timers, projects, daily plans,
/// day plan tasks) are synced. Jira integrations are excluded as they
/// contain device-specific credential paths.
library;

import 'dart:convert';
import 'dart:io';

import 'package:avodah_core/avodah_core.dart';
import 'package:drift/drift.dart' show Value;

/// Document type identifiers used in sync delta payloads.
class SyncDocType {
  SyncDocType._();

  static const String task = 'task';
  static const String worklog = 'worklog';
  static const String timer = 'timer';
  static const String project = 'project';
  static const String dailyPlan = 'dailyPlan';
  static const String dayPlanTask = 'dayPlanTask';
}

/// Handles CRDT delta sync HTTP requests.
class SyncApiService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  SyncApiService({required this.db, required this.clock});

  /// Routes a sync API request. Returns true if handled.
  Future<bool> handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    if (path != '/api/sync/deltas') return false;

    // CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers
        .add('Access-Control-Allow-Headers', 'Content-Type');

    if (method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      return true;
    }

    try {
      if (method == 'GET') {
        await _handlePullDeltas(request);
      } else if (method == 'POST') {
        await _handlePushDeltas(request);
      } else {
        _jsonResponse(request, HttpStatus.methodNotAllowed,
            {'error': 'Method not allowed'});
      }
    } catch (e, stack) {
      stderr.writeln('Sync API error: $e\n$stack');
      _jsonResponse(
          request, HttpStatus.internalServerError, {'error': e.toString()});
    }

    return true;
  }

  /// GET /api/sync/deltas?since=<hlc-packed>
  ///
  /// Returns all CRDT deltas modified after the given HLC watermark.
  /// If `since` is omitted or "0", returns all documents (full sync).
  Future<void> _handlePullDeltas(HttpRequest request) async {
    final sinceParam = request.uri.queryParameters['since'];
    final since = _parseWatermark(sinceParam);

    final deltas = await extractDeltas(since);

    // Current clock state as the new watermark
    final watermark = clock.now().pack();

    _jsonResponse(request, HttpStatus.ok, {
      'deltas': deltas,
      'watermark': watermark,
      'nodeId': clock.nodeId,
      'count': deltas.length,
    });
  }

  /// POST /api/sync/deltas
  ///
  /// Accepts CRDT deltas from a remote node and merges them.
  /// Body: {"node": "<node-id>", "deltas": [{"type": "...", "id": "...", "fields": {...}}]}
  Future<void> _handlePushDeltas(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final json = jsonDecode(body) as Map<String, dynamic>;

    final remoteNode = json['node'] as String?;
    final deltasJson = json['deltas'] as List<dynamic>? ?? [];

    if (remoteNode == null || remoteNode.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Missing "node" field'});
      return;
    }

    var merged = 0;
    final errors = <String>[];

    for (final deltaJson in deltasJson) {
      final delta = deltaJson as Map<String, dynamic>;
      try {
        await mergeDelta(delta);
        merged++;
      } catch (e) {
        errors.add('${delta['type']}/${delta['id']}: $e');
      }
    }

    final watermark = clock.now().pack();

    // Record the watermark of what we received from the remote node
    if (merged > 0) {
      await setWatermark(remoteNode, watermark, direction: 'received');
    }

    _jsonResponse(request, HttpStatus.ok, {
      'merged': merged,
      'errors': errors,
      'watermark': watermark,
      'nodeId': clock.nodeId,
    });
  }

  /// Extracts all CRDT deltas modified after [since].
  Future<List<Map<String, dynamic>>> extractDeltas(
      HybridTimestamp since) async {
    final deltas = <Map<String, dynamic>>[];

    // Tasks
    final tasks = await db.select(db.tasks).get();
    for (final row in tasks) {
      if (_isAfterWatermark(row.crdtClock, since)) {
        final doc = TaskDocument.fromDrift(task: row, clock: clock);
        deltas.add(_wrapDelta(SyncDocType.task, doc));
      }
    }

    // Worklogs
    final worklogs = await db.select(db.worklogEntries).get();
    for (final row in worklogs) {
      if (_isAfterWatermark(row.crdtClock, since)) {
        final doc = WorklogDocument.fromDrift(worklog: row, clock: clock);
        deltas.add(_wrapDelta(SyncDocType.worklog, doc));
      }
    }

    // Timer
    final timers = await db.select(db.timerEntries).get();
    for (final row in timers) {
      if (_isAfterWatermark(row.crdtClock, since)) {
        final doc = TimerDocument.fromDrift(timer: row, clock: clock);
        deltas.add(_wrapDelta(SyncDocType.timer, doc));
      }
    }

    // Projects
    final projects = await db.select(db.projects).get();
    for (final row in projects) {
      if (_isAfterWatermark(row.crdtClock, since)) {
        final doc = ProjectDocument.fromDrift(project: row, clock: clock);
        deltas.add(_wrapDelta(SyncDocType.project, doc));
      }
    }

    // Daily Plans
    final dailyPlans = await db.select(db.dailyPlanEntries).get();
    for (final row in dailyPlans) {
      if (_isAfterWatermark(row.crdtClock, since)) {
        final doc = DailyPlanDocument.fromDrift(entry: row, clock: clock);
        deltas.add(_wrapDelta(SyncDocType.dailyPlan, doc));
      }
    }

    // Day Plan Tasks
    final dayPlanTasks = await db.select(db.dayPlanTasks).get();
    for (final row in dayPlanTasks) {
      if (_isAfterWatermark(row.crdtClock, since)) {
        final doc = DayPlanTaskDocument.fromDrift(entry: row, clock: clock);
        deltas.add(_wrapDelta(SyncDocType.dayPlanTask, doc));
      }
    }

    return deltas;
  }

  /// Merges a single incoming delta into the local database.
  Future<void> mergeDelta(Map<String, dynamic> delta) async {
    final type = delta['type'] as String;
    final id = delta['id'] as String;
    final fields = delta['fields'] as Map<String, dynamic>? ?? {};

    // Receive remote timestamps to advance our clock
    for (final entry in fields.entries) {
      final field = entry.value as Map<String, dynamic>;
      final tStr = field['t'] as String?;
      if (tStr != null) {
        clock.receive(HybridTimestamp.parse(tStr));
      }
    }

    final state = CrdtDocument.stateFromJson(delta);

    switch (type) {
      case SyncDocType.task:
        await _mergeTask(id, state);
      case SyncDocType.worklog:
        await _mergeWorklog(id, state);
      case SyncDocType.timer:
        await _mergeTimer(id, state);
      case SyncDocType.project:
        await _mergeProject(id, state);
      case SyncDocType.dailyPlan:
        await _mergeDailyPlan(id, state);
      case SyncDocType.dayPlanTask:
        await _mergeDayPlanTask(id, state);
      default:
        throw ArgumentError('Unknown delta type: $type');
    }
  }

  Future<void> _mergeTask(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.tasks)
          ..where((t) => t.id.equals(id)))
        .get();

    final TaskDocument doc;
    if (rows.isNotEmpty) {
      doc = TaskDocument.fromDrift(task: rows.first, clock: clock);
    } else {
      doc = TaskDocument.fromState(id: id, clock: clock, state: {});
    }

    _applyState(doc, state);
    await db.into(db.tasks).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeWorklog(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.worklogEntries)
          ..where((t) => t.id.equals(id)))
        .get();

    final WorklogDocument doc;
    if (rows.isNotEmpty) {
      doc = WorklogDocument.fromDrift(worklog: rows.first, clock: clock);
    } else {
      doc = WorklogDocument.fromState(id: id, clock: clock, state: {});
    }

    _applyState(doc, state);
    await db
        .into(db.worklogEntries)
        .insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeTimer(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.timerEntries)
          ..where((t) => t.id.equals(id)))
        .get();

    final TimerDocument doc;
    if (rows.isNotEmpty) {
      doc = TimerDocument.fromDrift(timer: rows.first, clock: clock);
    } else {
      doc = TimerDocument.fromState(id: id, clock: clock, state: {});
    }

    _applyState(doc, state);
    await db
        .into(db.timerEntries)
        .insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeProject(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.projects)
          ..where((t) => t.id.equals(id)))
        .get();

    final ProjectDocument doc;
    if (rows.isNotEmpty) {
      doc = ProjectDocument.fromDrift(project: rows.first, clock: clock);
    } else {
      doc = ProjectDocument.fromState(id: id, clock: clock, state: {});
    }

    _applyState(doc, state);
    await db.into(db.projects).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeDailyPlan(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.dailyPlanEntries)
          ..where((t) => t.id.equals(id)))
        .get();

    final DailyPlanDocument doc;
    if (rows.isNotEmpty) {
      doc = DailyPlanDocument.fromDrift(entry: rows.first, clock: clock);
    } else {
      doc = DailyPlanDocument.fromState(id: id, clock: clock, state: {});
    }

    _applyState(doc, state);
    await db
        .into(db.dailyPlanEntries)
        .insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeDayPlanTask(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.dayPlanTasks)
          ..where((t) => t.id.equals(id)))
        .get();

    final DayPlanTaskDocument doc;
    if (rows.isNotEmpty) {
      doc = DayPlanTaskDocument.fromDrift(entry: rows.first, clock: clock);
    } else {
      doc = DayPlanTaskDocument.fromState(id: id, clock: clock, state: {});
    }

    _applyState(doc, state);
    await db
        .into(db.dayPlanTasks)
        .insertOnConflictUpdate(doc.toDriftCompanion());
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// Applies CRDT field state to a document using per-field merge.
  void _applyState(
      CrdtDocument doc, Map<String, CrdtFieldState> state) {
    for (final entry in state.entries) {
      doc.mergeField(
        entry.key,
        value: entry.value.value,
        timestamp: entry.value.timestamp,
      );
    }
  }

  /// Wraps a CRDT document as a typed sync delta.
  Map<String, dynamic> _wrapDelta(String type, CrdtDocument doc) {
    final json = doc.toJson();
    return {
      'type': type,
      'id': json['id'],
      'fields': json['fields'],
    };
  }

  /// Parses a watermark string into a HybridTimestamp.
  /// Returns a zero timestamp if null, empty, or "0".
  HybridTimestamp _parseWatermark(String? watermark) {
    if (watermark == null || watermark.isEmpty || watermark == '0') {
      return HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
    }
    return HybridTimestamp.parse(watermark);
  }

  /// Returns true if the document's crdtClock is after the watermark.
  bool _isAfterWatermark(String crdtClock, HybridTimestamp since) {
    if (crdtClock.isEmpty) return true; // Include docs without clock
    try {
      final docTs = HybridTimestamp.parse(crdtClock);
      return docTs > since;
    } catch (_) {
      return true; // Include docs with unparseable clock
    }
  }

  // ============================================================
  // Watermark management
  // ============================================================

  /// Returns the stored HLC watermark for [nodeId] in the given [direction].
  ///
  /// [direction] is either 'received' (data from node) or 'sent' (data to node).
  /// Returns "0" if no watermark has been recorded yet.
  Future<String> getWatermark(String nodeId,
      {String direction = 'received'}) async {
    final rows = await (db.select(db.syncWatermarks)
          ..where((w) => w.nodeId.equals(nodeId)))
        .get();
    final match = rows.where((r) => r.direction == direction);
    if (match.isEmpty) return '0';
    final hlc = match.first.lastHlc;
    return hlc.isEmpty ? '0' : hlc;
  }

  /// Stores or updates the HLC watermark for [nodeId] in the given [direction].
  Future<void> setWatermark(String nodeId, String hlcPacked,
      {String direction = 'received'}) async {
    await db.into(db.syncWatermarks).insertOnConflictUpdate(
          SyncWatermarksCompanion.insert(
            nodeId: nodeId,
            lastHlc: Value(hlcPacked),
            direction: Value(direction),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  /// Returns all stored watermarks (for diagnostics / status endpoint).
  Future<List<Map<String, dynamic>>> getAllWatermarks() async {
    final rows = await db.select(db.syncWatermarks).get();
    return rows
        .map((r) => {
              'nodeId': r.nodeId,
              'direction': r.direction,
              'lastHlc': r.lastHlc,
              'updatedAt': r.updatedAt,
            })
        .toList();
  }

  /// Sends a JSON response.
  void _jsonResponse(
      HttpRequest request, int statusCode, Map<String, dynamic> body) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body))
      ..close();
  }
}
