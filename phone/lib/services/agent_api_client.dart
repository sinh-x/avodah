import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/deployment.dart';
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
  Future<void> approveItem(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/inbox/$encoded/approve');
  }

  /// Reject an inbox item with a reason (appends reason, moves to rejected/).
  Future<void> rejectItem(String filename, {String? reason}) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/inbox/$encoded/reject',
        body: reason != null ? {'reason': reason} : null);
  }

  /// Defer an inbox item (moves to deferred/).
  Future<void> deferItem(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/inbox/$encoded/defer');
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
