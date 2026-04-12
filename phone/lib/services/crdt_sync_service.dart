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
///
/// ## Pairing Integration (AVO-065 Phase 4)
///
/// Uses [CryptoSyncService] for TLS 1.2+ transport with certificate
/// verification and [PhonePairingService] for pairing flow. On sync error
/// 403 or when server reports needsPairing:true, the [onNeedsPairing]
/// callback is invoked to trigger the pairing UI.
library;

import 'dart:convert';

import 'package:avodah_core/avodah_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'crypto_sync_service.dart';
import 'pairing_service.dart';

const _kDesktopNodeId = 'desktop';
const _kPhoneNodeIdKey = 'crdt_node_id';

/// Connection state for the sync indicator.
enum SyncConnectionState { disconnected, connecting, connected }

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

/// Callback type invoked when the server indicates pairing is required.
typedef OnNeedsPairingCallback = Future<void> Function();

/// Sync service that pulls CRDT deltas from the desktop via HTTP.
///
/// Uses [cryptoClient] for TLS + auth transport when provided.
/// Falls back to plain [http.Client] if not supplied (for non-TLS connections).
///
/// Triggers [onNeedsPairing] when:
/// - Sync returns HTTP 403 (unpaired or invalid token)
/// - GET /api/sync/status returns needsPairing:true
class CrdtSyncService {
  final String baseUrl;
  final AppDatabase db;
  final HybridLogicalClock clock;
  final http.Client _plainClient;
  final CryptoSyncService? _cryptoClient;

  /// Phone-side pairing service (initialized after pairing).
  PhonePairingService? get pairingService => _pairingService;
  PhonePairingService? _pairingService;

  /// Called when the server reports needsPairing:true or returns HTTP 403.
  final OnNeedsPairingCallback? onNeedsPairing;

  CrdtSyncService({
    required this.baseUrl,
    required this.db,
    required this.clock,
    http.Client? client,
    CryptoSyncService? cryptoClient,
    this.onNeedsPairing,
    required String nodeId,
  })  : _plainClient = client ?? http.Client(),
        _cryptoClient = cryptoClient {
    if (_cryptoClient != null) {
      _pairingService = PhonePairingService(
        cryptoClient: _cryptoClient,
        nodeId: nodeId,
      );
    }
  }

  /// Loads persisted pairing state from secure storage.
  Future<void> loadPersistedState() async {
    await _cryptoClient?.loadPersistedState();
    await _pairingService?.loadPersistedState();
  }

  /// Returns true if a pairing token is stored.
  bool get isPaired => _cryptoClient?.isPaired ?? false;

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
  /// Triggers [onNeedsPairing] if the server returns HTTP 403 or reports
  /// needsPairing:true.
  Future<int> pullFromDesktop() async {
    // Only check server pairing status if we DON'T have a local token.
    // If we do have a token, skip the network call and let the actual
    // /api/sync/deltas 403 response be the authoritative signal.
    if (_cryptoClient != null && !isPaired) {
      final status = await _pairingService?.checkPairingStatus();
      if (status != null && status.needsPairing) {
        debugPrint('[CrdtSync] Server needs pairing — triggering pairing flow');
        await onNeedsPairing?.call();
        throw Exception('Pairing required');
      }
    }

    final watermark = await _getDesktopWatermark();
    final nodeId = await getOrCreateNodeId();

    debugPrint('[Sync] Pulling deltas since watermark=$watermark');

    final http.Response response;
    if (_cryptoClient != null) {
      // Use TLS client — auth headers applied automatically
      final httpResponse = await _cryptoClient.get(
        'api/sync/deltas',
        queryParams: {
          'since': watermark,
          'node': nodeId,
        },
      );
      final body = await httpResponse.transform(utf8.decoder).join();
      response = http.Response(body, httpResponse.statusCode);
    } else {
      final uri = Uri.parse(
        '$baseUrl/api/sync/deltas?since=${Uri.encodeComponent(watermark)}&node=${Uri.encodeComponent(nodeId)}',
      );
      response = await _plainClient.get(uri).timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 403) {
      debugPrint('[CrdtSync] HTTP 403 — triggering pairing flow');
      await onNeedsPairing?.call();
      throw Exception('Pairing required (HTTP 403)');
    }

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

    // Count merged deltas by type for diagnostic logging
    var dailyPlanCount = 0;
    var dayPlanTaskCount = 0;
    var taskCount = 0;
    var worklogCount = 0;
    var timerCount = 0;
    var projectCount = 0;
    for (final deltaJson in deltas) {
      final delta = deltaJson as Map<String, dynamic>;
      switch (delta['type'] as String) {
        case _SyncDocType.dailyPlan:
          dailyPlanCount++;
          break;
        case _SyncDocType.dayPlanTask:
          dayPlanTaskCount++;
          break;
        case _SyncDocType.task:
          taskCount++;
          break;
        case _SyncDocType.worklog:
          worklogCount++;
          break;
        case _SyncDocType.timer:
          timerCount++;
          break;
        case _SyncDocType.project:
          projectCount++;
          break;
        default:
          break;
      }
    }

    debugPrint('[Sync] Pulled $merged deltas '
        '(dailyPlan=$dailyPlanCount, dayPlanTask=$dayPlanTaskCount, '
        'task=$taskCount, worklog=$worklogCount, timer=$timerCount, project=$projectCount)');
    debugPrint('[Sync] Merged $merged deltas into local DB. New watermark=$newWatermark');
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

  /// Push CRDT deltas from phone to desktop.
  ///
  /// Protocol: POST /api/sync/deltas
  /// Body: `{"node": "<node-id>", "deltas": [...]}`
  /// Returns the number of deltas merged by the desktop, or throws on HTTP error.
  /// Triggers [onNeedsPairing] on HTTP 403.
  Future<int> pushToDesktop(List<Map<String, dynamic>> deltas) async {
    if (deltas.isEmpty) return 0;

    final nodeId = await getOrCreateNodeId();
    final body = jsonEncode({'node': nodeId, 'deltas': deltas});

    debugPrint('[Sync] Pushing ${deltas.length} deltas');

    final http.Response response;
    if (_cryptoClient != null) {
      final httpResponse = await _cryptoClient.post(
        'api/sync/deltas',
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      response = http.Response(responseBody, httpResponse.statusCode);
    } else {
      final uri = Uri.parse('$baseUrl/api/sync/deltas');
      response = await _plainClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 403) {
      debugPrint('[CrdtSync] HTTP 403 — triggering pairing flow');
      await onNeedsPairing?.call();
      throw Exception('Pairing required (HTTP 403)');
    }

    if (response.statusCode != 200) {
      throw Exception('Sync push failed: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final merged = (json['merged'] as num?)?.toInt() ?? 0;
    final watermark = json['watermark'] as String?;

    // Advance our clock to the desktop's post-merge watermark
    if (watermark != null && watermark != '0') {
      try {
        clock.receive(HybridTimestamp.parse(watermark));
      } catch (_) {}
    }

    debugPrint('[Sync] Push completed, server processed $merged deltas');
    return merged;
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

  /// Force a full bidirectional sync: reset watermark, pull everything from
  /// desktop, then push all local documents.
  ///
  /// Returns the total number of deltas pushed to the desktop.
  Future<int> forceFullSync() async {
    // Reset watermark so the next pull fetches all deltas
    await _setDesktopWatermark('0');

    // Pull all from desktop
    await pullFromDesktop();

    // Collect all local documents as deltas
    final deltas = <Map<String, dynamic>>[];

    final tasks = await db.select(db.tasks).get();
    for (final t in tasks) {
      final doc = TaskDocument.fromDrift(task: t, clock: clock);
      final json = doc.toJson();
      json['type'] = _SyncDocType.task;
      deltas.add(json);
    }

    final worklogs = await db.select(db.worklogEntries).get();
    for (final w in worklogs) {
      final doc = WorklogDocument.fromDrift(worklog: w, clock: clock);
      final json = doc.toJson();
      json['type'] = _SyncDocType.worklog;
      deltas.add(json);
    }

    final timers = await db.select(db.timerEntries).get();
    for (final t in timers) {
      final doc = TimerDocument.fromDrift(timer: t, clock: clock);
      final json = doc.toJson();
      json['type'] = _SyncDocType.timer;
      deltas.add(json);
    }

    final projects = await db.select(db.projects).get();
    for (final p in projects) {
      final doc = ProjectDocument.fromDrift(project: p, clock: clock);
      final json = doc.toJson();
      json['type'] = _SyncDocType.project;
      deltas.add(json);
    }

    final dailyPlans = await db.select(db.dailyPlanEntries).get();
    for (final d in dailyPlans) {
      final doc = DailyPlanDocument.fromDrift(entry: d, clock: clock);
      final json = doc.toJson();
      json['type'] = _SyncDocType.dailyPlan;
      deltas.add(json);
    }

    final dayPlanTasks = await db.select(db.dayPlanTasks).get();
    for (final d in dayPlanTasks) {
      final doc = DayPlanTaskDocument.fromDrift(entry: d, clock: clock);
      final json = doc.toJson();
      json['type'] = _SyncDocType.dayPlanTask;
      deltas.add(json);
    }

    debugPrint('[Sync] Force full sync: pushing ${deltas.length} local deltas');
    return pushToDesktop(deltas);
  }

  /// Revokes pairing with the desktop server.
  ///
  /// Calls DELETE /api/sync/pair to notify the server, then clears local
  /// pairing state. After revocation, the next sync attempt will trigger
  /// the pairing flow again.
  ///
  /// Does nothing if not currently paired.
  Future<void> revokePairing() async {
    await _pairingService?.revokePairing();
    debugPrint('[CrdtSync] Pairing revoked. Service reset to unpaired state.');
  }

  void dispose() {
    _plainClient.close();
    _cryptoClient?.dispose();
  }
}
