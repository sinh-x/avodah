/// HTTP API service for agent workflow operations.
///
/// Provides endpoints for reviewing inbox items, viewing deployment status,
/// and browsing agent team folders. All file access is sandboxed to
/// `~/Documents/ai-usage/`.
library;

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

  AgentApiService({
    String? aiUsagePath,
    String? registryPath,
  })  : aiUsagePath = aiUsagePath ??
            p.join(Platform.environment['HOME'] ?? '/home', 'Documents',
                'ai-usage'),
        registryPath = registryPath ??
            p.join(
                Platform.environment['HOME'] ?? '/home',
                'Documents',
                'ai-usage',
                'deployments',
                'registry.jsonl');

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
      if (path == '/api/inbox' && method == 'GET') {
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
    } catch (_) {
      // Use no feedback if body parsing fails
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

    // Parse feedback body
    bool pending = false;
    String? whatIsWrong;
    String? whatToFix;
    String priority = 'medium';
    List<String> chips = const [];
    try {
      final body = await utf8.decoder.bind(request).join();
      if (body.isNotEmpty) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        pending = json['pending'] == true;
        whatIsWrong = json['what_is_wrong'] as String?;
        whatToFix = json['what_to_fix'] as String?;
        priority = json['priority'] as String? ?? 'medium';
        final chipsRaw = json['chips'];
        if (chipsRaw is List) {
          chips = chipsRaw.whereType<String>().toList();
        }
      }
    } catch (_) {
      // Use defaults if body parsing fails
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
          whatIsWrong: whatIsWrong ?? 'No reason provided',
          whatToFix: whatToFix ?? '',
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
    } catch (_) {
      // Use no feedback if body parsing fails
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
    } catch (_) {
      // Use no note if body parsing fails
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
      teams.add({'name': name, 'folders': folders});
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
