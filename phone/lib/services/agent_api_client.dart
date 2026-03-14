import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/deployment.dart';
import '../models/feedback_payload.dart';
import '../models/review_item.dart';
import '../models/team_folder.dart';

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
