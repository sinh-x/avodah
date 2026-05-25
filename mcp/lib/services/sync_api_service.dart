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
import 'dart:typed_data';

import 'package:avodah_core/avodah_core.dart';
import 'package:drift/drift.dart' show Value;

import 'package:http/http.dart' as http;

import '../config/avo_config.dart';
import '../config/paths.dart';
import 'jira_service.dart';
import 'pairing_service.dart';

/// Document type identifiers used in sync delta payloads.
class SyncDocType {
  SyncDocType._();

  static const String task = 'task';
  static const String worklog = 'worklog';
  static const String timer = 'timer';
  static const String project = 'project';
  static const String dailyPlan = 'dailyPlan';
  static const String dayPlanTask = 'dayPlanTask';
  static const String categoryChip = 'categoryChip';
}

/// Handles CRDT delta sync HTTP requests.
class SyncApiService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  /// Called after phone deltas are successfully merged into the local DB.
  ///
  /// The integer argument is the number of deltas merged. The server wires
  /// this to an immediate WS snapshot broadcast so connected clients see
  /// phone changes without waiting for the next periodic tick.
  final void Function(int count)? onDeltasMerged;

  /// Optional Jira service — if provided, triggers push after merging phone deltas.
  final JiraService? jiraService;

  /// User config for categories, etc.
  AvoConfig? config;

  /// Paths for config storage (injected to avoid read-only default path on NixOS).
  final AvodahPaths? paths;

  /// Optional pairing service for device authentication.
  final PairingService? pairingService;

  SyncApiService({
    required this.db,
    required this.clock,
    this.onDeltasMerged,
    this.jiraService,
    this.config,
    this.paths,
    this.pairingService,
  });

  /// Pulls CRDT deltas from all paired phone devices on startup.
  ///
  /// For each paired device with a `phone`-prefixed node ID, this method:
  /// 1. Looks up the stored watermark (last received HLC from that device).
  /// 2. Constructs a sync auth token from the pairing key.
  /// 3. Calls `GET /api/sync/deltas?since=<watermark>` on the phone with a
  ///    5-second timeout.
  /// 4. Merges returned deltas into the local DB via [mergePushBatch].
  ///
  /// If a phone is unreachable, a warning is logged and the loop continues.
  Future<void> pullFromPhone() async {
    if (pairingService == null) return;

    final devices = await pairingService!.listPairedDevices();

    for (final device in devices) {
      if (!device.id.startsWith('phone')) continue;

      final pairingKey = device.privateKey;
      if (pairingKey == null) {
        stderr.writeln(
            'Sync: skipping phone ${device.id} — no pairing key stored');
        continue;
      }

      final origin = device.origin;
      if (origin == null || origin.isEmpty) {
        stderr.writeln(
            'Sync: skipping phone ${device.id} — no origin stored');
        continue;
      }

      final token =
          await generateSyncVerifyCode(Uint8List.fromList(pairingKey));

      // Determine the phone API URL from the stored origin
      final phoneUrl = '$origin/api/sync/deltas';

      // Get stored watermark for this phone node (what we've received so far)
      final since = await getWatermark(device.id);

      try {
        final uri = Uri.parse(phoneUrl).replace(
          queryParameters: {'since': since},
        );

        final client = http.Client();
        try {
          final response = await client
              .get(
                uri,
                headers: {
                  'X-Av-Node-Id': clock.nodeId,
                  'X-Av-Pair-Token': token,
                  'Content-Type': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final body =
                jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true))
                    as Map<String, dynamic>;
            final deltasJson = (body['deltas'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();

            if (deltasJson.isNotEmpty) {
              final result = await mergePushBatch(
                remoteNode: device.id,
                deltas: deltasJson,
              );
              stderr.writeln(
                  'Sync: pulled ${deltasJson.length} deltas from ${device.id} '
                  '(merged ${result.merged}, errors ${result.errors.length})');
            } else {
              stderr.writeln(
                  'Sync: pulled 0 deltas from ${device.id} (up to date)');
            }
          } else {
            stderr.writeln(
                'Sync: phone ${device.id} returned ${response.statusCode}');
          }
        } finally {
          client.close();
        }
      } catch (e) {
        stderr.writeln(
            'Sync: WARNING — could not reach phone ${device.id} at $origin ($e). Continuing.');
      }
    }
  }

  /// Routes a sync API request. Returns true if handled.
  Future<bool> handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    if (path != '/api/sync/deltas' &&
        path != '/api/config/categories' &&
        path != '/api/config/category-chips') {
      return false;
    }

    // Set CORS headers (restricted to paired origin after pairing is established)
    await _setCorsHeaders(request);

    if (method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      return true;
    }

    // Auth check for /api/sync/deltas — requires valid X-Av-Pair-Token
    if (path == '/api/sync/deltas') {
      final nodeId = request.headers.value('X-Av-Node-Id');
      final token = request.headers.value('X-Av-Pair-Token');

      if (nodeId == null || token == null) {
        _jsonResponse(request, HttpStatus.forbidden,
            {'error': 'Missing X-Av-Node-Id or X-Av-Pair-Token header'});
        return true;
      }

      if (pairingService == null) {
        _jsonResponse(request, HttpStatus.internalServerError,
            {'error': 'Pairing service not configured'});
        return true;
      }

      final isValid = await pairingService!.verifyPairToken(nodeId, token);
      if (!isValid) {
        _jsonResponse(request, HttpStatus.forbidden,
            {'error': 'Invalid or expired pairing token'});
        return true;
      }

      // Update lastSeen for the paired device
      await _updateLastSeen(nodeId);
    }

    try {
      if (path == '/api/config/categories') {
        if (method == 'GET') {
          await _handleGetCategories(request);
        } else {
          _jsonResponse(request, HttpStatus.methodNotAllowed,
              {'error': 'Method not allowed'});
        }
      } else if (path == '/api/config/category-chips') {
        if (method == 'GET') {
          await _handleGetCategoryChips(request);
        } else if (method == 'POST') {
          await _handleUpdateCategoryChip(request);
        } else if (method == 'DELETE') {
          await _handleDeleteCategoryChip(request);
        } else {
          _jsonResponse(request, HttpStatus.methodNotAllowed,
              {'error': 'Method not allowed'});
        }
      } else if (method == 'GET') {
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
    // Read raw bytes first, then decode with allowMalformed to handle
    // any non-UTF-8 data in CRDT field values from the phone.
    final bytes = await request.fold<List<int>>([], (a, b) => a..addAll(b));
    final body = utf8.decode(bytes, allowMalformed: true);
    final json = jsonDecode(body) as Map<String, dynamic>;

    final remoteNode = json['node'] as String?;
    final deltasJson =
        (json['deltas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    if (remoteNode == null || remoteNode.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Missing "node" field'});
      return;
    }

    final result =
        await mergePushBatch(remoteNode: remoteNode, deltas: deltasJson);

    _jsonResponse(request, HttpStatus.ok, {
      'merged': result.merged,
      'errors': result.errors,
      'watermark': result.watermark,
      'nodeId': clock.nodeId,
    });
  }

  /// GET /api/config/categories
  ///
  /// Returns the merged and sorted list of categories from AvoConfig
  /// (user-configured or defaults) plus any distinct category values
  /// found on existing tasks in the DB.
  Future<void> _handleGetCategories(HttpRequest request) async {
    final configCategories =
        (config?.effectiveCategories ?? AvoConfig.defaultCategories).toSet();

    final tasks = await db.select(db.tasks).get();
    final dbCategories = tasks
        .map((t) => t.category)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet();

    final allCategories = {...configCategories, ...dbCategories}.toList()
      ..sort();

    _jsonResponse(request, HttpStatus.ok, {'categories': allCategories});
  }

  /// GET /api/config/category-chips?category=Working
  ///
  /// Returns the list of chip presets for the specified category.
  /// If no category is specified, returns all category chips as a map.
  /// Falls back to config.categoryChips when the database is empty.
  Future<void> _handleGetCategoryChips(HttpRequest request) async {
    final category = request.uri.queryParameters['category'];

    // Read from CRDT-backed table
    final allChips = await db.select(db.categoryChips).get();

    // Build model list, filtering soft-deleted chips
    final chipModels = <CategoryChipModel>[];
    for (final row in allChips) {
      final doc = CategoryChipDocument.fromDrift(chip: row, clock: clock);
      if (!doc.isDeleted) {
        chipModels.add(doc.toModel());
      }
    }

    // Fall back to config.categoryChips when DB is empty
    if (chipModels.isEmpty &&
        config != null &&
        config!.categoryChips.isNotEmpty) {
      final configChips = config!.categoryChips;
      if (category != null) {
        final chips = configChips[category] ?? [];
        _jsonResponse(request, HttpStatus.ok, {
          'category': category,
          'chips': chips,
        });
      } else {
        _jsonResponse(request, HttpStatus.ok, {'categoryChips': configChips});
      }
      return;
    }

    if (category != null) {
      // Return chips for specific category
      final categoryChipList = chipModels
          .where((c) => c.category == category)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _jsonResponse(request, HttpStatus.ok, {
        'category': category,
        'chips': categoryChipList.map((c) => c.label).toList(),
      });
    } else {
      // Return all chips as a map grouped by category
      final chipsMap = <String, List<String>>{};
      for (final chip in chipModels) {
        final cat = chip.category ?? '';
        chipsMap.putIfAbsent(cat, () => []).add(chip.label!);
      }
      // Sort each category's chips by sortOrder
      for (final key in chipsMap.keys) {
        final sorted = chipModels.where((c) => c.category == key).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        chipsMap[key] = sorted.map((c) => c.label!).toList();
      }
      _jsonResponse(request, HttpStatus.ok, {'categoryChips': chipsMap});
    }
  }

  /// POST /api/config/category-chips
  ///
  /// Adds or removes a chip preset for a category.
  /// Body: {"action": "add"|"remove", "category": "Working", "chip": "standup"}
  Future<void> _handleUpdateCategoryChip(HttpRequest request) async {
    // Check if config is available first
    if (config == null) {
      _jsonResponse(request, HttpStatus.serviceUnavailable,
          {'error': 'Service unavailable: no config'});
      return;
    }

    final body = await utf8.decoder.bind(request).join();
    if (body.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Request body is empty'});
      return;
    }
    final json = jsonDecode(body) as Map<String, dynamic>;

    final action = json['action'] as String?;
    final category = json['category'] as String?;
    final chip = json['chip'] as String?;

    if (action == null || category == null || chip == null) {
      _jsonResponse(request, HttpStatus.badRequest,
          {'error': 'Missing required fields: action, category, chip'});
      return;
    }

    if (chip.isEmpty) {
      _jsonResponse(request, HttpStatus.badRequest,
          {'error': 'Chip text cannot be empty'});
      return;
    }

    if (action == 'add') {
      // Find existing chip by category+label to check if it already exists
      final existingChips = await db.select(db.categoryChips).get();
      CategoryChip? existing;
      for (final row in existingChips) {
        final doc = CategoryChipDocument.fromDrift(chip: row, clock: clock);
        if (!doc.isDeleted && doc.category == category && doc.label == chip) {
          existing = row;
          break;
        }
      }

      if (existing != null) {
        _jsonResponse(request, HttpStatus.ok, {
          'success': true,
          'action': 'already_exists',
          'category': category,
          'chip': chip,
        });
      } else {
        // Create new CRDT document and upsert
        final doc = CategoryChipDocument.create(
          clock: clock,
          category: category,
          label: chip,
          sortOrder: 0,
        );
        await db
            .into(db.categoryChips)
            .insertOnConflictUpdate(doc.toDriftCompanion());
        _jsonResponse(request, HttpStatus.ok, {
          'success': true,
          'action': 'added',
          'category': category,
          'chip': chip,
        });
      }
    } else if (action == 'remove') {
      // Soft-delete via CRDT _deleted field
      final existingChips = await db.select(db.categoryChips).get();
      CategoryChip? existing;
      for (final row in existingChips) {
        final doc = CategoryChipDocument.fromDrift(chip: row, clock: clock);
        if (!doc.isDeleted && doc.category == category && doc.label == chip) {
          existing = row;
          break;
        }
      }

      if (existing != null) {
        final doc =
            CategoryChipDocument.fromDrift(chip: existing, clock: clock);
        doc.delete();
        await db
            .into(db.categoryChips)
            .insertOnConflictUpdate(doc.toDriftCompanion());
      }
      _jsonResponse(request, HttpStatus.ok, {
        'success': true,
        'action': 'removed',
        'category': category,
        'chip': chip,
      });
    } else {
      _jsonResponse(request, HttpStatus.badRequest,
          {'error': 'Invalid action. Use "add" or "remove"'});
    }
  }

  /// DELETE /api/config/category-chips?category=Working&chip=standup
  ///
  /// Removes a chip preset from a category (soft-delete via CRDT _deleted field).
  Future<void> _handleDeleteCategoryChip(HttpRequest request) async {
    final category = request.uri.queryParameters['category'];
    final chip = request.uri.queryParameters['chip'];

    if (category == null || chip == null) {
      _jsonResponse(request, HttpStatus.badRequest,
          {'error': 'Missing required query parameters: category, chip'});
      return;
    }

    // Find and soft-delete via CRDT _deleted field
    final existingChips = await db.select(db.categoryChips).get();
    for (final row in existingChips) {
      final doc = CategoryChipDocument.fromDrift(chip: row, clock: clock);
      if (!doc.isDeleted && doc.category == category && doc.label == chip) {
        doc.delete();
        await db
            .into(db.categoryChips)
            .insertOnConflictUpdate(doc.toDriftCompanion());
        break;
      }
    }

    _jsonResponse(request, HttpStatus.ok, {
      'success': true,
      'category': category,
      'chip': chip,
    });
  }

  /// Merges a batch of incoming CRDT deltas from [remoteNode] into the local DB.
  ///
  /// Records the received watermark and fires [onDeltasMerged] when at least
  /// one delta was applied. Exposed for direct testing without an HTTP layer.
  Future<({int merged, List<String> errors, String watermark})> mergePushBatch({
    required String remoteNode,
    required List<Map<String, dynamic>> deltas,
  }) async {
    var merged = 0;
    final errors = <String>[];

    for (final delta in deltas) {
      try {
        await mergeDelta(delta);
        merged++;
      } catch (e) {
        errors.add('${delta['type']}/${delta['id']}: $e');
      }
    }

    final watermark = clock.now().pack();

    // Record the watermark of what we received from the remote node
    // and propagate merged deltas to connected clients immediately.
    if (merged > 0) {
      await setWatermark(remoteNode, watermark, direction: 'received');
      onDeltasMerged?.call(merged);
      // Trigger Jira push for any newly merged worklogs (fire-and-forget).
      jiraService?.push().then(
            (_) {},
            onError: (Object e) =>
                stderr.writeln('Jira push after phone sync failed: $e'),
          );
    }

    return (merged: merged, errors: errors, watermark: watermark);
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

    // Category Chips
    final categoryChips = await db.select(db.categoryChips).get();
    for (final row in categoryChips) {
      if (_isAfterWatermark(row.crdtClock, since)) {
        final doc = CategoryChipDocument.fromDrift(chip: row, clock: clock);
        deltas.add(_wrapDelta(SyncDocType.categoryChip, doc));
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
      case SyncDocType.categoryChip:
        await _mergeCategoryChip(id, state);
      default:
        throw ArgumentError('Unknown delta type: $type');
    }
  }

  Future<void> _mergeTask(String id, Map<String, CrdtFieldState> state) async {
    final rows =
        await (db.select(db.tasks)..where((t) => t.id.equals(id))).get();

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

  Future<void> _mergeTimer(String id, Map<String, CrdtFieldState> state) async {
    final rows =
        await (db.select(db.timerEntries)..where((t) => t.id.equals(id))).get();

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
    final rows =
        await (db.select(db.projects)..where((t) => t.id.equals(id))).get();

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
    final rows =
        await (db.select(db.dayPlanTasks)..where((t) => t.id.equals(id))).get();

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

  Future<void> _mergeCategoryChip(
      String id, Map<String, CrdtFieldState> state) async {
    final rows = await (db.select(db.categoryChips)
          ..where((t) => t.id.equals(id)))
        .get();

    final CategoryChipDocument doc;
    if (rows.isNotEmpty) {
      doc = CategoryChipDocument.fromDrift(chip: rows.first, clock: clock);
    } else {
      doc = CategoryChipDocument.fromState(id: id, clock: clock, state: {});
    }

    _applyState(doc, state);
    await db
        .into(db.categoryChips)
        .insertOnConflictUpdate(doc.toDriftCompanion());
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// Applies CRDT field state to a document using per-field merge.
  void _applyState(CrdtDocument doc, Map<String, CrdtFieldState> state) {
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

  /// Returns comprehensive sync diagnostics for CLI status display.
  ///
  /// Returns:
  /// - phoneWatermark: the last HLC watermark received from any phone node
  /// - lastPhoneSync: epoch millis of last phone sync
  /// - deltaCounts: per-document-type local document counts, not pending deltas
  Future<Map<String, dynamic>> syncDiagnostics() async {
    final allWatermarks = await getAllWatermarks();
    int? lastPhoneSync;
    String phoneWatermark = '0';
    for (final w in allWatermarks) {
      final nodeId = w['nodeId'] as String? ?? '';
      if (nodeId.startsWith('phone') && w['direction'] == 'received') {
        final ts = w['updatedAt'] as int?;
        if (ts != null && (lastPhoneSync == null || ts > lastPhoneSync)) {
          lastPhoneSync = ts;
          phoneWatermark = (w['lastHlc'] as String?) ?? '0';
        }
      }
    }

    // Count local documents per type. This is a diagnostic inventory, not a
    // pending-sync count; phone pull watermarks are stored on the phone.
    final zeroWatermark =
        HybridTimestamp(physicalTime: 0, counter: 0, nodeId: '');
    final counts = <String, int>{
      'dailyPlan': 0,
      'dayPlanTask': 0,
      'task': 0,
      'worklog': 0,
      'timer': 0,
      'project': 0,
    };

    // Tasks
    final tasks = await db.select(db.tasks).get();
    counts['task'] = tasks
        .where((r) => _isAfterWatermark(r.crdtClock, zeroWatermark))
        .length;

    // Worklogs
    final worklogs = await db.select(db.worklogEntries).get();
    counts['worklog'] = worklogs
        .where((r) => _isAfterWatermark(r.crdtClock, zeroWatermark))
        .length;

    // Timers
    final timers = await db.select(db.timerEntries).get();
    counts['timer'] = timers
        .where((r) => _isAfterWatermark(r.crdtClock, zeroWatermark))
        .length;

    // Projects
    final projects = await db.select(db.projects).get();
    counts['project'] = projects
        .where((r) => _isAfterWatermark(r.crdtClock, zeroWatermark))
        .length;

    // Daily plans
    final dailyPlans = await db.select(db.dailyPlanEntries).get();
    counts['dailyPlan'] = dailyPlans
        .where((r) => _isAfterWatermark(r.crdtClock, zeroWatermark))
        .length;

    // Day plan tasks
    final dayPlanTasks = await db.select(db.dayPlanTasks).get();
    counts['dayPlanTask'] = dayPlanTasks
        .where((r) => _isAfterWatermark(r.crdtClock, zeroWatermark))
        .length;

    return {
      'phoneWatermark': phoneWatermark,
      'lastPhoneSync': lastPhoneSync,
      'deltaCounts': counts,
    };
  }

  /// Sends a JSON response.
  void _jsonResponse(
      HttpRequest request, int statusCode, Map<String, dynamic> body) {
    try {
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(body));
      request.response.close(); // Separate call so errors can be caught
    } catch (e) {
      stderr.writeln('Response write error (client likely disconnected): $e');
    }
  }

  // ============================================================
  // Auth & CORS helpers
  // ============================================================

  /// Sets CORS headers for sync endpoints.
  ///
  /// After pairing is established, CORS is restricted to the paired device's origin.
  /// Before pairing, a permissive CORS is set for the pairing endpoints.
  ///
  /// Returns the paired device's origin if known, otherwise null.
  Future<String?> _setCorsHeaders(HttpRequest request) async {
    final origin = request.headers.value('origin');

    // If pairing service is available, check if we have a paired device
    String? allowedOrigin;
    if (pairingService != null && origin != null) {
      // Try to look up the paired device by nodeId (from X-Av-Node-Id header)
      final nodeId = request.headers.value('X-Av-Node-Id');
      if (nodeId != null) {
        final device = await pairingService!.getPairedDevice(nodeId);
        if (device != null && device.origin != null) {
          // If origin matches the stored origin (or is a sub-origin of it), allow it
          if (origin == device.origin ||
              origin.startsWith(
                  device.origin!.replaceFirst(RegExp(r'^https?://'), ''))) {
            allowedOrigin = origin;
          }
        }
      }
    }

    // Default: allow the origin header value for pairing endpoints
    // (After pairing, the phone sends the same origin it used during pairing)
    allowedOrigin ??= origin ?? '*';

    request.response.headers.add('Access-Control-Allow-Origin',
        allowedOrigin == '*' ? '*' : allowedOrigin);
    request.response.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers',
        'Content-Type, X-Av-Pair-Token, X-Av-Node-Id');

    return allowedOrigin == '*' ? null : allowedOrigin;
  }

  /// Updates the lastSeen timestamp for a paired device.
  Future<void> _updateLastSeen(String nodeId) async {
    await (db.update(db.pairedDevices)..where((d) => d.id.equals(nodeId)))
        .write(PairedDevicesCompanion(
      lastSeen: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
}
