import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show XFile;

import '../models/activity_event.dart';
import '../models/agent_team.dart';
import '../models/bulletin.dart';
import '../models/create_idea_payload.dart';
import '../models/dashboard_views.dart';
import '../models/deploy_result.dart';
import '../models/deploy_routing.dart';
import '../models/deployment.dart';
import '../models/focus_item.dart';
import '../models/git_summary.dart';
import '../models/repo_branches.dart';
import '../models/repo_commits.dart';
import '../models/repo_compare.dart';
import '../models/repo_diff.dart';
import '../models/repo_git_info.dart';
import '../models/repo_remote_branches.dart';
import '../models/feedback_payload.dart';
import '../models/pa_team.dart';
import '../models/review_item.dart';
import '../models/session_record.dart';
import '../models/team_folder.dart';
import '../models/ticket.dart';
import '../models/timer_info.dart';
import 'kanban_constants.dart';

/// HTTP client for the agent workflow API endpoints.
///
/// Wraps the API exposed by pa serve (TypeScript server on port 9848,
/// proxied via Docker on port 9847).
/// Base URL is derived from the WebSocket URL (same host:port, HTTP scheme).
class AgentApiClient {
  final String baseUrl;
  final http.Client _client;

  /// Pairing token for authenticated proxy requests.
  String? pairingToken;

  /// Node ID for authenticated proxy requests.
  String? nodeId;

  AgentApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// Auth headers for proxy requests via the sync server.
  Map<String, String> get _authHeaders => {
        if (pairingToken != null) 'X-Av-Pair-Token': pairingToken!,
        if (nodeId != null) 'X-Av-Node-Id': nodeId!,
      };

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
    final response = await _get('/api/folders/inbox/$encoded');
    return ReviewItem.fromJson(response);
  }

  /// Approve an inbox item (moves to approved/).
  ///
  /// Pass [feedback] to include optional note and chips.
  /// Annotation is written only when feedback is non-empty (fast-path: no extra fields sent).
  Future<void> approveItem(String filename, {ApproveFeedback? feedback}) async {
    final encoded = Uri.encodeComponent(filename);
    final body = <String, dynamic>{'action': 'approve'};
    if (feedback != null && feedback.hasContent) {
      if (feedback.note != null && feedback.note!.isNotEmpty) body['note'] = feedback.note;
      if (feedback.chips.isNotEmpty) body['chips'] = feedback.chips;
      if (feedback.destinationTeam != null && feedback.destinationTeam!.isNotEmpty) {
        body['destination_team'] = feedback.destinationTeam;
      }
    }
    await _post('/api/inbox/$encoded/action', body: body);
  }

  /// Reject an inbox item with structured feedback (moves to rejected/).
  ///
  /// Use [RejectFeedback.pendingOnly()] to create a pending-reject-feedback state.
  Future<void> rejectItem(String filename, RejectFeedback feedback) async {
    final encoded = Uri.encodeComponent(filename);
    final body = <String, dynamic>{'action': 'reject'};
    if (feedback.pending) {
      body['pending'] = true;
    } else {
      body['what_is_wrong'] = feedback.whatIsWrong;
      body['what_to_fix'] = feedback.whatToFix;
      body['priority'] = feedback.priority.apiValue;
      if (feedback.chips.isNotEmpty) body['chips'] = feedback.chips;
      if (feedback.destinationTeam != null && feedback.destinationTeam!.isNotEmpty) {
        body['destination_team'] = feedback.destinationTeam;
      }
    }
    await _post('/api/inbox/$encoded/action', body: body);
  }

  /// Defer an inbox item (moves to deferred/).
  ///
  /// Pass [feedback] to include optional note, date, and chips.
  /// Annotation is written only when feedback is non-empty (fast-path: no extra fields sent).
  Future<void> deferItem(String filename, {DeferFeedback? feedback}) async {
    final encoded = Uri.encodeComponent(filename);
    final body = <String, dynamic>{'action': 'defer'};
    if (feedback != null && feedback.hasContent) {
      if (feedback.reason != null && feedback.reason!.isNotEmpty) body['reason'] = feedback.reason;
      if (feedback.requeueAfter != null) body['requeue_after'] = feedback.requeueAfter;
      if (feedback.chips.isNotEmpty) body['chips'] = feedback.chips;
    }
    await _post('/api/inbox/$encoded/action', body: body);
  }

  /// Save an inbox item for later (moves to for-later/, writes minimal YAML frontmatter).
  Future<void> saveForLater(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/inbox/$encoded/action', body: {'action': 'save-for-later'});
  }

  /// Acknowledge a work-report or fyi item (moves to done/).
  ///
  /// Fast-path: omit [note] for a clean move with no annotation written.
  /// With [note]: writes `human_feedback.action: acknowledged` + note to YAML
  /// frontmatter only — no `## Human Review` section.
  Future<void> acknowledgeItem(String filename, {String? note}) async {
    final encoded = Uri.encodeComponent(filename);
    final body = <String, dynamic>{'action': 'acknowledge'};
    if (note != null && note.isNotEmpty) body['note'] = note;
    await _post('/api/inbox/$encoded/action', body: body);
  }

  /// Append a named section to an inbox item (file stays in inbox).
  Future<void> appendSection(
      String filename, String title, String content) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/inbox/$encoded/action',
        body: {'action': 'append-section', 'title': title, 'content': content});
  }

  /// Append an inline comment section to a document.
  ///
  /// The server appends at document end (no lineText). title: null suppresses
  /// the header. Content is formatted as a GFM alert with the selected text
  /// as a quoted Re: reference.
  Future<void> appendInlineSection(
    String path,
    String selectedText,
    String comment,
  ) async {
    // Parse path into folderId and fileId
    final parts = path.split('/');
    if (parts.length < 2) {
      throw AgentApiException(400, 'Invalid path format: $path');
    }
    final fileId = parts.last;
    final folderParts = parts.sublist(0, parts.length - 1);
    final folderId = folderParts.join('/');

    final encodedFolder = Uri.encodeComponent(folderId);
    final encodedFile = Uri.encodeComponent(fileId);

    // Format: GFM alert with Re: quoted reference and timestamp
    final timestamp = DateTime.now().toIso8601String();
    final content = '> [!NOTE] Sinh comment:\n> **Re:** "$selectedText"\n>\n> $comment\n>\n> _$timestamp"_';

    await _post(
      '/api/folders/$encodedFolder/files/$encodedFile/sections',
      body: {
        'title': null,
        'content': content,
      },
    );
  }

  /// Fetch feedback chip labels from server config.
  ///
  /// Returns empty list if config is missing or malformed.
  Future<List<String>> getFeedbackChips() async {
    final response = await _get('/api/config/feedback-chips');
    final chips = response['chips'] as List? ?? [];
    return chips.map((e) => e as String).toList();
  }

  // --- For Later ---

  /// List all for-later items with parsed metadata.
  Future<List<ReviewItem>> listForLater() async {
    final response = await _get('/api/folders/for-later');
    final items = response['items'] as List;
    return items
        .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single for-later item with full markdown content.
  Future<ReviewItem> getForLaterItem(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    final response = await _get('/api/folders/for-later/$encoded');
    return ReviewItem.fromJson(response);
  }

  // --- Deployments ---

  /// List recent deployments (last 3 days).
  ///
  /// When [ticketId] is provided, fetches all historical deployments for that
  /// ticket (no 3-day cutoff) — server-side filtering via PA-1147.
  /// When [ticketId] is null, returns last 3 days only (backward compatible).
  Future<List<Deployment>> listDeployments({String? ticketId}) async {
    String path = '/api/deployments';
    if (ticketId != null && ticketId.isNotEmpty) {
      path += '?ticket_id=${Uri.encodeComponent(ticketId)}';
    }
    final response = await _get(path);
    final deployments = response['deployments'] as List;
    final cutoff = DateTime.now().subtract(const Duration(days: 3));
    return deployments
        .map((e) => Deployment.fromJson(e as Map<String, dynamic>))
        .where((d) {
          final started = DateTime.tryParse(d.startedAt);
          return started != null && started.isAfter(cutoff);
        })
        .toList();
  }

  /// Fetch activity events for a deployment.
  ///
  /// Pass [since] (ISO-8601 timestamp) to fetch only events after that time.
  /// Returns events in chronological order.
  Future<List<ActivityEvent>> getDeploymentActivity(
    String id, {
    String? since,
  }) async {
    final params = since != null ? '?since=${Uri.encodeComponent(since)}' : '';
    final response = await _get('/api/deployments/$id/activity$params');
    // New servers return 'activity_events'; older servers return 'events'.
    final events = (response['activity_events'] ?? response['events']) as List;
    return events
        .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch detailed deployment info including all metadata + activity events.
  ///
  /// Calls GET /api/deployments/\<id> which returns a merged object with
  /// full deployment metadata and the activity_events array.
  Future<Deployment> getDeploymentDetail(String id) async {
    final response = await _get('/api/deployments/$id');
    // The response is the deployment object directly (not wrapped in a key).
    return Deployment.fromJson(response);
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
    final response = await _get('/api/folders/teams/$team/$folder');
    final items = response['items'] as List;
    return items
        .map((e) => TeamFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Read a file from a team folder (returns full content with metadata).
  Future<ReviewItem> getTeamFile(
      String team, String folder, String filename) async {
    final response = await _get('/api/folders/teams/$team/$folder/$filename');
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
    final response = await _get('/api/folders/sinh-inputs/$folder$query');
    final items = response['items'] as List;
    return items
        .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single item from a sinh-inputs folder with full markdown content.
  Future<ReviewItem> getFolderItem(String folder, String filename) async {
    final encoded = Uri.encodeComponent(filename);
    final response = await _get('/api/folders/sinh-inputs/$folder/$encoded');
    return ReviewItem.fromJson(response);
  }

  /// Re-queue an item from a resolved folder back to inbox/.
  ///
  /// Adds `requeued_from: <folder>` to YAML frontmatter and moves the file.
  Future<void> requeueItem(String folder, String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/sinh-inputs/$folder/$encoded/action',
        body: {'action': 'requeue'});
  }

  /// Archive an item from any folder by moving it to done/.
  Future<void> archiveItem(String folder, String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/sinh-inputs/$folder/$encoded/action',
        body: {'action': 'archive'});
  }

  /// Save an approved item for later (moves from approved/ to for-later/).
  ///
  /// Distinct from [saveForLater] which operates on inbox items.
  Future<void> saveApprovedForLater(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/sinh-inputs/approved/$encoded/action',
        body: {'action': 'save-for-later'});
  }

  /// Create a new idea in ideas/ folder.
  ///
  /// The generated file format matches `pa idea` CLI output exactly.
  Future<void> createIdea(CreateIdeaPayload payload) async {
    await _post('/api/ideas', body: payload.toJson());
  }

  /// Append a named section to an idea file.
  Future<void> appendToIdea(
      String filename, String title, String content) async {
    final encoded = Uri.encodeComponent(filename);
    await _post('/api/sinh-inputs/ideas/$encoded/action',
        body: {'action': 'append-section', 'title': title, 'content': content});
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
    final response = await _get('/api/folders/sinh-inputs/$folder$query');
    final items = (response['items'] as List)
        .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedFolderResult(
      items: items,
      total: response['total'] as int? ?? items.length,
      hasMore: response['hasMore'] as bool? ?? false,
    );
  }

  // --- Routing ---

  /// List agent team directories for the destination-team routing selector.
  ///
  /// Calls GET /api/agent-teams (added in Phase 1 routing work).
  /// Returns teams sorted alphabetically; each entry carries [AgentTeam.inboxExists].
  Future<List<AgentTeam>> listAgentTeams() async {
    final response = await _get('/api/agent-teams');
    final teams = response['teams'] as List;
    return teams
        .map((e) => AgentTeam.fromJson(e as Map<String, dynamic>))
        .toList();
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

  /// List available PA repos from the repos registry.
  ///
  /// Returns empty list if no repos.yaml configured — not an error.
  Future<List<PaRepo>> listPaRepos() async {
    final response = await _get('/api/pa-repos');
    final repos = response['repos'] as List;
    return repos
        .map((e) => PaRepo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch deploy routing — teams with non-interactive modes + repos.
  ///
  /// Calls GET /api/deploy-routing (added in PA-906).
  /// Server already filters out interactive modes.
  Future<DeployRouting> getDeployRouting() async {
    final response = await _get('/api/deploy-routing');
    return DeployRouting.fromJson(response);
  }

  /// Trigger a PA team deployment.
  ///
  /// Validates team + mode on the server before executing.
  /// Returns immediately after the subprocess is started.
  /// Optional [repo] passes `--repo <name>` to PA (for codebase-aware modes).
  /// Optional [ticket] links the deployment to a ticket in the registry.
  /// Optional [provider] selects the AI provider (anthropic, minimax).
  /// Optional [teamModel] selects the model (haiku, sonnet, opus).
  Future<DeployResult> triggerDeployment(
    String team,
    String mode, {
    String? objective,
    String? repo,
    String? ticket,
    String? provider,
    String? teamModel,
  }) async {
    final body = <String, dynamic>{'team': team, 'mode': mode};
    if (objective != null && objective.isNotEmpty) {
      body['objective'] = objective;
    }
    if (repo != null && repo.isNotEmpty) {
      body['repo'] = repo;
    }
    if (ticket != null && ticket.isNotEmpty) {
      body['ticket'] = ticket;
    }
    if (provider != null && provider.isNotEmpty) {
      body['provider'] = provider;
    }
    if (teamModel != null && teamModel.isNotEmpty) {
      body['team_model'] = teamModel;
    }
    final response = await _post('/api/deploy', body: body);
    return DeployResult.fromJson(response);
  }

  /// Fetch the merged list of categories from AvoConfig + task DB.
  ///
  /// Calls GET /api/config/categories (added in Phase 1 sync work).
  /// Returns sorted list; empty on failure.
  Future<List<String>> getCategories() async {
    final response = await _get('/api/config/categories');
    final cats = response['categories'] as List? ?? [];
    return cats.map((e) => e as String).toList();
  }

  /// Fetch comment chip presets for a specific category.
  ///
  /// Calls GET /api/config/category-chips?category=X
  /// Returns list of chip strings; empty on failure.
  Future<List<String>> getCategoryChips(String category) async {
    try {
      final response = await _get('/api/config/category-chips?category=${Uri.encodeComponent(category)}');
      final chips = response['chips'] as List? ?? [];
      return chips.map((e) => e as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch all category chip presets.
  ///
  /// Calls GET /api/config/category-chips
  /// Returns map of category -> list of chips; empty map on failure.
  Future<Map<String, List<String>>> getAllCategoryChips() async {
    try {
      final response = await _get('/api/config/category-chips');
      final chipsMap = response['categoryChips'] as Map<String, dynamic>? ?? {};
      return chipsMap.map((key, value) =>
          MapEntry(key, (value as List<dynamic>).map((e) => e as String).toList()));
    } catch (_) {
      return {};
    }
  }

  /// Add a chip preset to a category.
  ///
  /// Calls POST /api/config/category-chips with {"action": "add", "category": X, "chip": Y}
  /// Returns true on success.
  Future<bool> addCategoryChip(String category, String chip) async {
    try {
      await _post('/api/config/category-chips', body: {
        'action': 'add',
        'category': category,
        'chip': chip,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove a chip preset from a category.
  ///
  /// Calls POST /api/config/category-chips with {"action": "remove", "category": X, "chip": Y}
  /// Returns true on success.
  Future<bool> removeCategoryChip(String category, String chip) async {
    try {
      await _post('/api/config/category-chips', body: {
        'action': 'remove',
        'category': category,
        'chip': chip,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// List active PA systemd timers.
  Future<List<TimerInfo>> listTimers() async {
    final response = await _get('/api/timers');
    final timers = response['timers'] as List;
    return timers
        .map((e) => TimerInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Self-Update ---

  /// Triggers a self-update build (phone → server → APK push).
  ///
  /// POST /api/self-update → 2xx with {status: building, startedAt}
  /// Returns null on network error.
  Future<SelfUpdateResult?> triggerSelfUpdate() async {
    try {
      final json = await _post('/api/self-update');
      return SelfUpdateResult.fromJson(json);
    } catch (e) {
      debugPrint('[AgentApiClient] triggerSelfUpdate error: $e');
      return null;
    }
  }

  /// Gets the current self-update build status.
  ///
  /// GET /api/self-update/status → {status, log, startedAt, completedAt}
  /// Returns null on network error.
  Future<SelfUpdateStatus?> getSelfUpdateStatus() async {
    try {
      final json = await _get('/api/self-update/status');
      return SelfUpdateStatus.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // --- Repo Detail ---

  /// Fetch git info for a repository.
  ///
  /// GET /api/repos/:key/git-info → RepoGitInfo
  Future<RepoGitInfo> getRepoGitInfo(String key) async {
    final encoded = Uri.encodeComponent(key);
    final response = await _get('/api/repos/$encoded/git-info');
    return RepoGitInfo.fromJson(response);
  }

  /// Fetch deployments for a repository.
  ///
  /// GET /api/repos/\:key/deployments?status=X&limit=Y → List\<Deployment>
  Future<List<Deployment>> getRepoDeployments(
    String key, {
    String? status,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (limit != null) params['limit'] = '$limit';
    final encoded = Uri.encodeComponent(key);
    final query =
        params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    final response = await _get('/api/repos/$encoded/deployments$query');
    final deployments = response['deployments'] as List;
    return deployments
        .map((e) => Deployment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch branch list for a repository.
  ///
  /// GET /api/repos/:key/branches → RepoBranches
  Future<RepoBranches> getRepoBranches(String key) async {
    final encoded = Uri.encodeComponent(key);
    final response = await _get('/api/repos/$encoded/branches');
    return RepoBranches.fromJson(response);
  }

  /// Fetch commit history for a repository branch.
  ///
  /// GET /api/repos/:key/commits?branch=X&limit=Y&offset=Z → RepoCommits
  Future<RepoCommits> getRepoCommits(
    String key,
    String branch, {
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'branch': branch,
      'limit': '$limit',
      'offset': '$offset',
    };
    final encoded = Uri.encodeComponent(key);
    final query = '?${Uri(queryParameters: params).query}';
    final response = await _get('/api/repos/$encoded/commits$query');
    return RepoCommits.fromJson(response);
  }

  /// Fetch the diff for a specific commit.
  ///
  /// GET /api/repos/:key/diff?commit=<sha> → RepoDiff
  Future<RepoDiff> getRepoDiff(String key, String commitSha) async {
    final encoded = Uri.encodeComponent(key);
    final query = '?commit=${Uri.encodeComponent(commitSha)}';
    final response = await _get('/api/repos/$encoded/diff$query');
    return RepoDiff.fromJson(response);
  }

  // --- Tickets ---

  /// List available projects with full metadata.
  ///
  /// GET /api/projects → {"projects": [{key, prefix, description, path, activeTicketCount}, ...]}
  /// Filters to projects with activeTicketCount > 0 for the dropdown.
  /// Returns empty list on failure.
  ///
  /// Note: GET /api/ticket-projects is deprecated; this endpoint supersedes it.
  Future<List<TicketProject>> getProjects() async {
    try {
      final response = await _get('/api/projects');
      final projects = response['projects'] as List? ?? [];
      return projects
          .map((e) => TicketProject.fromJson(e as Map<String, dynamic>))
          .where((p) => p.activeTicketCount > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get the kanban board view for a project.
  ///
  /// GET /api/board?project=X&assignee=Y&excludeTags=backlog,archived&excludeTypes=fyi,work-report → {"board": {...}}
  /// Always excludes backlog/archived tickets and fyi/work-report types to match CLI defaults.
  Future<BoardView> getBoard({required String project, String? assignee}) async {
    final params = <String, String>{
      'project': project,
      'excludeTags': 'backlog,archived',
      'excludeTypes': 'fyi,work-report',
    };
    if (assignee != null) params['assignee'] = assignee;
    final query = '?${Uri(queryParameters: params).query}';
    final response = await _get('/api/board$query');
    return BoardView.fromJson(response['board'] as Map<String, dynamic>);
  }

  /// Get the GTD focus view — cross-project actionable items sorted by priority and staleness.
  ///
  /// GET /api/focus?enrich=true → FocusResult
  Future<FocusResult> getFocus({bool enrich = false}) async {
    final query = enrich ? '?enrich=true' : '';
    final response = await _get('/api/focus$query');
    return FocusResult.fromJson(response);
  }

  /// Get a single ticket by ID.
  ///
  /// GET /api/tickets/$id → {"ticket": {...}}
  Future<Ticket> getTicket(String id) async {
    final encoded = Uri.encodeComponent(id);
    final response = await _get('/api/tickets/$encoded');
    return Ticket.fromJson(response['ticket'] as Map<String, dynamic>);
  }

  /// List tickets with optional filters.
  ///
  /// GET /api/tickets?project=X&assignee=Y&status=Z → {"tickets": [...], "count": N}
  Future<List<Ticket>> listTickets({
    String? project,
    String? assignee,
    String? status,
    String? priority,
    String? type,
    String? tags,
    String? excludeTags,
    String? search,
  }) async {
    final params = <String, String>{};
    if (project != null) params['project'] = project;
    if (assignee != null) params['assignee'] = assignee;
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (type != null) params['type'] = type;
    if (tags != null) params['tags'] = tags;
    if (excludeTags != null) params['excludeTags'] = excludeTags;
    if (search != null) params['search'] = search;
    final query =
        params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    final response = await _get('/api/tickets$query');
    final tickets = response['tickets'] as List;
    return tickets
        .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get the backlog — tickets that are inactive.
  ///
  /// The backlog is the union of:
  /// - Tag-based backlog: tickets with 'backlog' tag
  /// - Status-based backlog: tickets with status in backlogStatuses
  ///
  /// Combines both queries and deduplicates by ticket ID.
  Future<List<Ticket>> getBacklog({
    String? project,
    String? assignee,
    String? priority,
    String? tags,
  }) async {
    // Tag-based backlog: tickets with 'backlog' tag
    final tagBased = await listTickets(
      project: project,
      assignee: assignee,
      priority: priority,
      tags: 'backlog',
    );

    // Status-based backlog: tickets in backlog statuses, excluding backlog/archived tags
    // (a ticket that has 'backlog' tag but also a backlog status is already captured above)
    final statusBased = await listTickets(
      project: project,
      assignee: assignee,
      priority: priority,
      tags: tags,
      excludeTags: 'backlog,archived',
      status: backlogStatuses.join(','),
    );

    // Combine and deduplicate by ticket ID
    final Map<String, Ticket> byId = {};
    for (final t in tagBased) {
      byId[t.id] = t;
    }
    for (final t in statusBased) {
      byId[t.id] = t;
    }

    return byId.values.toList();
  }

  /// Create a new ticket.
  ///
  /// POST /api/tickets body=data → {"ticket": {...}} (201)
  Future<Ticket> createTicket(Map<String, dynamic> data) async {
    final response = await _post('/api/tickets', body: data);
    return Ticket.fromJson(response['ticket'] as Map<String, dynamic>);
  }

  /// Update an existing ticket.
  ///
  /// PATCH /api/tickets/$id body=updates → {"ticket": {...}}
  Future<Ticket> updateTicket(String id, Map<String, dynamic> updates) async {
    final encoded = Uri.encodeComponent(id);
    final response = await _patch('/api/tickets/$encoded', body: updates);
    return Ticket.fromJson(response['ticket'] as Map<String, dynamic>);
  }

  /// Add a comment to a ticket.
  ///
  /// POST /api/tickets/:id/comments body={content, author} → {"ticket": {...}}
  Future<Ticket> addComment(
      String ticketId, String content, String author) async {
    final encoded = Uri.encodeComponent(ticketId);
    final response = await _post(
      '/api/tickets/$encoded/comments',
      body: {'content': content, 'author': author},
    );
    return Ticket.fromJson(response['ticket'] as Map<String, dynamic>);
  }

  /// Edit a comment on a ticket.
  ///
  /// PATCH /api/tickets/:id/comments/:commentId body={content, actor} → {"ticket": {...}}
  Future<Ticket> editComment(
      String ticketId, String commentId, String content, String actor) async {
    final encodedId = Uri.encodeComponent(ticketId);
    final encodedComment = Uri.encodeComponent(commentId);
    final response = await _patch(
      '/api/tickets/$encodedId/comments/$encodedComment',
      body: {'content': content, 'actor': actor},
    );
    return Ticket.fromJson(response['ticket'] as Map<String, dynamic>);
  }

  /// Delete a comment from a ticket.
  ///
  /// DELETE /api/tickets/:id/comments/:commentId body={actor} → {"success": true}
  Future<void> deleteComment(
      String ticketId, String commentId, String actor) async {
    final encodedId = Uri.encodeComponent(ticketId);
    final encodedComment = Uri.encodeComponent(commentId);
    await _delete(
      '/api/tickets/$encodedId/comments/$encodedComment',
      body: {'actor': actor},
    );
  }

  /// Move a ticket to a different project.
  ///
  /// POST /api/tickets/:id/move body={'project': targetProject, 'actor': actor?} → {'ticket': {...}}
  /// Returns the newly created ticket with its new ID.
  Future<Ticket> moveTicket(String id, String targetProject, {String? actor}) async {
    final encoded = Uri.encodeComponent(id);
    final body = <String, dynamic>{'project': targetProject};
    if (actor != null) body['actor'] = actor;
    final response = await _post('/api/tickets/$encoded/move', body: body);
    return Ticket.fromJson(response['ticket'] as Map<String, dynamic>);
  }

  /// Upload an image attachment to a ticket.
  ///
  /// POST /api/tickets/:id/attachments/upload with multipart form containing 'file' field.
  /// Returns the doc_ref string for the uploaded attachment.
  Future<String> uploadAttachment(
    String ticketId,
    XFile image, {
    void Function(double)? onProgress,
  }) async {
    final encodedId = Uri.encodeComponent(ticketId);
    final uri = Uri.parse('$baseUrl/api/tickets/$encodedId/attachments/upload');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders);

    // Add the file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
        filename: image.name,
      ),
    );

    // Send and stream response
    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(
        const Duration(minutes: 5),
      );
    } catch (e) {
      throw AgentApiException(0, _networkErrorMessage(e));
    }
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiException(response.statusCode, response.body);
    }

    // Parse response: {"docRef": "attachments/<ticket-id>/<filename>"}
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final docRef = json['docRef'] as String?;
    if (docRef == null || docRef.isEmpty) {
      throw AgentApiException(500, 'No docRef in upload response: ${response.body}');
    }
    return docRef;
  }

  // --- Documents ---

  /// Fetch a document or directory listing from the PA file system.
  ///
  /// GET /api/documents?path=`<path>`
  /// Returns file content (markdown, text, etc.) or a directory listing.
  Future<DocumentContent> getDocument(String path) async {
    final encoded = Uri.encodeComponent(path);
    final response = await _get('/api/documents?path=$encoded');
    return DocumentContent.fromJson(response);
  }

  /// Fetch raw image bytes from pa-serve.
  ///
  /// GET /api/images?path=<encoded>
  /// Returns image binary bytes. Throws on non-200 response.
  Future<List<int>> getImageBytes(String path) async {
    final encoded = Uri.encodeComponent(path);
    final uri = Uri.parse('$baseUrl/api/images?path=$encoded');
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AgentApiException(0, _networkErrorMessage(e));
    }
    if (response.statusCode != 200) {
      _throwApiException(response.statusCode, response.body);
    }
    return response.bodyBytes;
  }

  // --- Bulletins ---

  /// List all bulletins.
  ///
  /// GET /api/bulletin → {"bulletins": [...], "count": N}
  Future<List<Bulletin>> getBulletins() async {
    final response = await _get('/api/bulletin');
    final bulletins = response['bulletins'] as List;
    return bulletins
        .map((e) => Bulletin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new bulletin.
  ///
  /// POST /api/bulletin body=data → {"bulletin": {...}} (201)
  Future<Bulletin> createBulletin(Map<String, dynamic> data) async {
    final response = await _post('/api/bulletin', body: data);
    return Bulletin.fromJson(response['bulletin'] as Map<String, dynamic>);
  }

  /// Resolve (dismiss) a bulletin.
  ///
  /// PATCH /api/bulletin/$id body={"status": "resolved"} → {"success": true}
  Future<void> resolveBulletin(String id) async {
    final encoded = Uri.encodeComponent(id);
    await _patch('/api/bulletin/$encoded', body: {'status': 'resolved'});
  }

  // --- Sessions ---

  /// List all active sessions registered with the SessionManager.
  ///
  /// GET /api/sessions → SessionRecord[]
  Future<List<SessionRecord>> listSessions() async {
    final uri = Uri.parse('$baseUrl/api/sessions');
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AgentApiException(0, _networkErrorMessage(e));
    }
    if (response.statusCode != 200) {
      _throwApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Some servers may wrap in {"sessions": [...]}
    final items = (decoded as Map<String, dynamic>)['sessions'] as List? ?? [];
    return items
        .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Register a deploy session.
  ///
  /// POST /api/sessions body={deploymentId, model?} → {sessionId, deploymentId, model?, status}
  Future<Map<String, dynamic>> createSession({
    required String deploymentId,
    String? model,
  }) async {
    final body = <String, dynamic>{'deploymentId': deploymentId};
    if (model != null) body['model'] = model;
    return await _post('/api/sessions', body: body);
  }

  /// Stop a session by id.
  ///
  /// POST /api/sessions/:id/stop → {status: "stopped"}
  Future<void> stopSession(String id) async {
    final encoded = Uri.encodeComponent(id);
    await _post('/api/sessions/$encoded/stop');
  }

  // --- Repo Browsing (additional) ---

  /// Fetch a lightweight git summary for all configured repos.
  ///
  /// GET /api/repos/git-summary → GitSummary
  Future<GitSummary> getRepoGitSummary() async {
    final response = await _get('/api/repos/git-summary');
    return GitSummary.fromJson(response);
  }

  /// List remote-tracking branches for a repo.
  ///
  /// GET /api/repos/:key/branches/remote → RepoRemoteBranches
  Future<RepoRemoteBranches> getRepoRemoteBranches(String key) async {
    final encoded = Uri.encodeComponent(key);
    final response = await _get('/api/repos/$encoded/branches/remote');
    return RepoRemoteBranches.fromJson(response);
  }

  /// Compare two refs (branches or tags) and return the paginated commit list.
  ///
  /// GET /api/repos/:key/compare?from=X&to=Y&limit=N&offset=M → RepoCompare
  Future<RepoCompare> getRepoCompare(
    String key,
    String from,
    String to, {
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'from': from,
      'to': to,
      'limit': '$limit',
      'offset': '$offset',
    };
    final encoded = Uri.encodeComponent(key);
    final query = '?${Uri(queryParameters: params).query}';
    final response = await _get('/api/repos/$encoded/compare$query');
    return RepoCompare.fromJson(response);
  }

  // --- Deploy Control & Status ---

  /// Query the status of a deployment.
  ///
  /// GET /api/deploy/status/:id → {status: DeploymentStatus}
  Future<Map<String, dynamic>> getDeployStatus(String id) async {
    final encoded = Uri.encodeComponent(id);
    return await _get('/api/deploy/status/$encoded');
  }

  /// Return the raw registry event log for a deployment.
  ///
  /// GET /api/deploy/events/:id → {events: [RegistryEvent]}
  Future<List<Map<String, dynamic>>> getDeployEvents(String id) async {
    final encoded = Uri.encodeComponent(id);
    final response = await _get('/api/deploy/events/$encoded');
    final events = response['events'] as List? ?? [];
    return events
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Emit a `started` registry event for a deployment.
  ///
  /// POST /api/deploy/start body={deploymentId, team, ...}
  Future<void> emitDeployStart({
    required String deploymentId,
    required String team,
    String? primer,
    List<String>? agents,
    String? ticketId,
    String? objective,
    String? provider,
    String? repo,
  }) async {
    final body = <String, dynamic>{
      'deploymentId': deploymentId,
      'team': team,
    };
    if (primer != null) body['primer'] = primer;
    if (agents != null) body['agents'] = agents;
    if (ticketId != null) body['ticketId'] = ticketId;
    if (objective != null) body['objective'] = objective;
    if (provider != null) body['provider'] = provider;
    if (repo != null) body['repo'] = repo;
    await _post('/api/deploy/start', body: body);
  }

  /// Emit a `pid` registry event.
  ///
  /// POST /api/deploy/pid body={deploymentId, team, pid}
  Future<void> emitDeployPid({
    required String deploymentId,
    required String team,
    required int pid,
  }) async {
    await _post('/api/deploy/pid', body: {
      'deploymentId': deploymentId,
      'team': team,
      'pid': pid,
    });
  }

  /// Emit a `completed` registry event.
  ///
  /// POST /api/deploy/complete body={deploymentId, team, status?, summary?, ...}
  Future<void> emitDeployComplete({
    required String deploymentId,
    required String team,
    String? status,
    String? summary,
    String? logFile,
    int? exitCode,
    bool? fallback,
  }) async {
    final body = <String, dynamic>{
      'deploymentId': deploymentId,
      'team': team,
    };
    if (status != null) body['status'] = status;
    if (summary != null) body['summary'] = summary;
    if (logFile != null) body['logFile'] = logFile;
    if (exitCode != null) body['exitCode'] = exitCode;
    if (fallback != null) body['fallback'] = fallback;
    await _post('/api/deploy/complete', body: body);
  }

  /// Emit a `crashed` registry event.
  ///
  /// POST /api/deploy/crash body={deploymentId, team, error?, exitCode?}
  Future<void> emitDeployCrash({
    required String deploymentId,
    required String team,
    String? error,
    int? exitCode,
  }) async {
    final body = <String, dynamic>{
      'deploymentId': deploymentId,
      'team': team,
    };
    if (error != null) body['error'] = error;
    if (exitCode != null) body['exitCode'] = exitCode;
    await _post('/api/deploy/crash', body: body);
  }

  /// Emit an `amended` registry event to update a completed deployment.
  ///
  /// POST /api/deploy/amend body={deploymentId, team, note?, status?, summary?}
  Future<void> emitDeployAmend({
    required String deploymentId,
    required String team,
    String? note,
    String? status,
    String? summary,
  }) async {
    final body = <String, dynamic>{
      'deploymentId': deploymentId,
      'team': team,
    };
    if (note != null) body['note'] = note;
    if (status != null) body['status'] = status;
    if (summary != null) body['summary'] = summary;
    await _post('/api/deploy/amend', body: body);
  }

  // --- Skills ---

  /// Return the full skill registry report.
  ///
  /// GET /api/skills → {generatedAt, scannedRoots, inventory, issues, openCodeVisibility}
  Future<Map<String, dynamic>> getSkills() async {
    return await _get('/api/skills');
  }

  // --- Knowledge ---

  /// List knowledge boundaries (item types and their storage locations).
  ///
  /// GET /api/knowledge-boundaries → {boundaries: [KnowledgeBoundary]}
  Future<List<KnowledgeBoundary>> getKnowledgeBoundaries() async {
    final response = await _get('/api/knowledge-boundaries');
    final boundaries = response['boundaries'] as List? ?? [];
    return boundaries
        .map((e) => KnowledgeBoundary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// List improvement candidates aggregated from session logs.
  ///
  /// GET /api/improvement-candidates → {candidates: [ImprovementCandidate]}
  Future<List<ImprovementCandidate>> getImprovementCandidates() async {
    final response = await _get('/api/improvement-candidates');
    final candidates = response['candidates'] as List? ?? [];
    return candidates
        .map((e) =>
            ImprovementCandidate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Dashboard Views ---

  /// Fetch aggregate counts for the dashboard.
  ///
  /// GET /api/dashboard/overview → DashboardOverview
  Future<DashboardOverview> getDashboardOverview() async {
    final response = await _get('/api/dashboard/overview');
    return DashboardOverview.fromJson(response);
  }

  /// Fetch up to 200 deployment status records for the dashboard.
  ///
  /// GET /api/dashboard/views/deployments → DashboardDeployments
  Future<DashboardDeployments> getDashboardDeployments() async {
    final response = await _get('/api/dashboard/views/deployments');
    return DashboardDeployments.fromJson(response);
  }

  /// Fetch up to 500 tickets for the dashboard.
  ///
  /// GET /api/dashboard/views/tickets → DashboardTickets
  Future<DashboardTickets> getDashboardTickets() async {
    final response = await _get('/api/dashboard/views/tickets');
    return DashboardTickets.fromJson(response);
  }

  /// Fetch up to 250 skill inventory entries for the dashboard.
  ///
  /// GET /api/dashboard/views/skills → DashboardSkills
  Future<DashboardSkills> getDashboardSkills() async {
    final response = await _get('/api/dashboard/views/skills');
    return DashboardSkills.fromJson(response);
  }

  /// Fetch knowledge boundaries for the dashboard.
  ///
  /// GET /api/dashboard/views/knowledge-memory → DashboardKnowledgeMemory
  Future<DashboardKnowledgeMemory> getDashboardKnowledgeMemory() async {
    final response = await _get('/api/dashboard/views/knowledge-memory');
    return DashboardKnowledgeMemory.fromJson(response);
  }

  /// Fetch up to 500 improvement candidates for the dashboard.
  ///
  /// GET /api/dashboard/views/improvement-candidates → DashboardImprovementCandidates
  Future<DashboardImprovementCandidates>
      getDashboardImprovementCandidates() async {
    final response =
        await _get('/api/dashboard/views/improvement-candidates');
    return DashboardImprovementCandidates.fromJson(response);
  }

  /// Fetch OpenCode integration metadata for the dashboard.
  ///
  /// GET /api/dashboard/views/opencode-integration → DashboardOpencodeIntegration
  Future<DashboardOpencodeIntegration>
      getDashboardOpencodeIntegration() async {
    final response =
        await _get('/api/dashboard/views/opencode-integration');
    return DashboardOpencodeIntegration.fromJson(response);
  }

  // --- Health ---

  /// Health probe — returns true when pa-platform is reachable.
  ///
  /// GET /api/health → {status: "ok"}
  Future<bool> checkHealth() async {
    try {
      await _get('/api/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Ticket Review ---

  /// Fetch a ticket together with enriched doc_refs for review.
  ///
  /// GET /api/tickets/:id/review → {ticket, doc_refs}
  Future<TicketReviewResult> getTicketReview(String id) async {
    final encoded = Uri.encodeComponent(id);
    final response = await _get('/api/tickets/$encoded/review');
    return TicketReviewResult.fromJson(response);
  }

  // --- HTTP helpers ---

  Future<Map<String, dynamic>> _get(String path) async {
    http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$baseUrl$path'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AgentApiException(0, _networkErrorMessage(e));
    }
    if (response.statusCode != 200) {
      _throwApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path,
      {Map<String, dynamic>? body}) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json', ..._authHeaders},
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AgentApiException(0, _networkErrorMessage(e));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patch(String path,
      {Map<String, dynamic>? body}) async {
    http.Response response;
    try {
      response = await _client
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json', ..._authHeaders},
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AgentApiException(0, _networkErrorMessage(e));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path,
      {Map<String, dynamic>? body}) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl$path'));
    request.headers['Content-Type'] = 'application/json';
    request.headers.addAll(_authHeaders);
    if (body != null) request.body = jsonEncode(body);
    http.StreamedResponse streamed;
    try {
      streamed =
          await _client.send(request).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AgentApiException(0, _networkErrorMessage(e));
    }
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiException(response.statusCode, response.body);
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Never _throwApiException(int statusCode, String rawBody) {
    try {
      final json = jsonDecode(rawBody) as Map<String, dynamic>;
      throw AgentApiException(
        statusCode,
        json['error'] as String? ?? rawBody,
        json['code'] as String? ?? '',
      );
    } on AgentApiException {
      rethrow;
    } catch (_) {
      throw AgentApiException(statusCode, rawBody);
    }
  }

  /// Build a user-facing error message for network failures (connection
  /// refused, timeout, DNS). The caller wraps this in an [AgentApiException]
  /// with status code 0 so the UI can distinguish network errors from HTTP
  /// errors.
  String _networkErrorMessage(Object error) {
    final detail = error.toString();
    if (detail.contains('Connection refused') ||
        detail.contains('Failed host lookup') ||
        detail.contains('Connection terminated') ||
        detail.contains('Connection closed') ||
        detail.contains('TimeoutException') ||
        detail.contains('SocketException') ||
        detail.contains('HandshakeException')) {
      return 'pa-platform is not running at $baseUrl. '
          'Start it with `pa-core serve`.';
    }
    return 'Could not reach pa-platform at $baseUrl: $detail';
  }

  void dispose() {
    _client.close();
  }
}

class AgentApiException implements Exception {
  final int statusCode;
  final String message;
  final String code;

  AgentApiException(this.statusCode, this.message, [this.code = '']);

  @override
  String toString() => 'AgentApiException($statusCode/$code): $message';
}

/// Result type for document fetch (file content or directory listing).
class DocumentContent {
  final String path;
  final String type; // 'file' | 'directory'
  final String? content; // text content for files (markdown, plain text)
  final String? mimeType; // e.g. 'text/markdown', 'application/pdf'
  final List<String>? entries; // directory entry names

  const DocumentContent({
    required this.path,
    required this.type,
    this.content,
    this.mimeType,
    this.entries,
  });

  factory DocumentContent.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'] as List?;
    return DocumentContent(
      path: json['path'] as String? ?? '',
      type: json['type'] as String? ?? 'file',
      content: json['content'] as String?,
      mimeType: json['mimeType'] as String?,
      entries: entriesRaw?.map((e) => e as String).toList(),
    );
  }
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

/// Result of triggering a self-update build.
class SelfUpdateResult {
  final String status;
  final DateTime? startedAt;

  const SelfUpdateResult({required this.status, this.startedAt});

  factory SelfUpdateResult.fromJson(Map<String, dynamic> json) {
    return SelfUpdateResult(
      status: json['status'] as String? ?? 'unknown',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
    );
  }
}

/// Current self-update build status.
class SelfUpdateStatus {
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> log;

  const SelfUpdateStatus({
    required this.status,
    this.startedAt,
    this.completedAt,
    this.log = const [],
  });

  factory SelfUpdateStatus.fromJson(Map<String, dynamic> json) {
    return SelfUpdateStatus(
      status: json['status'] as String? ?? 'idle',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      log: (json['log'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  bool get isBuilding => status == 'building';
  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';
  bool get isIdle => status == 'idle';
}

/// Result of GET /api/tickets/:id/review — ticket with enriched doc_refs.
class TicketReviewResult {
  final Ticket ticket;
  final List<ReviewDocRef> docRefs;

  const TicketReviewResult({required this.ticket, required this.docRefs});

  factory TicketReviewResult.fromJson(Map<String, dynamic> json) {
    final ticketJson = json['ticket'] as Map<String, dynamic>;
    final docRefsRaw = json['doc_refs'] as List? ?? [];
    return TicketReviewResult(
      ticket: Ticket.fromJson(ticketJson),
      docRefs: docRefsRaw
          .map((e) => ReviewDocRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A doc_ref with resolved URL and title, returned by the review endpoint.
class ReviewDocRef {
  final String path;
  final String? type;
  final String url;
  final String title;

  const ReviewDocRef({
    required this.path,
    this.type,
    required this.url,
    required this.title,
  });

  factory ReviewDocRef.fromJson(Map<String, dynamic> json) {
    return ReviewDocRef(
      path: json['path'] as String? ?? '',
      type: json['type'] as String?,
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}
