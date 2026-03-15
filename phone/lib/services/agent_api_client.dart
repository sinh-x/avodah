import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/create_idea_payload.dart';
import '../models/deploy_result.dart';
import '../models/deployment.dart';
import '../models/feedback_payload.dart';
import '../models/pa_team.dart';
import '../models/review_item.dart';
import '../models/team_folder.dart';
import '../models/timer_info.dart';

/// HTTP client for the agent workflow API endpoints.
///
/// Wraps the API exposed by the sync server's AgentApiService.
/// Base URL is derived from the WebSocket URL (same host:port, HTTP scheme).
class AgentApiClient {
  final String baseUrl;
  final http.Client _client;

  AgentApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// Construct from the WebSocket server URL.
  ///
  /// Converts `ws://host:port` → `http://host:port`.
  factory AgentApiClient.fromWsUrl(String wsUrl) {
    final uri = Uri.parse(wsUrl);
    final httpUrl = uri.replace(scheme: 'http').toString();
    // Remove trailing slash if present
    final base = httpUrl.endsWith('/') ? httpUrl.substring(0, httpUrl.length - 1) : httpUrl;
    return AgentApiClient(baseUrl: base);
  }

  // --- Inbox ---

  /// List all inbox items with parsed metadata.
  Future<List<ReviewItem>> listInbox() async {
    final response = await _get('/api/inbox');
    final items = response['items'] as List;
    return items
        .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single inbox item with full markdown content.
  Future<ReviewItem> getInboxItem(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    final response = await _get('/api/inbox/$encoded');
    return ReviewItem.fromJson(response);
  }

  /// Approve an inbox item (moves to approved/).
  ///
  /// Pass [feedback] to include optional note and chips.
  /// Annotation is written only when feedback is non-empty (fast-path: no body sent).
  Future<void> approveItem(String filename, {ApproveFeedback? feedback}) async {
    final encoded = Uri.encodeComponent(filename);
    final body = (feedback != null && feedback.hasContent) ? feedback.toJson() : null;
    await _post('/api/inbox/$encoded/approve', body: body);
  }

  /// Reject an inbox item with structured feedback (moves to rejected/).
  ///
  /// Use [RejectFeedback.pendingOnly()] to create a pending-reject-feedback state.
  Future<void> rejectItem(String filename, RejectFeedback feedback) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/inbox/$encoded/reject', body: feedback.toJson());
  }

  /// Defer an inbox item (moves to deferred/).
  ///
  /// Pass [feedback] to include optional note, date, and chips.
  /// Annotation is written only when feedback is non-empty (fast-path: no body sent).
  Future<void> deferItem(String filename, {DeferFeedback? feedback}) async {
    final encoded = Uri.encodeComponent(filename);
    final body = (feedback != null && feedback.hasContent) ? feedback.toJson() : null;
    await _post('/api/inbox/$encoded/defer', body: body);
  }

  /// Save an inbox item for later (moves to for-later/, writes minimal YAML frontmatter).
  Future<void> saveForLater(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/inbox/$encoded/save-for-later');
  }

  /// Acknowledge a work-report or fyi item (moves to done/).
  ///
  /// Fast-path: omit [note] for a clean move with no annotation written.
  /// With [note]: writes `human_feedback.action: acknowledged` + note to YAML
  /// frontmatter only — no `## Human Review` section.
  Future<void> acknowledgeItem(String filename, {String? note}) async {
    final encoded = Uri.encodeComponent(filename);
    final body =
        (note != null && note.isNotEmpty) ? <String, dynamic>{'note': note} : null;
    await _post('/api/inbox/$encoded/acknowledge', body: body);
  }

  /// Append a named section to an inbox item (file stays in inbox).
  Future<void> appendSection(
      String filename, String title, String content) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/inbox/$encoded/append-section',
        body: {'title': title, 'content': content});
  }

  /// Fetch feedback chip labels from server config.
  ///
  /// Returns empty list if config is missing or malformed.
  Future<List<String>> getFeedbackChips() async {
    final response = await _get('/api/config/feedback-chips');
    final chips = response['chips'] as List? ?? [];
    return chips.map((e) => e as String).toList();
  }

  /// Fetch the existing human_feedback block for a pending-reject-feedback item.
  Future<Map<String, dynamic>> getItemFeedback(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    return _get('/api/inbox/$encoded/feedback');
  }

  // --- For Later ---

  /// List all for-later items with parsed metadata.
  Future<List<ReviewItem>> listForLater() async {
    final response = await _get('/api/for-later');
    final items = response['items'] as List;
    return items
        .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single for-later item with full markdown content.
  Future<ReviewItem> getForLaterItem(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    final response = await _get('/api/for-later/$encoded');
    return ReviewItem.fromJson(response);
  }

  // --- Deployments ---

  /// List all deployments with computed status.
  Future<List<Deployment>> listDeployments() async {
    final response = await _get('/api/deployments');
    final deployments = response['deployments'] as List;
    return deployments
        .map((e) => Deployment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Teams ---

  /// List all agent teams.
  Future<List<TeamFolder>> listTeams() async {
    final response = await _get('/api/teams');
    final teams = response['teams'] as List;
    return teams
        .map((e) => TeamFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// List files in a team's folder.
  Future<List<TeamFile>> listTeamFolder(String team, String folder) async {
    final response = await _get('/api/teams/$team/$folder');
    final files = response['files'] as List;
    return files
        .map((e) => TeamFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Read a file from a team folder (returns full content with metadata).
  Future<ReviewItem> getTeamFile(
      String team, String folder, String filename) async {
    final response = await _get('/api/teams/$team/$folder/$filename');
    return ReviewItem.fromJson(response);
  }

  // --- sinh-inputs Folder Browser ---

  /// List items in a sinh-inputs folder.
  ///
  /// [folder] ∈ {approved, rejected, deferred, done, ideas}.
  /// Done folder supports [q] keyword search and [limit]/[offset] pagination.
  Future<List<ReviewItem>> listFolder(
    String folder, {
    String? q,
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final query =
        params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    final response = await _get('/api/sinh-inputs/$folder$query');
    final items = response['items'] as List;
    return items
        .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single item from a sinh-inputs folder with full markdown content.
  Future<ReviewItem> getFolderItem(String folder, String filename) async {
    final encoded = Uri.encodeComponent(filename);
    final response = await _get('/api/sinh-inputs/$folder/$encoded');
    return ReviewItem.fromJson(response);
  }

  /// Re-queue an item from a resolved folder back to inbox/.
  ///
  /// Adds `requeued_from: <folder>` to YAML frontmatter and moves the file.
  Future<void> requeueItem(String folder, String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/sinh-inputs/$folder/$encoded/requeue');
  }

  /// Archive an item from any folder by moving it to done/.
  Future<void> archiveItem(String folder, String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/sinh-inputs/$folder/$encoded/archive');
  }

  /// Save an approved item for later (moves from approved/ to for-later/).
  ///
  /// Distinct from [saveForLater] which operates on inbox items.
  Future<void> saveApprovedForLater(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/sinh-inputs/approved/$encoded/save-for-later');
  }

  /// Create a new idea in ideas/ folder.
  ///
  /// The generated file format matches `pa idea` CLI output exactly.
  Future<void> createIdea(CreateIdeaPayload payload) async {
    await _post('/api/sinh-inputs/ideas', body: payload.toJson());
  }

  /// Append a named section to an idea file.
  Future<void> appendToIdea(
      String filename, String title, String content) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/sinh-inputs/ideas/$encoded/append-section',
        body: {'title': title, 'content': content});
  }

  /// List items in the done folder with search and pagination.
  ///
  /// Returns [PagedFolderResult] with items, total count, and hasMore flag.
  /// Uses server-side keyword search (`?q=`) and pagination (`limit`/`offset`).
  Future<PagedFolderResult> listFolderPaged(
    String folder, {
    String? q,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (q != null && q.isNotEmpty) params['q'] = q;
    final query = '?${Uri(queryParameters: params).query}';
    final response = await _get('/api/sinh-inputs/$folder$query');
    final items = (response['items'] as List)
        .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedFolderResult(
      items: items,
      total: response['total'] as int? ?? items.length,
      hasMore: response['hasMore'] as bool? ?? false,
    );
  }

  // --- PA Deploy ---

  /// List available PA teams with their deploy modes (phone-visible only).
  Future<List<PaTeam>> listPaTeams() async {
    final response = await _get('/api/pa-teams');
    final teams = response['teams'] as List;
    return teams
        .map((e) => PaTeam.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Trigger a PA team deployment.
  ///
  /// Validates team + mode on the server before executing.
  /// Returns immediately after the subprocess is started.
  Future<DeployResult> triggerDeployment(
    String team,
    String mode, {
    String? objective,
  }) async {
    final body = <String, dynamic>{'team': team, 'mode': mode};
    if (objective != null && objective.isNotEmpty) {
      body['objective'] = objective;
    }
    final response = await _post('/api/deploy', body: body);
    return DeployResult.fromJson(response);
  }

  /// List active PA systemd timers.
  Future<List<TimerInfo>> listTimers() async {
    final response = await _get('/api/timers');
    final timers = response['timers'] as List;
    return timers
        .map((e) => TimerInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- HTTP helpers ---

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode != 200) {
      throw AgentApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path,
      {Map<String, dynamic>? body}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: body != null ? {'Content-Type': 'application/json'} : null,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode != 200) {
      throw AgentApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() {
    _client.close();
  }
}

class AgentApiException implements Exception {
  final int statusCode;
  final String body;

  AgentApiException(this.statusCode, this.body);

  @override
  String toString() => 'AgentApiException($statusCode): $body';
}

/// Result type for paginated folder listing (done folder).
class PagedFolderResult {
  final List<ReviewItem> items;
  final int total;
  final bool hasMore;

  const PagedFolderResult({
    required this.items,
    required this.total,
    required this.hasMore,
  });
}
