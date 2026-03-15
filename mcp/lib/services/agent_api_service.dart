/// HTTP API service for agent workflow operations.
///
/// Provides endpoints for reviewing inbox items, viewing deployment status,
/// and browsing agent team folders. All file access is sandboxed to
/// `~/Documents/ai-usage/`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'markdown_parser.dart';
import 'registry_parser.dart';

/// Handles HTTP requests for the agent workflow API.
class AgentApiService {
  /// Base path for all ai-usage data. All file access is sandboxed here.
  final String aiUsagePath;

  /// Path to the registry JSONL file.
  final String registryPath;

  /// PA home directory (PA_HOME env var) — contains teams/, skills/, etc.
  final String paHome;

  /// PA config override directory (PA_CONFIG env var) — user-overridden teams.
  final String? paConfigDir;

  /// Path to the `pa` binary.
  final String paBinPath;

  AgentApiService({
    String? aiUsagePath,
    String? registryPath,
    String? paHome,
    String? paConfigDir,
    String? paBinPath,
  })  : aiUsagePath = aiUsagePath ??
            p.join(Platform.environment['HOME'] ?? '/home', 'Documents',
                'ai-usage'),
        registryPath = registryPath ??
            p.join(
                Platform.environment['HOME'] ?? '/home',
                'Documents',
                'ai-usage',
                'deployments',
                'registry.jsonl'),
        paHome = paHome ??
            Platform.environment['PA_HOME'] ??
            p.join(Platform.environment['HOME'] ?? '/home', 'git-repos',
                'sinh-x', 'tools', 'personal-assistant'),
        paConfigDir = paConfigDir ?? Platform.environment['PA_CONFIG'],
        paBinPath = paBinPath ?? Platform.environment['PA_BIN'] ?? 'pa';

  String get _inboxPath => p.join(aiUsagePath, 'sinh-inputs', 'inbox');
  String get _approvedPath => p.join(aiUsagePath, 'sinh-inputs', 'approved');
  String get _rejectedPath => p.join(aiUsagePath, 'sinh-inputs', 'rejected');
  String get _deferredPath => p.join(aiUsagePath, 'sinh-inputs', 'deferred');
  String get _forLaterPath => p.join(aiUsagePath, 'sinh-inputs', 'for-later');
  String get _donePath => p.join(aiUsagePath, 'sinh-inputs', 'done');
  String get _chipConfigPath => p.join(aiUsagePath, 'feedback-chips.yaml');
  String get _teamsPath => p.join(aiUsagePath, 'agent-teams');

  /// Route an HTTP request to the appropriate handler.
  ///
  /// Returns true if the request was handled, false if not an API route.
  Future<bool> handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    // CORS headers for development
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

    if (!path.startsWith('/api/')) return false;

    try {
      // Route matching
      if (path.startsWith('/api/sinh-inputs')) {
        await _handleSinhInputsRoute(request);
      } else if (path == '/api/inbox' && method == 'GET') {
        await _handleListInbox(request);
      } else if (path.startsWith('/api/inbox/') &&
          path.endsWith('/feedback') &&
          method == 'GET') {
        await _handleGetFeedback(request);
      } else if (path.startsWith('/api/inbox/') && method == 'GET') {
        await _handleGetInboxItem(request);
      } else if (path.endsWith('/approve') && method == 'POST') {
        await _handleApprove(request);
      } else if (path.endsWith('/reject') && method == 'POST') {
        await _handleReject(request);
      } else if (path.endsWith('/defer') && method == 'POST') {
        await _handleDefer(request);
      } else if (path.endsWith('/save-for-later') && method == 'POST') {
        await _handleSaveForLater(request);
      } else if (path.endsWith('/acknowledge') && method == 'POST') {
        await _handleAcknowledge(request);
      } else if (path.endsWith('/append-section') && method == 'POST') {
        await _handleAppendSection(request);
      } else if (path == '/api/for-later' && method == 'GET') {
        await _handleListForLater(request);
      } else if (path.startsWith('/api/for-later/') && method == 'GET') {
        await _handleGetForLaterItem(request);
      } else if (path == '/api/config/feedback-chips' && method == 'GET') {
        await _handleGetFeedbackChips(request);
      } else if (path == '/api/deployments' && method == 'GET') {
        await _handleListDeployments(request);
      } else if (path == '/api/teams' && method == 'GET') {
        await _handleListTeams(request);
      } else if (path.startsWith('/api/teams/') && method == 'GET') {
        await _handleTeamBrowse(request);
      } else if (path == '/api/pa-teams' && method == 'GET') {
        await _handleListPaTeams(request);
      } else if (path == '/api/deploy' && method == 'POST') {
        await _handleDeploy(request);
      } else if (path == '/api/timers' && method == 'GET') {
        await _handleListTimers(request);
      } else {
        _jsonResponse(request, HttpStatus.notFound, {'error': 'Not found'});
      }
    } catch (e, stack) {
      stderr.writeln('API error: $e\n$stack');
      _jsonResponse(
          request, HttpStatus.internalServerError, {'error': e.toString()});
    }

    return true;
  }

  /// GET /api/inbox — List inbox items with parsed metadata.
  ///
  /// Each item includes a canonical `type` field (work-report, review-request,
  /// plan-draft, fyi, decision-needed) computed via type detection algorithm.
  /// Response also includes `count_by_type` breakdown.
  Future<void> _handleListInbox(HttpRequest request) async {
    final dir = Directory(_inboxPath);
    if (!dir.existsSync()) {
      _jsonResponse(
          request, HttpStatus.ok, {'items': [], 'count_by_type': {}});
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      try {
        final filename = p.basename(entity.path);
        final content = entity.readAsStringSync();
        final metadata = parseMarkdownMetadata(content, filename: filename);
        final docType = detectDocumentType(content, filename);
        final stat = entity.statSync();
        items.add({
          'id': filename,
          ...metadata.toJson(),
          'type': docType, // canonical type overwrites raw metadata.type
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        });
      } catch (e) {
        stderr.writeln('Skipping malformed inbox file ${entity.path}: $e');
      }
    }

    // Sort by date descending (newest first)
    items.sort((a, b) {
      final aDate = a['date'] as String? ?? '';
      final bDate = b['date'] as String? ?? '';
      return bDate.compareTo(aDate);
    });

    // Count items by type
    final countByType = <String, int>{};
    for (final item in items) {
      final t = item['type'] as String? ?? 'work-report';
      countByType[t] = (countByType[t] ?? 0) + 1;
    }

    _jsonResponse(request, HttpStatus.ok, {
      'items': items,
      'count_by_type': countByType,
    });
  }

  /// GET /api/inbox/:filename — Read single inbox item content.
  Future<void> _handleGetInboxItem(HttpRequest request) async {
    final filename = _extractFilename(request.uri.path, '/api/inbox/');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final file = File(p.join(_inboxPath, filename));
    if (!file.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    final content = file.readAsStringSync();
    final metadata = parseMarkdownMetadata(content, filename: filename);
    final docType = detectDocumentType(content, filename);

    _jsonResponse(request, HttpStatus.ok, {
      'id': filename,
      ...metadata.toJson(),
      'type': docType,
      'content': content,
    });
  }

  /// GET /api/for-later — List for-later items with parsed metadata.
  Future<void> _handleListForLater(HttpRequest request) async {
    final dir = Directory(_forLaterPath);
    if (!dir.existsSync()) {
      _jsonResponse(request, HttpStatus.ok, {'items': []});
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      try {
        final filename = p.basename(entity.path);
        final content = entity.readAsStringSync();
        final metadata = parseMarkdownMetadata(content, filename: filename);
        final stat = entity.statSync();
        items.add({
          'id': filename,
          ...metadata.toJson(),
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        });
      } catch (e) {
        stderr.writeln('Skipping malformed for-later file ${entity.path}: $e');
      }
    }

    items.sort((a, b) {
      final aDate = a['date'] as String? ?? '';
      final bDate = b['date'] as String? ?? '';
      return bDate.compareTo(aDate);
    });

    _jsonResponse(request, HttpStatus.ok, {'items': items});
  }

  /// GET /api/for-later/:filename — Read single for-later item content.
  Future<void> _handleGetForLaterItem(HttpRequest request) async {
    final filename = _extractFilename(request.uri.path, '/api/for-later/');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final file = File(p.join(_forLaterPath, filename));
    if (!file.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    final content = file.readAsStringSync();
    final metadata = parseMarkdownMetadata(content, filename: filename);

    _jsonResponse(request, HttpStatus.ok, {
      'id': filename,
      ...metadata.toJson(),
      'content': content,
    });
  }

  /// POST /api/inbox/:filename/approve — Write optional feedback annotation and
  /// move file to approved/.
  ///
  /// Body (optional JSON): `{"note": "...", "chips": ["..."]}`
  /// If no note and no chips, the file moves with no annotation (fast-path).
  Future<void> _handleApprove(HttpRequest request) async {
    final filename =
        _extractActionFilename(request.uri.path, '/api/inbox/', '/approve');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(p.join(_inboxPath, filename));
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    // Parse optional feedback body
    String? note;
    List<String> chips = const [];
    try {
      final body = await utf8.decoder.bind(request).join();
      if (body.isNotEmpty) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        note = json['note'] as String?;
        final chipsRaw = json['chips'];
        if (chipsRaw is List) {
          chips = chipsRaw.whereType<String>().toList();
        }
      }
    } catch (e) {
      stderr.writeln('_handleApprove: body parse error: $e');
      // proceed with defaults — optional body fields
    }

    // Write annotation only if note or chips provided (fast-path: no annotation)
    final content = source.readAsStringSync();
    final updated = writeFeedbackAnnotation(
        content, ApproveFeedbackAnnotation(note: note, chips: chips));
    if (updated != content) {
      source.writeAsStringSync(updated);
    }

    _ensureDir(_approvedPath);
    final dest = File(p.join(_approvedPath, filename));
    source.renameSync(dest.path);

    _jsonResponse(
        request, HttpStatus.ok, {'status': 'approved', 'file': filename});
  }

  /// POST /api/inbox/:filename/reject — Write structured feedback annotation and
  /// move to rejected/, or mark as pending-reject-feedback (file stays in inbox).
  ///
  /// Body (JSON):
  /// - Full reject: `{"what_is_wrong": "...", "what_to_fix": "...", "priority": "high|medium|low", "chips": [...]}`
  /// - Pending reject: `{"pending": true}` — file stays in inbox with pending annotation
  Future<void> _handleReject(HttpRequest request) async {
    final filename =
        _extractActionFilename(request.uri.path, '/api/inbox/', '/reject');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(p.join(_inboxPath, filename));
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    // 1. Read body (stream errors → 500)
    String body;
    try {
      body = await utf8.decoder.bind(request).join();
    } catch (e, stack) {
      stderr.writeln('_handleReject: stream read error: $e\n$stack');
      _jsonResponse(request, HttpStatus.internalServerError,
          {'error': 'Failed to read request body'});
      return;
    }

    // 2. Parse body (bad JSON → 400)
    bool pending = false;
    String? whatIsWrong;
    String? whatToFix;
    String priority = 'medium';
    List<String> chips = const [];
    if (body.isNotEmpty) {
      Map<String, dynamic> json;
      try {
        json = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        _jsonResponse(
            request, HttpStatus.badRequest, {'error': 'Invalid JSON body'});
        return;
      }
      pending = json['pending'] == true;
      whatIsWrong = json['what_is_wrong'] as String?;
      whatToFix = json['what_to_fix'] as String?;
      priority = json['priority'] as String? ?? 'medium';
      final chipsRaw = json['chips'];
      if (chipsRaw is List) {
        chips = chipsRaw.whereType<String>().toList();
      }
    }

    // 3. Validate required fields (full reject only — pending skips this)
    if (!pending) {
      if (whatIsWrong == null || whatIsWrong.isEmpty) {
        _jsonResponse(request, HttpStatus.badRequest,
            {'error': 'what_is_wrong is required'});
        return;
      }
      if (whatToFix == null || whatToFix.isEmpty) {
        _jsonResponse(request, HttpStatus.badRequest,
            {'error': 'what_to_fix is required'});
        return;
      }
    }

    final content = source.readAsStringSync();

    if (pending) {
      // Pending-reject: write annotation only, file stays in inbox
      final updated =
          writeFeedbackAnnotation(content, const PendingRejectAnnotation());
      source.writeAsStringSync(updated);
      _jsonResponse(request, HttpStatus.ok, {
        'status': 'pending-reject-feedback',
        'file': filename,
      });
      return;
    }

    // Full reject: write structured annotation and move to rejected/
    final updated = writeFeedbackAnnotation(
        content,
        RejectFeedbackAnnotation(
          whatIsWrong: whatIsWrong!,
          whatToFix: whatToFix!,
          priority: priority,
          chips: chips,
        ));
    source.writeAsStringSync(updated);

    _ensureDir(_rejectedPath);
    final dest = File(p.join(_rejectedPath, filename));
    source.renameSync(dest.path);

    _jsonResponse(
        request, HttpStatus.ok, {'status': 'rejected', 'file': filename});
  }

  /// POST /api/inbox/:filename/defer — Write optional feedback annotation and
  /// move file to deferred/.
  ///
  /// Body (optional JSON): `{"reason": "...", "requeue_after": "YYYY-MM-DD", "chips": [...]}`
  /// If no fields provided, file moves with no annotation (fast-path).
  Future<void> _handleDefer(HttpRequest request) async {
    final filename =
        _extractActionFilename(request.uri.path, '/api/inbox/', '/defer');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(p.join(_inboxPath, filename));
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    // Parse optional feedback body
    String? reason;
    String? requeueAfter;
    List<String> chips = const [];
    try {
      final body = await utf8.decoder.bind(request).join();
      if (body.isNotEmpty) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        reason = json['reason'] as String?;
        requeueAfter = json['requeue_after'] as String?;
        final chipsRaw = json['chips'];
        if (chipsRaw is List) {
          chips = chipsRaw.whereType<String>().toList();
        }
      }
    } catch (e) {
      stderr.writeln('_handleDefer: body parse error: $e');
      // proceed with defaults — optional body fields
    }

    // Write annotation only if reason, date, or chips provided
    final content = source.readAsStringSync();
    final updated = writeFeedbackAnnotation(
        content,
        DeferFeedbackAnnotation(
          reason: reason,
          requeueAfter: requeueAfter,
          chips: chips,
        ));
    if (updated != content) {
      source.writeAsStringSync(updated);
    }

    _ensureDir(_deferredPath);
    final dest = File(p.join(_deferredPath, filename));
    source.renameSync(dest.path);

    _jsonResponse(
        request, HttpStatus.ok, {'status': 'deferred', 'file': filename});
  }

  /// POST /api/inbox/:filename/save-for-later — Write minimal YAML frontmatter
  /// and move file to for-later/.
  ///
  /// No body required. Always writes `human_feedback.action: saved-for-later`.
  Future<void> _handleSaveForLater(HttpRequest request) async {
    final filename = _extractActionFilename(
        request.uri.path, '/api/inbox/', '/save-for-later');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(p.join(_inboxPath, filename));
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    // Always write minimal YAML frontmatter (no ## Human Review section)
    final content = source.readAsStringSync();
    final updated =
        writeFeedbackAnnotation(content, const SaveForLaterAnnotation());
    source.writeAsStringSync(updated);

    _ensureDir(_forLaterPath);
    final dest = File(p.join(_forLaterPath, filename));
    source.renameSync(dest.path);

    _jsonResponse(request, HttpStatus.ok,
        {'status': 'saved-for-later', 'file': filename});
  }

  /// POST /api/inbox/:filename/acknowledge — Acknowledge a work-report or FYI
  /// item and move it to done/.
  ///
  /// Body (optional JSON): `{"note": "..."}`
  /// - No note → clean move to done/ with no annotation (fast-path).
  /// - Note provided → writes `human_feedback.action: acknowledged` + note to
  ///   YAML frontmatter; no `## Human Review` section written.
  Future<void> _handleAcknowledge(HttpRequest request) async {
    final filename = _extractActionFilename(
        request.uri.path, '/api/inbox/', '/acknowledge');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(p.join(_inboxPath, filename));
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    // Parse optional note body
    String? note;
    try {
      final body = await utf8.decoder.bind(request).join();
      if (body.isNotEmpty) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        note = json['note'] as String?;
      }
    } catch (e) {
      stderr.writeln('_handleAcknowledge: body parse error: $e');
      // proceed with defaults — optional body fields
    }

    // Write annotation only if note provided (fast-path: clean move)
    final content = source.readAsStringSync();
    final updated = writeFeedbackAnnotation(
        content, AcknowledgeFeedbackAnnotation(note: note));
    if (updated != content) {
      source.writeAsStringSync(updated);
    }

    _ensureDir(_donePath);
    final dest = File(p.join(_donePath, filename));
    source.renameSync(dest.path);

    _jsonResponse(
        request, HttpStatus.ok, {'status': 'acknowledged', 'file': filename});
  }

  /// POST /api/inbox/:filename/append-section — Append a named section to file.
  ///
  /// Body (JSON): `{"title": "Section Title", "content": "Section content..."}`
  /// File stays in inbox; no action taken.
  Future<void> _handleAppendSection(HttpRequest request) async {
    final filename = _extractActionFilename(
        request.uri.path, '/api/inbox/', '/append-section');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(p.join(_inboxPath, filename));
    await _doAppendSection(request, source, filename);
  }

  /// Core logic to append a named `### Section` to any file.
  ///
  /// Used by both inbox append-section and ideas append-section.
  /// Body (JSON): `{"title": "Section Title", "content": "Section content..."}`
  Future<void> _doAppendSection(
      HttpRequest request, File source, String filename) async {
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    // Parse body: {title, content}
    String? title;
    String? sectionContent;
    try {
      final body = await utf8.decoder.bind(request).join();
      if (body.isNotEmpty) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        title = json['title'] as String?;
        sectionContent = json['content'] as String?;
      }
    } catch (_) {
      // Fall through to validation below
    }

    if (title == null || title.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'title is required'});
      return;
    }

    // Append ### Section to file
    var result = source.readAsStringSync();
    if (!result.endsWith('\n')) result = '$result\n';
    if (!result.endsWith('\n\n')) result = '$result\n';
    result = '$result### $title\n\n${sectionContent ?? ''}\n';
    source.writeAsStringSync(result);

    _jsonResponse(request, HttpStatus.ok, {
      'status': 'section-appended',
      'file': filename,
      'title': title,
    });
  }

  /// GET /api/config/feedback-chips — Return chip labels from feedback-chips.yaml.
  ///
  /// Creates the config file with defaults if missing.
  /// Returns empty list (not crash) if file is malformed.
  Future<void> _handleGetFeedbackChips(HttpRequest request) async {
    final configFile = File(_chipConfigPath);

    final defaultChips = [
      'Needs more detail',
      'Good, follow up on X',
      'Revisit next sprint',
      'Looks good, minor tweaks',
      'Needs full rework',
      'Blocked by dependency',
      'Secretary: create follow-up task',
    ];

    List<String> chips;
    if (!configFile.existsSync()) {
      // Create default config file
      final buf = StringBuffer('chips:\n');
      for (final chip in defaultChips) {
        final escaped = chip.replaceAll('"', '\\"');
        buf.writeln('  - "$escaped"');
      }
      try {
        configFile.writeAsStringSync(buf.toString());
      } catch (e) {
        stderr.writeln('Warning: could not write default chips config: $e');
      }
      chips = defaultChips;
    } else {
      try {
        chips = _parseChipsYaml(configFile.readAsStringSync());
      } catch (e) {
        stderr.writeln('Warning: malformed chips config, using defaults: $e');
        chips = defaultChips;
      }
    }

    _jsonResponse(request, HttpStatus.ok, {'chips': chips});
  }

  /// GET /api/inbox/:filename/feedback — Return existing human_feedback block.
  ///
  /// Used to pre-fill the pending-reject-feedback dialog.
  Future<void> _handleGetFeedback(HttpRequest request) async {
    final filename = _extractActionFilename(
        request.uri.path, '/api/inbox/', '/feedback');
    if (filename == null || !_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final file = File(p.join(_inboxPath, filename));
    if (!file.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    final content = file.readAsStringSync();
    final metadata = parseMarkdownMetadata(content, filename: filename);

    _jsonResponse(request, HttpStatus.ok, {
      'id': filename,
      'human_feedback': metadata.humanFeedback?.toJson(),
    });
  }

  /// GET /api/deployments — List deployments from registry.jsonl.
  Future<void> _handleListDeployments(HttpRequest request) async {
    final events = parseRegistryFile(registryPath);
    final deployments = computeDeploymentStatuses(events);

    _jsonResponse(request, HttpStatus.ok, {
      'deployments': deployments.map((d) => d.toJson()).toList(),
    });
  }

  /// GET /api/teams — List agent teams.
  Future<void> _handleListTeams(HttpRequest request) async {
    final dir = Directory(_teamsPath);
    if (!dir.existsSync()) {
      _jsonResponse(request, HttpStatus.ok, {'teams': []});
      return;
    }

    int _countFiles(Directory d) =>
        d.existsSync() ? d.listSync().whereType<File>().length : 0;

    final teams = <Map<String, dynamic>>[];
    for (final entity in dir.listSync()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      // List available subfolders
      final folders = <String>[];
      for (final sub in entity.listSync()) {
        if (sub is Directory) {
          folders.add(p.basename(sub.path));
        }
      }
      final inboxCount =
          _countFiles(Directory(p.join(entity.path, 'inbox')));
      final ongoingCount =
          _countFiles(Directory(p.join(entity.path, 'ongoing')));
      final wfrCount = _countFiles(
          Directory(p.join(entity.path, 'waiting-for-response')));
      teams.add({
        'name': name,
        'folders': folders,
        'inbox_count': inboxCount,
        'ongoing_count': ongoingCount,
        'wfr_count': wfrCount,
      });
    }

    teams.sort((a, b) =>
        (a['name'] as String).compareTo(b['name'] as String));
    _jsonResponse(request, HttpStatus.ok, {'teams': teams});
  }

  /// GET /api/teams/:name/:folder — List files in a team folder.
  /// GET /api/teams/:name/:folder/:filename — Read file content.
  Future<void> _handleTeamBrowse(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    // /api/teams/:name/:folder[/:filename]
    // segments: [api, teams, name, folder, ?filename]

    if (segments.length < 4) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Missing team or folder'});
      return;
    }

    final teamName = segments[2];
    final folderName = segments[3];

    // Validate path safety
    if (!_isSafeFilename(teamName) || !_isSafeFilename(folderName)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final folderPath = p.join(_teamsPath, teamName, folderName);
    final folderDir = Directory(folderPath);

    // Verify resolved path stays within ai-usage
    if (!_isWithinSandbox(folderDir.path)) {
      _jsonResponse(
          request, HttpStatus.forbidden, {'error': 'Path traversal blocked'});
      return;
    }

    if (!folderDir.existsSync()) {
      _jsonResponse(
          request, HttpStatus.notFound, {'error': 'Folder not found'});
      return;
    }

    // Read specific file
    if (segments.length >= 5) {
      final filename = segments.sublist(4).join('/');
      if (!_isSafeFilename(filename)) {
        _jsonResponse(
            request, HttpStatus.forbidden, {'error': 'Invalid path'});
        return;
      }

      final file = File(p.join(folderPath, filename));
      if (!_isWithinSandbox(file.path) || !file.existsSync()) {
        _jsonResponse(
            request, HttpStatus.notFound, {'error': 'File not found'});
        return;
      }

      final content = file.readAsStringSync();
      final metadata = parseMarkdownMetadata(content, filename: filename);
      _jsonResponse(request, HttpStatus.ok, {
        'id': filename,
        ...metadata.toJson(),
        'content': content,
      });
      return;
    }

    // List files in folder
    final files = <Map<String, dynamic>>[];
    for (final entity in folderDir.listSync()) {
      if (entity is! File) continue;
      final filename = p.basename(entity.path);
      try {
        final stat = entity.statSync();
        files.add({
          'name': filename,
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        });
      } catch (e) {
        stderr.writeln('Error reading file stat $filename: $e');
      }
    }

    files.sort((a, b) {
      final aDate = a['modified'] as String;
      final bDate = b['modified'] as String;
      return bDate.compareTo(aDate);
    });

    _jsonResponse(request, HttpStatus.ok, {
      'team': teamName,
      'folder': folderName,
      'files': files,
    });
  }

  // --- sinh-inputs folder API ---

  /// Route /api/sinh-inputs/:folder[/:filename[/:action]] requests.
  ///
  /// Handles GET (list, read) and POST (requeue, archive, save-for-later,
  /// append-section, create-idea) for all 5 non-inbox sinh-inputs folders:
  /// approved | rejected | deferred | done | ideas
  Future<void> _handleSinhInputsRoute(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    final prefix = '/api/sinh-inputs';
    final afterPrefix =
        path.length > prefix.length ? path.substring(prefix.length) : '';

    if (afterPrefix.isEmpty || afterPrefix == '/') {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Folder required'});
      return;
    }

    // afterPrefix always starts with '/'
    final rest = afterPrefix.substring(1);
    final rawSegments = rest.split('/');

    if (rawSegments.isEmpty || rawSegments[0].isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Folder required'});
      return;
    }

    final folder = Uri.decodeComponent(rawSegments[0]);
    const allowedFolders = {
      'approved',
      'rejected',
      'deferred',
      'done',
      'ideas'
    };
    if (!allowedFolders.contains(folder)) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'Unknown folder'});
      return;
    }

    if (rawSegments.length == 1) {
      // /api/sinh-inputs/:folder
      if (method == 'GET') {
        await _handleSinhInputsListFolder(request, folder);
      } else if (method == 'POST' && folder == 'ideas') {
        await _handleSinhInputsCreateIdea(request);
      } else {
        _jsonResponse(request, HttpStatus.methodNotAllowed,
            {'error': 'Method not allowed'});
      }
      return;
    }

    final filename = Uri.decodeComponent(rawSegments[1]);
    if (!_isSafeFilename(filename)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    if (rawSegments.length == 2) {
      // /api/sinh-inputs/:folder/:filename
      if (method == 'GET') {
        await _handleSinhInputsGetItem(request, folder, filename);
      } else {
        _jsonResponse(request, HttpStatus.methodNotAllowed,
            {'error': 'Method not allowed'});
      }
      return;
    }

    if (rawSegments.length == 3 && method == 'POST') {
      // /api/sinh-inputs/:folder/:filename/:action
      final action = rawSegments[2];
      switch (action) {
        case 'requeue':
          await _handleSinhInputsRequeue(request, folder, filename);
        case 'archive':
          await _handleSinhInputsArchive(request, folder, filename);
        case 'save-for-later':
          if (folder != 'approved') {
            _jsonResponse(request, HttpStatus.badRequest, {
              'error': 'save-for-later is only available for approved items'
            });
          } else {
            await _handleSinhInputsSaveForLater(request, filename);
          }
        case 'append-section':
          await _handleSinhInputsAppendSection(request, folder, filename);
        default:
          _jsonResponse(
              request, HttpStatus.notFound, {'error': 'Unknown action'});
      }
      return;
    }

    _jsonResponse(request, HttpStatus.notFound, {'error': 'Not found'});
  }

  /// GET /api/sinh-inputs/:folder — List items in a sinh-inputs folder.
  ///
  /// Done folder supports: `?q=<keyword>&limit=<n>&offset=<n>`
  /// Done response: `{folder, items, total, hasMore}`
  /// Other folders: `{folder, items}`
  Future<void> _handleSinhInputsListFolder(
      HttpRequest request, String folder) async {
    final dirPath = _sinhInputsFolderPath(folder);
    final dir = Directory(dirPath);

    if (!dir.existsSync()) {
      if (folder == 'done') {
        _jsonResponse(request, HttpStatus.ok, {
          'folder': folder,
          'items': <dynamic>[],
          'total': 0,
          'hasMore': false,
        });
      } else {
        _jsonResponse(request, HttpStatus.ok, {
          'folder': folder,
          'items': <dynamic>[],
        });
      }
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      try {
        final filename = p.basename(entity.path);
        final content = entity.readAsStringSync();
        final metadata = parseMarkdownMetadata(content, filename: filename);
        final docType = detectDocumentType(content, filename);
        final stat = entity.statSync();

        final item = <String, dynamic>{
          'id': filename,
          ...metadata.toJson(),
          'type': docType,
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        };

        // For deferred, surface requeue_after at top level for easy UI access
        if (folder == 'deferred') {
          final requeueAfter = metadata.humanFeedback?.requeueAfter;
          if (requeueAfter != null) {
            item['requeue_after'] = requeueAfter;
          }
        }

        items.add(item);
      } catch (e) {
        stderr
            .writeln('Skipping malformed $folder file ${entity.path}: $e');
      }
    }

    // Sort by date descending (newest first)
    items.sort((a, b) {
      final aDate = a['date'] as String? ?? '';
      final bDate = b['date'] as String? ?? '';
      return bDate.compareTo(aDate);
    });

    if (folder == 'done') {
      // Apply keyword search and pagination
      final q = request.uri.queryParameters['q'];
      final limit =
          int.tryParse(request.uri.queryParameters['limit'] ?? '') ?? 20;
      final offset =
          int.tryParse(request.uri.queryParameters['offset'] ?? '') ?? 0;

      var filtered = items;
      if (q != null && q.isNotEmpty) {
        final qLower = q.toLowerCase();
        filtered = items.where((item) {
          final id = (item['id'] as String? ?? '').toLowerCase();
          final title = (item['title'] as String? ?? '').toLowerCase();
          return id.contains(qLower) || title.contains(qLower);
        }).toList();
      }

      final total = filtered.length;
      final paginated = filtered.skip(offset).take(limit).toList();
      final hasMore = offset + limit < total;

      _jsonResponse(request, HttpStatus.ok, {
        'folder': folder,
        'items': paginated,
        'total': total,
        'hasMore': hasMore,
      });
    } else {
      _jsonResponse(request, HttpStatus.ok, {
        'folder': folder,
        'items': items,
      });
    }
  }

  /// GET /api/sinh-inputs/:folder/:filename — Read single item content.
  Future<void> _handleSinhInputsGetItem(
      HttpRequest request, String folder, String filename) async {
    final filePath = p.join(_sinhInputsFolderPath(folder), filename);
    if (!_isWithinSandbox(filePath)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    final content = file.readAsStringSync();
    final metadata = parseMarkdownMetadata(content, filename: filename);
    final docType = detectDocumentType(content, filename);

    _jsonResponse(request, HttpStatus.ok, {
      'id': filename,
      'folder': folder,
      ...metadata.toJson(),
      'type': docType,
      'content': content,
    });
  }

  /// POST /api/sinh-inputs/:folder/:filename/requeue — Move item back to inbox.
  ///
  /// Adds `requeued_from: <folder>` to YAML frontmatter.
  /// Preserves all existing content and annotations intact.
  Future<void> _handleSinhInputsRequeue(
      HttpRequest request, String folder, String filename) async {
    final sourcePath = p.join(_sinhInputsFolderPath(folder), filename);
    if (!_isWithinSandbox(sourcePath)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(sourcePath);
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    // Add requeued_from frontmatter key, preserving all existing content
    final content = source.readAsStringSync();
    final updated = _insertFrontmatterKey(content, 'requeued_from', folder);
    source.writeAsStringSync(updated);

    // Move to inbox (atomic rename on same filesystem)
    _ensureDir(_inboxPath);
    final dest = File(p.join(_inboxPath, filename));
    source.renameSync(dest.path);

    _jsonResponse(request, HttpStatus.ok, {
      'status': 'requeued',
      'file': filename,
      'from': folder,
    });
  }

  /// POST /api/sinh-inputs/:folder/:filename/archive — Move item to done/.
  Future<void> _handleSinhInputsArchive(
      HttpRequest request, String folder, String filename) async {
    final sourcePath = p.join(_sinhInputsFolderPath(folder), filename);
    if (!_isWithinSandbox(sourcePath)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(sourcePath);
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    _ensureDir(_donePath);
    final dest = File(p.join(_donePath, filename));
    source.renameSync(dest.path);

    _jsonResponse(request, HttpStatus.ok, {
      'status': 'archived',
      'file': filename,
      'from': folder,
    });
  }

  /// POST /api/sinh-inputs/approved/:filename/save-for-later
  ///
  /// Moves approved item to for-later/, adds `saved_from: approved` frontmatter.
  Future<void> _handleSinhInputsSaveForLater(
      HttpRequest request, String filename) async {
    final sourcePath = p.join(_sinhInputsFolderPath('approved'), filename);
    if (!_isWithinSandbox(sourcePath)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }

    final source = File(sourcePath);
    if (!source.existsSync()) {
      _jsonResponse(request, HttpStatus.notFound, {'error': 'File not found'});
      return;
    }

    // Add saved_from frontmatter key
    final content = source.readAsStringSync();
    final updated = _insertFrontmatterKey(content, 'saved_from', 'approved');
    source.writeAsStringSync(updated);

    _ensureDir(_forLaterPath);
    final dest = File(p.join(_forLaterPath, filename));
    source.renameSync(dest.path);

    _jsonResponse(request, HttpStatus.ok, {
      'status': 'saved-for-later',
      'file': filename,
    });
  }

  /// POST /api/sinh-inputs/ideas — Create a new idea.
  ///
  /// Body (JSON): `{title*, category?, effort?, what?, why?, who?, notes?, tags?}`
  /// Generated file format matches `pa idea` CLI output exactly.
  /// `tags` accepts a JSON array or a space-separated string.
  Future<void> _handleSinhInputsCreateIdea(HttpRequest request) async {
    String body;
    try {
      body = await utf8.decoder.bind(request).join();
    } catch (e) {
      _jsonResponse(request, HttpStatus.internalServerError,
          {'error': 'Failed to read request body'});
      return;
    }

    if (body.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Body required'});
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Invalid JSON body'});
      return;
    }

    final title = json['title'] as String?;
    if (title == null || title.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'title is required'});
      return;
    }

    final category = (json['category'] as String?)?.trim() ?? 'personal';
    final effort = (json['effort'] as String?)?.trim() ?? 'M';
    final what = (json['what'] as String?)?.trim();
    final why = (json['why'] as String?)?.trim();
    final who = (json['who'] as String?)?.trim() ?? 'Sinh';
    final notes = (json['notes'] as String?)?.trim();

    // Tags: accept array or space-separated string — matches pa idea CLI format
    String tagsFormatted;
    final tagsRaw = json['tags'];
    if (tagsRaw is List && tagsRaw.isNotEmpty) {
      final tags =
          tagsRaw.whereType<String>().where((t) => t.isNotEmpty).toList();
      tagsFormatted =
          tags.isNotEmpty ? tags.map((t) => '`$t`').join(' ') : '(none yet)';
    } else if (tagsRaw is String && tagsRaw.trim().isNotEmpty) {
      tagsFormatted = tagsRaw
          .trim()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .map((t) => '`$t`')
          .join(' ');
    } else {
      tagsFormatted = '(none yet)';
    }

    // Generate filename — matches pa idea CLI slugify logic
    final now = DateTime.now();
    final today = _formatDate(now);
    final timestamp = _formatTimestamp(now);
    final slug = _slugify(title);

    final ideasDir = _sinhInputsFolderPath('ideas');
    _ensureDir(ideasDir);

    var filename = '$today-$slug.md';
    if (File(p.join(ideasDir, filename)).existsSync()) {
      var counter = 2;
      while (
          File(p.join(ideasDir, '$today-$slug-$counter.md')).existsSync()) {
        counter++;
      }
      filename = '$today-$slug-$counter.md';
    }

    // Build file content — identical structure to pa idea CLI output
    final buf = StringBuffer();
    buf.writeln('# Idea: $title');
    buf.writeln();
    buf.writeln('> **Date:** $timestamp');
    buf.writeln('> **Category:** $category');
    buf.writeln('> **Status:** new');
    buf.writeln('> **Effort:** $effort');
    buf.writeln();
    buf.writeln('## What');
    buf.writeln(what != null && what.isNotEmpty ? what : title);
    buf.writeln();
    buf.writeln('## Why');
    buf.writeln(why != null && why.isNotEmpty ? why : '_(not specified)_');
    buf.writeln();
    buf.writeln('## Who');
    buf.writeln(who);
    buf.writeln();
    buf.writeln('## Notes');
    buf.writeln(notes != null && notes.isNotEmpty ? notes : '_(none)_');
    buf.writeln();
    buf.writeln('## Tags');
    buf.write(tagsFormatted);
    buf.writeln();

    File(p.join(ideasDir, filename)).writeAsStringSync(buf.toString());

    _jsonResponse(request, HttpStatus.ok, {
      'status': 'created',
      'file': filename,
    });
  }

  /// POST /api/sinh-inputs/:folder/:filename/append-section
  ///
  /// Appends a `### Section` to a file in any sinh-inputs folder.
  /// Primarily used for ideas. Reuses `_doAppendSection` logic.
  Future<void> _handleSinhInputsAppendSection(
      HttpRequest request, String folder, String filename) async {
    final filePath = p.join(_sinhInputsFolderPath(folder), filename);
    if (!_isWithinSandbox(filePath)) {
      _jsonResponse(request, HttpStatus.forbidden, {'error': 'Invalid path'});
      return;
    }
    final source = File(filePath);
    await _doAppendSection(request, source, filename);
  }

  // --- PA deploy endpoints ---

  /// GET /api/pa-teams — List available PA teams with their deploy modes.
  ///
  /// Reads YAML files from PA_CONFIG/teams (if set) then PA_HOME/teams.
  /// Config-dir teams shadow home-dir teams of the same name.
  /// Excludes `example` team and modes with `phone_visible: false`.
  Future<void> _handleListPaTeams(HttpRequest request) async {
    final teams = await _loadPaTeams();
    _jsonResponse(request, HttpStatus.ok,
        {'teams': teams.map((t) => t.toJson()).toList()});
  }

  /// POST /api/deploy — Trigger a PA team deployment.
  ///
  /// Body (JSON): `{"team": "builder", "mode": "background"}`
  /// Validates team + mode against the YAML whitelist before executing.
  /// Runs the `pa` command as a detached subprocess and returns immediately
  /// with the deployment ID parsed from the primer path in pa's output.
  ///
  /// Returns: `{"deployment_id": "d-abc123", "started": true, "team": ..., "mode": ...}`
  Future<void> _handleDeploy(HttpRequest request) async {
    String body;
    try {
      body = await utf8.decoder.bind(request).join();
    } catch (e) {
      _jsonResponse(request, HttpStatus.internalServerError,
          {'error': 'Failed to read request body'});
      return;
    }

    if (body.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Body required'});
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Invalid JSON body'});
      return;
    }

    final team = json['team'] as String?;
    final mode = json['mode'] as String?;

    if (team == null || team.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'team is required'});
      return;
    }
    if (mode == null || mode.isEmpty) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'mode is required'});
      return;
    }

    // Validate team name (alphanumeric + hyphens only — no shell injection)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(team)) {
      _jsonResponse(
          request, HttpStatus.badRequest, {'error': 'Invalid team name'});
      return;
    }

    // Validate team + mode against YAML whitelist
    final teams = await _loadPaTeams();
    final paTeam = teams.where((t) => t.name == team).firstOrNull;
    if (paTeam == null) {
      _jsonResponse(request, HttpStatus.badRequest,
          {'error': 'Unknown team: $team'});
      return;
    }

    // Check mode exists in team (any mode, including phone_visible: false)
    // Load full team (unfiltered) to validate the mode
    final fullTeams = await _loadPaTeams(filterPhoneVisible: false);
    final fullTeam = fullTeams.where((t) => t.name == team).firstOrNull;
    final deployMode =
        fullTeam?.deployModes.where((m) => m.id == mode).firstOrNull;
    if (deployMode == null) {
      _jsonResponse(request, HttpStatus.badRequest,
          {'error': 'Unknown mode: $mode for team: $team'});
      return;
    }

    // Build pa command
    // daily team: `pa daily <mode>` — all other teams: `pa deploy <team> [--flag]`
    final List<String> args;
    if (team == 'daily') {
      args = ['daily', mode];
    } else {
      args = ['deploy', team];
      if (mode == 'background') args.add('--background');
      if (mode == 'interactive') args.add('--interactive');
      // foreground: no extra flag
    }

    // Start subprocess and read first line for deployment ID
    String deploymentId = '';
    try {
      final process =
          await Process.start(paBinPath, args, runInShell: false);

      // Drain stderr to prevent back-pressure
      process.stderr.listen((_) {});

      // Read stdout until first newline, with 5s timeout
      final completer = Completer<String>();
      String partial = '';
      final sub = process.stdout.transform(utf8.decoder).listen(
        (chunk) {
          if (completer.isCompleted) return;
          final nl = chunk.indexOf('\n');
          if (nl >= 0) {
            completer.complete(partial + chunk.substring(0, nl));
          } else {
            partial += chunk;
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(partial);
        },
        onError: (Object e) {
          if (!completer.isCompleted) completer.complete('');
        },
        cancelOnError: true,
      );

      final String firstLine;
      try {
        firstLine = await completer.future
            .timeout(const Duration(seconds: 5), onTimeout: () => '');
      } finally {
        await sub.cancel();
      }

      // Extract deployment ID: "Primer generated: .../d-abc123-primer.md"
      final match = RegExp(r'\b(d-[a-f0-9]{6})\b').firstMatch(firstLine);
      if (match != null) deploymentId = match.group(1)!;
    } catch (e) {
      _jsonResponse(request, HttpStatus.internalServerError,
          {'error': 'Failed to start deployment: $e'});
      return;
    }

    _jsonResponse(request, HttpStatus.ok, {
      'deployment_id': deploymentId,
      'started': true,
      'team': team,
      'mode': mode,
    });
  }

  /// GET /api/timers — List active PA systemd timers.
  ///
  /// Runs `pa timers` and parses the output into a structured list.
  /// Also includes the raw output for debugging.
  Future<void> _handleListTimers(HttpRequest request) async {
    try {
      final result =
          await Process.run(paBinPath, ['timers'], runInShell: false);
      final output = result.stdout as String;
      final timers = _parseTimersOutput(output);
      _jsonResponse(request, HttpStatus.ok, {
        'timers': timers,
        'raw': output.trim(),
      });
    } catch (e) {
      _jsonResponse(request, HttpStatus.internalServerError,
          {'error': 'Failed to list timers: $e'});
    }
  }

  // --- PA team YAML parsing ---

  /// Load PA teams from disk (PA_CONFIG/teams overrides PA_HOME/teams).
  ///
  /// [filterPhoneVisible] — when true (default), only include modes where
  /// `phone_visible: true`. Pass false to load all modes (for validation).
  Future<List<_PaTeam>> _loadPaTeams(
      {bool filterPhoneVisible = true}) async {
    final teamsDirs = <String>[];
    if (paConfigDir != null) {
      teamsDirs.add(p.join(paConfigDir!, 'teams'));
    }
    teamsDirs.add(p.join(paHome, 'teams'));

    final seenNames = <String>{};
    final teams = <_PaTeam>[];

    for (final dir in teamsDirs) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final entity in d.listSync()) {
        if (entity is! File || !entity.path.endsWith('.yaml')) continue;
        final filename = p.basename(entity.path);
        if (filename == 'example.yaml') continue;
        try {
          final content = entity.readAsStringSync();
          final team = _parseTeamYaml(content,
              filterPhoneVisible: filterPhoneVisible);
          if (team != null && !seenNames.contains(team.name)) {
            seenNames.add(team.name);
            teams.add(team);
          }
        } catch (e) {
          stderr.writeln('Error parsing team YAML $filename: $e');
        }
      }
    }

    teams.sort((a, b) => a.name.compareTo(b.name));
    return teams;
  }

  /// Parse a PA team YAML file into a [_PaTeam].
  ///
  /// Only handles the specific fields needed for deploy support:
  /// `name`, `description`, and `deploy_modes:` list.
  /// Returns null if the file has no `name:` field.
  _PaTeam? _parseTeamYaml(String content,
      {bool filterPhoneVisible = true}) {
    String? name;
    String? description;
    final modes = <_DeployMode>[];

    bool inDeployModes = false;
    Map<String, String>? currentMode;

    for (final rawLine in content.split('\n')) {
      final line = rawLine.trimRight();

      if (line.isEmpty || line.startsWith('#')) continue;

      // Top-level keys (no indentation)
      if (!line.startsWith(' ') && !line.startsWith('\t')) {
        // Flush pending mode
        if (inDeployModes && currentMode != null) {
          final m = _DeployMode.fromMap(currentMode);
          if (m != null) modes.add(m);
          currentMode = null;
        }

        if (line.startsWith('name:')) {
          name = _yamlScalar(line, 'name');
        } else if (line.startsWith('description:')) {
          description = _yamlScalar(line, 'description');
        }

        inDeployModes = line.trim() == 'deploy_modes:';
        continue;
      }

      // Indented content under deploy_modes:
      if (!inDeployModes) continue;

      final trimmed = line.trim();
      if (trimmed.startsWith('- ')) {
        // New list item — flush previous
        if (currentMode != null) {
          final m = _DeployMode.fromMap(currentMode);
          if (m != null) modes.add(m);
        }
        currentMode = {};
        final rest = trimmed.substring(2).trim();
        _parseYamlKv(rest, currentMode);
      } else if (currentMode != null && trimmed.isNotEmpty) {
        _parseYamlKv(trimmed, currentMode);
      }
    }

    // Flush last mode
    if (inDeployModes && currentMode != null) {
      final m = _DeployMode.fromMap(currentMode);
      if (m != null) modes.add(m);
    }

    if (name == null) return null;

    final filteredModes = filterPhoneVisible
        ? modes.where((m) => m.phoneVisible).toList()
        : modes;

    return _PaTeam(
      name: name,
      description: description ?? '',
      deployModes: filteredModes,
    );
  }

  /// Extract a scalar value from a YAML line like `key: value` or `key: "value"`.
  String? _yamlScalar(String line, String key) {
    final colonIdx = line.indexOf(':');
    if (colonIdx < 0) return null;
    var value = line.substring(colonIdx + 1).trim();
    // Strip surrounding quotes
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    return value.isEmpty ? null : value;
  }

  /// Parse `key: value` into a map entry (in-place).
  void _parseYamlKv(String line, Map<String, String> target) {
    final colonIdx = line.indexOf(':');
    if (colonIdx < 0) return;
    final key = line.substring(0, colonIdx).trim();
    var value = line.substring(colonIdx + 1).trim();
    // Strip quotes
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    if (key.isNotEmpty) target[key] = value;
  }

  /// Parse `pa timers` output into a structured list.
  ///
  /// Output format (systemctl list-timers):
  /// ```
  /// NEXT                        LEFT LAST   PASSED UNIT               ACTIVATES
  /// Mon 2026-03-16 05:00:00 +07   6h Sun … - pa-daily-plan.timer …
  /// ```
  List<Map<String, String>> _parseTimersOutput(String output) {
    final timers = <Map<String, String>>[];
    for (final line in output.split('\n').skip(1)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      final timerIdx = parts.indexWhere((part) => part.endsWith('.timer'));
      if (timerIdx < 0) continue;

      final unit = parts[timerIdx];
      // LEFT is the 5th token (index 4): after DAY DATE TIME ZONE
      final left = parts.length > 4 ? parts[4] : '';
      // Strip "pa-" prefix and ".timer" suffix for a readable team name
      final team = unit
          .replaceFirst(RegExp(r'^pa-'), '')
          .replaceFirst('.timer', '');
      timers.add({'unit': unit, 'team': team, 'next_in': left});
    }
    return timers;
  }

  // --- Helpers ---

  /// Parse a `chips:` YAML list from a config file.
  ///
  /// Handles simple YAML list syntax: `  - "value"` or `  - value`.
  List<String> _parseChipsYaml(String yaml) {
    final chips = <String>[];
    bool inChips = false;
    for (final rawLine in yaml.split('\n')) {
      final line = rawLine.trimRight();
      if (line.trim() == 'chips:') {
        inChips = true;
        continue;
      }
      if (inChips) {
        if (line.isEmpty) continue;
        // Stop at non-indented non-empty line
        if (!line.startsWith(' ') && !line.startsWith('\t')) {
          inChips = false;
          continue;
        }
        final trimmed = line.trim();
        if (trimmed.startsWith('- ')) {
          var value = trimmed.substring(2).trim();
          // Unquote quoted values
          if (value.length >= 2 &&
              ((value.startsWith('"') && value.endsWith('"')) ||
                  (value.startsWith("'") && value.endsWith("'")))) {
            value = value.substring(1, value.length - 1);
          }
          if (value.isNotEmpty) chips.add(value);
        }
      }
    }
    return chips;
  }

  /// Compute the filesystem path for a sinh-inputs folder.
  String _sinhInputsFolderPath(String folder) =>
      p.join(aiUsagePath, 'sinh-inputs', folder);

  /// Insert or update a top-level key-value pair in YAML frontmatter.
  ///
  /// Creates a new frontmatter block if none exists.
  /// Replaces any existing key with the same name.
  String _insertFrontmatterKey(String content, String key, String value) {
    if (content.startsWith('---\n')) {
      final endIdx = content.indexOf('\n---\n', 4);
      if (endIdx != -1) {
        var fm = content.substring(4, endIdx);
        final after = content.substring(endIdx + 5);
        fm = _dropFrontmatterKey(fm, key);
        if (fm.isNotEmpty && !fm.endsWith('\n')) fm = '$fm\n';
        fm = '$fm$key: $value';
        return '---\n$fm\n---\n$after';
      }
    }
    return '---\n$key: $value\n---\n$content';
  }

  /// Remove all lines for a top-level key (and its indented children)
  /// from a raw YAML string (no surrounding `---` delimiters).
  String _dropFrontmatterKey(String yaml, String key) {
    final lines = yaml.split('\n');
    final result = <String>[];
    bool inKey = false;
    for (final line in lines) {
      if (line == '$key:' ||
          line.startsWith('$key: ') ||
          line.startsWith('$key:\t')) {
        inKey = true;
        continue;
      }
      if (inKey) {
        if (line.startsWith(' ') || line.startsWith('\t') || line.isEmpty) {
          continue;
        }
        inKey = false;
      }
      result.add(line);
    }
    while (result.isNotEmpty && result.last.isEmpty) {
      result.removeLast();
    }
    return result.join('\n');
  }

  /// Slugify a title to a URL-safe filename component (max 50 chars).
  ///
  /// Matches the slugify logic used by the `pa idea` CLI.
  String _slugify(String title) {
    var slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    if (slug.startsWith('-')) slug = slug.substring(1);
    if (slug.endsWith('-')) slug = slug.substring(0, slug.length - 1);
    if (slug.length > 50) {
      slug = slug.substring(0, 50);
      while (slug.endsWith('-')) {
        slug = slug.substring(0, slug.length - 1);
      }
    }
    return slug;
  }

  /// Format a [DateTime] as `YYYY-MM-DD`.
  String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  /// Format a [DateTime] as `YYYY-MM-DD HH:MM` — matches `pa idea` CLI format.
  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt)} $h:$min';
  }

  /// Send a JSON response.
  void _jsonResponse(
      HttpRequest request, int statusCode, Map<String, dynamic> body) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body))
      ..close();
  }

  /// Ensure a directory exists, creating it if needed.
  void _ensureDir(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Extract filename from a path like `/api/inbox/some-file.md`.
  String? _extractFilename(String path, String prefix) {
    if (!path.startsWith(prefix)) return null;
    final rest = path.substring(prefix.length);
    if (rest.isEmpty) return null;
    return Uri.decodeComponent(rest);
  }

  /// Extract filename from an action path like `/api/inbox/file.md/approve`.
  String? _extractActionFilename(
      String path, String prefix, String actionSuffix) {
    if (!path.startsWith(prefix) || !path.endsWith(actionSuffix)) return null;
    final rest =
        path.substring(prefix.length, path.length - actionSuffix.length);
    if (rest.isEmpty) return null;
    return Uri.decodeComponent(rest);
  }

  /// Check if a filename is safe (no path traversal).
  bool _isSafeFilename(String name) {
    if (name.contains('..') || name.contains('/') || name.contains('\\')) {
      return false;
    }
    if (name.startsWith('.')) return false;
    return name.isNotEmpty;
  }

  /// Check if a resolved path is within the ai-usage sandbox.
  bool _isWithinSandbox(String filePath) {
    final resolved = p.canonicalize(filePath);
    final sandbox = p.canonicalize(aiUsagePath);
    return resolved.startsWith(sandbox);
  }
}

// --- Private data classes for PA team support ---

class _PaTeam {
  final String name;
  final String description;
  final List<_DeployMode> deployModes;

  const _PaTeam({
    required this.name,
    required this.description,
    required this.deployModes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'deploy_modes': deployModes.map((m) => m.toJson()).toList(),
      };
}

class _DeployMode {
  final String id;
  final String label;
  final bool phoneVisible;

  const _DeployMode({
    required this.id,
    required this.label,
    required this.phoneVisible,
  });

  /// Parse a deploy mode from a map of YAML key-value pairs.
  static _DeployMode? fromMap(Map<String, String> map) {
    final id = map['id'];
    final label = map['label'];
    if (id == null || id.isEmpty || label == null || label.isEmpty) return null;
    final phoneVisible = map['phone_visible']?.toLowerCase() == 'true';
    return _DeployMode(id: id, label: label, phoneVisible: phoneVisible);
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}
