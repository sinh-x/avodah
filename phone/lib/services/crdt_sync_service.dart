/// CRDT delta sync service for the phone app.
///
/// Pulls CRDT deltas from the desktop server and merges them
/// into the local phone database.
///
/// Protocol:
///   GET /api/sync/deltas?since=[hlc-packed]&node=[phone-node-id]
///   → {deltas, watermark, nodeId, count}
///
/// Watermark tracking: phone stores the desktop's watermark in
/// [AppDatabase.syncWatermarks] with nodeId='desktop' and direction='received'.
library;

import 'dart:convert';

import 'package:avodah_core/avodah_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kDesktopNodeId = 'desktop';
const _kPhoneNodeIdKey = 'crdt_node_id';

/// Document type identifiers matching the desktop SyncApiService.
class _SyncDocType {
  _SyncDocType._();

  static const String task = 'task';
  static const String worklog = 'worklog';
  static const String timer = 'timer';
  static const String project = 'project';
  static const String dailyPlan = 'dailyPlan';
  static const String dayPlanTask = 'dayPlanTask';
}

/// Sync service that pulls CRDT deltas from the desktop via HTTP.
class CrdtSyncService {
  final String baseUrl;
  final AppDatabase db;
  final HybridLogicalClock clock;
  final http.Client _client;

  CrdtSyncService({
    required this.baseUrl,
    required this.db,
    required this.clock,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Returns or creates the phone's persistent node ID.
  static Future<String> getOrCreateNodeId() async {
    final prefs = await SharedPreferences.getInstance();
    var nodeId = prefs.getString(_kPhoneNodeIdKey);
    if (nodeId == null || nodeId.isEmpty) {
      // Generate a stable node ID from timestamp + random bits
      nodeId = 'phone-${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_kPhoneNodeIdKey, nodeId);
    }
    return nodeId;
  }

  /// Pull all CRDT deltas from the desktop since the last known watermark.
  ///
  /// Returns the number of deltas merged, or throws on HTTP error.
  Future<int> pullFromDesktop() async {
    final watermark = await _getDesktopWatermark();

    final nodeId = await getOrCreateNodeId();
    final uri = Uri.parse(
      '$baseUrl/api/sync/deltas?since=${Uri.encodeComponent(watermark)}&node=${Uri.encodeComponent(nodeId)}',
    );

    debugPrint('[CrdtSync] Pulling deltas since $watermark from $uri');

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Sync pull failed: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final deltas = json['deltas'] as List<dynamic>? ?? [];
    final newWatermark = json['watermark'] as String? ?? '0';

    var merged = 0;
    for (final deltaJson in deltas) {
      final delta = deltaJson as Map<String, dynamic>;
      try {
        await _mergeDelta(delta);
        merged++;
      } catch (e) {
        debugPrint('[CrdtSync] Failed to merge delta ${delta['type']}/${delta['id']}: $e');
      }
    }

    // Advance our clock to at least the desktop's watermark
    if (newWatermark != '0') {
      try {
        clock.receive(HybridTimestamp.parse(newWatermark));
      } catch (_) {}
    }

    // Store the new watermark so next pull is incremental
    if (newWatermark != '0') {
      await _setDesktopWatermark(newWatermark);
    }

    debugPrint('[CrdtSync] Merged $merged/${deltas.length} deltas. New watermark: $newWatermark');
    return merged;
  }

  // ============================================================
  // Merge logic (mirrors desktop SyncApiService.mergeDelta)
  // ============================================================

  Future<void> _mergeDelta(Map<String, dynamic> delta) async {
    final type = delta['type'] as String;
    final id = delta['id'] as String;
    final fields = delta['fields'] as Map<String, dynamic>? ?? {};

    // Advance clock to incorporate remote timestamps
    for (final entry in fields.entries) {
      final field = entry.value as Map<String, dynamic>;
      final tStr = field['t'] as String?;
      if (tStr != null) {
        try {
          clock.receive(HybridTimestamp.parse(tStr));
        } catch (_) {}
      }
    }

    final state = CrdtDocument.stateFromJson(delta);

    switch (type) {
      case _SyncDocType.task:
        await _mergeTask(id, state);
      case _SyncDocType.worklog:
        await _mergeWorklog(id, state);
      case _SyncDocType.timer:
        await _mergeTimer(id, state);
      case _SyncDocType.project:
        await _mergeProject(id, state);
      case _SyncDocType.dailyPlan:
        await _mergeDailyPlan(id, state);
      case _SyncDocType.dayPlanTask:
        await _mergeDayPlanTask(id, state);
      default:
        debugPrint('[CrdtSync] Unknown delta type: $type — skipping');
    }
  }

  Future<void> _mergeTask(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.tasks)
          ..where((t) => t.id.equals(id)))
        .get();
    final doc = rows.isNotEmpty
        ? TaskDocument.fromDrift(task: rows.first, clock: clock)
        : TaskDocument.fromState(id: id, clock: clock, state: {});
    _applyState(doc, state);
    await db.into(db.tasks).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeWorklog(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.worklogEntries)
          ..where((t) => t.id.equals(id)))
        .get();
    final doc = rows.isNotEmpty
        ? WorklogDocument.fromDrift(worklog: rows.first, clock: clock)
        : WorklogDocument.fromState(id: id, clock: clock, state: {});
    _applyState(doc, state);
    await db.into(db.worklogEntries).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeTimer(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.timerEntries)
          ..where((t) => t.id.equals(id)))
        .get();
    final doc = rows.isNotEmpty
        ? TimerDocument.fromDrift(timer: rows.first, clock: clock)
        : TimerDocument.fromState(id: id, clock: clock, state: {});
    _applyState(doc, state);
    await db.into(db.timerEntries).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeProject(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.projects)
          ..where((t) => t.id.equals(id)))
        .get();
    final doc = rows.isNotEmpty
        ? ProjectDocument.fromDrift(project: rows.first, clock: clock)
        : ProjectDocument.fromState(id: id, clock: clock, state: {});
    _applyState(doc, state);
    await db.into(db.projects).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeDailyPlan(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.dailyPlanEntries)
          ..where((t) => t.id.equals(id)))
        .get();
    final doc = rows.isNotEmpty
        ? DailyPlanDocument.fromDrift(entry: rows.first, clock: clock)
        : DailyPlanDocument.fromState(id: id, clock: clock, state: {});
    _applyState(doc, state);
    await db.into(db.dailyPlanEntries).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  Future<void> _mergeDayPlanTask(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.dayPlanTasks)
          ..where((t) => t.id.equals(id)))
        .get();
    final doc = rows.isNotEmpty
        ? DayPlanTaskDocument.fromDrift(entry: rows.first, clock: clock)
        : DayPlanTaskDocument.fromState(id: id, clock: clock, state: {});
    _applyState(doc, state);
    await db.into(db.dayPlanTasks).insertOnConflictUpdate(doc.toDriftCompanion());
  }

  void _applyState(CrdtDocument doc, Map<String, CrdtFieldState> state) {
    for (final entry in state.entries) {
      doc.mergeField(
        entry.key,
        value: entry.value.value,
        timestamp: entry.value.timestamp,
      );
    }
  }

  // ============================================================
  // Watermark helpers
  // ============================================================

  Future<String> _getDesktopWatermark() async {
    final rows = await (db.select(db.syncWatermarks)
          ..where((w) => w.nodeId.equals(_kDesktopNodeId)))
        .get();
    final match = rows.where((r) => r.direction == 'received');
    if (match.isEmpty) return '0';
    final hlc = match.first.lastHlc;
    return hlc.isEmpty ? '0' : hlc;
  }

  Future<void> _setDesktopWatermark(String hlcPacked) async {
    await db.into(db.syncWatermarks).insertOnConflictUpdate(
          SyncWatermarksCompanion.insert(
            nodeId: _kDesktopNodeId,
            lastHlc: Value(hlcPacked),
            direction: Value('received'),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  void dispose() {
    _client.close();
  }
}
