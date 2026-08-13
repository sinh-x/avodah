/// Session service for managing opencode sessions from the Avodah CLI.
///
/// Calls the pa-platform Agent API (`POST /api/deploy`, `GET /api/sessions`,
/// `POST /api/sessions/:id/stop`) instead of spawning `opa deploy`
/// subprocesses and parsing `registry.jsonl` directly.
///
/// Phase 3 deliverable for AVO-117 (pa-platform API integration). The
/// service layer owns all HTTP communication; CLI commands consume the
/// typed results without touching [Process] or the registry file.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Summary of a single session returned by `GET /api/sessions`.
///
/// Thin projection over the pa-platform `SessionRecord` shape with the
/// fields the `avo session list` command surfaces. Kept as an immutable
/// value type so callers (including tests) can construct expected values
/// without touching the API.
class SessionSummary {
  /// Session id assigned by the `SessionManager` (e.g. `s<base36>-<n>`).
  final String sessionId;

  /// Deployment id linked to this session (e.g. `d-<hex6>`).
  final String deploymentId;

  /// Model used by the session (e.g. `ollama-cloud/deepseek-v4-pro`).
  final String model;

  /// Session status (`running`, `stopping`).
  final String status;

  /// ISO-8601 timestamp the session was started.
  final String startedAt;

  const SessionSummary({
    required this.sessionId,
    required this.deploymentId,
    required this.model,
    required this.status,
    required this.startedAt,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionId: json['id'] as String? ?? '',
      deploymentId: json['deploymentId'] as String? ?? '',
      model: json['model'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startedAt: json['startedAt'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'SessionSummary($sessionId, deployment=$deploymentId, '
      'model=$model, status=$status, startedAt=$startedAt)';
}

/// Result of a `startSession` attempt.
class StartSessionResult {
  /// Deployment ID returned by `POST /api/deploy`.
  ///
  /// Empty string when the deploy failed or no deployment id was returned.
  final String deploymentId;

  /// Status returned by the deploy API: `success`, `pending`, or `failed`.
  final String status;

  /// Human-readable error message when [deploymentId] is empty.
  final String? error;

  const StartSessionResult({
    required this.deploymentId,
    required this.status,
    this.error,
  });

  bool get succeeded => deploymentId.isNotEmpty && status != 'failed';
}

/// Handle to a deployment's runtime state, used by the attach command.
class SessionHandle {
  final String deploymentId;
  final String? sessionId;
  final String status;
  final String deployDir;
  final String activityLogPath;

  const SessionHandle({
    required this.deploymentId,
    required this.sessionId,
    required this.status,
    required this.deployDir,
    required this.activityLogPath,
  });
}

/// Thrown when the pa-platform Agent API is unreachable (not running, wrong
/// port, or connection refused). Carries a user-facing message so the CLI
/// can surface a clear error instead of a raw stack trace.
class PaPlatformUnavailableException implements Exception {
  final String message;

  PaPlatformUnavailableException(this.message);

  @override
  String toString() => message;
}

/// Outcome of `stopSession`.
class StopSessionResult {
  /// The session id (or deployment id) the caller requested to stop.
  final String id;
  final bool stopped;
  final String? error;

  /// HTTP status code from the stop attempt. Null on network errors. Used
  /// internally to decide whether to retry via [SessionService.listSessions]
  /// (only on 404).
  final int? statusCode;

  const StopSessionResult({
    required this.id,
    required this.stopped,
    this.error,
    this.statusCode,
  });
}

/// Internal subclass that carries the HTTP status code from a stop attempt.
class _StopSessionResultWithStatus extends StopSessionResult {
  _StopSessionResultWithStatus({
    required super.id,
    required super.stopped,
    super.error,
    required int statusCode,
  }) : super(statusCode: statusCode);
}

/// Business logic for `avo session …` subcommands.
///
/// All HTTP access goes through an injectable [http.Client] so the service
/// is testable without a running pa-platform. The default constructor
/// resolves the API base URL from the `AGENT_API_URL` environment variable
/// (matching the sync server convention) and the ai-usage tree from `HOME`.
class SessionService {
  /// Base URL of the pa-platform Agent API (e.g. `http://localhost:9848`).
  final String apiBaseUrl;

  /// Base path of the ai-usage tree (used to locate deploy dirs and session
  /// logs).
  final String aiUsagePath;

  /// Path to `registry.jsonl` — used only by the attach runner for exit
  /// detection. Phase 4 will replace this with API-based polling.
  final String registryPath;

  /// HTTP client used for all API calls. Injectable for tests.
  final http.Client httpClient;

  SessionService({
    String? apiBaseUrl,
    String? aiUsagePath,
    String? registryPath,
    http.Client? httpClient,
  })  : apiBaseUrl = (apiBaseUrl ??
                Platform.environment['AGENT_API_URL'] ??
                'http://localhost:9848')
            .replaceAll(RegExp(r'/+$'), ''),
        aiUsagePath = aiUsagePath ??
            p.join(Platform.environment['HOME'] ?? '/home', 'Documents',
                'ai-usage'),
        registryPath = registryPath ??
            p.join(Platform.environment['HOME'] ?? '/home', 'Documents',
                'ai-usage', 'deployments', 'registry.jsonl'),
        httpClient = httpClient ?? http.Client();

  /// Probe the pa-platform Agent API health endpoint.
  ///
  /// Returns `true` when pa-platform is reachable and reports
  /// `{"status":"ok"}`, `false` on any network error or non-200 response.
  /// Use this before long-running operations to fail fast with a clear
  /// message instead of letting the first API call hang or crash.
  Future<bool> checkHealth() async {
    try {
      final response =
          await httpClient.get(Uri.parse('$apiBaseUrl/api/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// List all active sessions via `GET /api/sessions`.
  ///
  /// Returns an empty list when pa-platform returns no sessions. Throws an
  /// [Exception] on network errors or non-200 responses so the CLI command
  /// can surface a clear error message.
  Future<List<SessionSummary>> listSessions() async {
    http.Response response;
    try {
      response =
          await httpClient.get(Uri.parse('$apiBaseUrl/api/sessions'));
    } catch (e) {
      throw PaPlatformUnavailableException(
          'pa-platform is not running at $apiBaseUrl. '
          'Start it with `pa-core serve`. ($e)');
    }
    if (response.statusCode != 200) {
      throw Exception(
          'GET /api/sessions returned ${response.statusCode}: ${response.body}');
    }
    final body = jsonDecode(response.body);
    // The pa-platform returns a bare JSON array. Some proxies may wrap in
    // {"sessions": [...]}; handle both shapes defensively.
    List<dynamic> items;
    if (body is List) {
      items = body;
    } else if (body is Map<String, dynamic> && body['sessions'] is List) {
      items = body['sessions'] as List;
    } else {
      items = [];
    }
    return items
        .map((e) => SessionSummary.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Extract the deployment id from a pa-platform deploy response,
  /// accepting both the canonical snake_case key `deployment_id` and the
  /// camelCase variant `deploymentId`.
  ///
  /// The pa-platform `POST /api/deploy` route normalises the key to
  /// `deployment_id` (snake_case), but some intermediate proxies or older
  /// clients may emit `deploymentId`. This helper reads the canonical key
  /// first and falls back to the camelCase variant so callers do not need to
  /// duplicate the fallback logic.
  ///
  /// Returns the deployment id string, or an empty string when neither key is
  /// present or the value is not a string.
  static String extractDeploymentId(Map<String, dynamic> json) {
    final v = json['deployment_id'];
    if (v is String && v.isNotEmpty) return v;
    final alt = json['deploymentId'];
    if (alt is String && alt.isNotEmpty) return alt;
    return '';
  }

  /// Trigger a deployment via `POST /api/deploy`.
  ///
  /// The pa-platform spawns the `opa deploy` subprocess server-side and
  /// auto-registers the session via `POST /api/sessions` (handled by the
  /// deploy-control route). This method does **not** spawn any subprocess
  /// locally — no `Process.start`, no `Process` handle.
  ///
  /// [extraArgs] are parsed for `--ticket`, `--objective`, `--repo`, and
  /// `--provider` flags and forwarded as fields in the JSON body.
  Future<StartSessionResult> startSession(
    String team,
    String mode, {
    List<String> extraArgs = const [],
  }) async {
    final body = _buildDeployBody(team, mode, extraArgs);
    http.Response response;
    try {
      response = await httpClient.post(
        Uri.parse('$apiBaseUrl/api/deploy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      return StartSessionResult(
        deploymentId: '',
        status: 'failed',
        error: 'pa-platform is not running at $apiBaseUrl. '
            'Start it with `pa-core serve`. ($e)',
      );
    }

    // POST /api/deploy should return 202 on success (per the phone contract).
    // Guard against non-2xx responses and malformed JSON bodies so the CLI
    // never crashes on an unexpected server response (NFR5/AC9). Mirrors the
    // try/catch + status-code pattern already used in [_stopById].
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['error'] as String? ?? body['reason'] as String?;
      } catch (_) {}
      final snippet = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
      return StartSessionResult(
        deploymentId: '',
        status: 'failed',
        error: message ??
            'Deploy failed (HTTP ${response.statusCode}): $snippet',
      );
    }

    Map<String, dynamic> result;
    try {
      result = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return StartSessionResult(
        deploymentId: '',
        status: 'failed',
        error: 'Deploy returned non-JSON response (HTTP '
            '${response.statusCode}): $e',
      );
    }
    final status = result['status'] as String? ?? 'failed';
    final deploymentId = extractDeploymentId(result);
    if (status == 'failed' || deploymentId.isEmpty) {
      return StartSessionResult(
        deploymentId: '',
        status: 'failed',
        error: result['reason'] as String? ?? 'Deploy failed',
      );
    }
    return StartSessionResult(
      deploymentId: deploymentId,
      status: status,
    );
  }

  /// Stop a session via `POST /api/sessions/:id/stop`.
  ///
  /// Accepts either a session id (e.g. `s<base36>-<n>`) or a deployment id
  /// (e.g. `d-<hex6>`). When a deployment id is passed, the method looks
  /// up the matching session via `GET /api/sessions` first.
  Future<StopSessionResult> stopSession(String id) async {
    // Try the id directly first — it may be a session id.
    final direct = await _stopById(id);
    if (direct.stopped) return direct;
    // Only retry via listSessions when the direct stop returned 404 (the
    // id was not a valid session id). Network errors and other failures
    // should not trigger a second API call.
    if (direct.statusCode != 404) return direct;
    // The id may be a deployment id — look up the session record and retry.
    final sessions = await listSessions();
    final match = sessions.where((s) => s.deploymentId == id).firstOrNull;
    if (match == null) {
      return StopSessionResult(
        id: id,
        stopped: false,
        error: direct.error ?? 'No session found for $id',
      );
    }
    return _stopById(match.sessionId);
  }

  Future<StopSessionResult> _stopById(String sessionId) async {
    http.Response response;
    try {
      response = await httpClient.post(
        Uri.parse('$apiBaseUrl/api/sessions/$sessionId/stop'),
      );
    } catch (e) {
      return StopSessionResult(
        id: sessionId,
        stopped: false,
        error: 'pa-platform is not running at $apiBaseUrl. '
            'Start it with `pa-core serve`. ($e)',
      );
    }
    if (response.statusCode == 200) {
      return StopSessionResult(id: sessionId, stopped: true);
    }
    String? message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String?;
    } catch (_) {}
    return _StopSessionResultWithStatus(
      id: sessionId,
      stopped: false,
      error: message ?? 'Stop returned ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  /// Resolve the deploy directory and session metadata for [deploymentId].
  ///
  /// Used by the attach command to locate the live `activity.jsonl` event
  /// stream. Returns null when no active session matches the deployment id.
  Future<SessionHandle?> findSession(String deploymentId) async {
    final sessions = await listSessions();
    final match = sessions
        .where((s) => s.deploymentId == deploymentId)
        .firstOrNull;
    if (match == null) return null;
    final deployDir = p.join(aiUsagePath, 'deployments', deploymentId);
    return SessionHandle(
      deploymentId: deploymentId,
      sessionId: match.sessionId,
      status: match.status,
      deployDir: deployDir,
      activityLogPath: p.join(deployDir, 'activity.jsonl'),
    );
  }

  /// Locate the session conversation log file for [deploymentId].
  ///
  /// Session logs live under `~/Documents/ai-usage/sessions/YYYY/MM/` and are
  /// typically nested one level deeper under a team subfolder such as
  /// `agent-team/`. Filenames are of the form
  /// `YYYY-MM-DD-<deploymentId>-….md`. We scan the current month and the
  /// previous month (rolling window) recursively and return the first match.
  /// Returns null when no log is found.
  ///
  /// [atReference] may be supplied (mainly by tests) to anchor the search
  /// clock; defaults to [DateTime.now].
  File? getSessionLog(String deploymentId, {DateTime? atReference}) {
    final anchor = atReference ?? DateTime.now();
    final candidates = <String>[];
    for (final offset in [0, 1]) {
      final dt = DateTime(anchor.year, anchor.month - offset);
      final dir = p.join(aiUsagePath, 'sessions',
          dt.year.toString(), dt.month.toString().padLeft(2, '0'));
      candidates.add(dir);
    }
    for (final dir in candidates) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      // Recursive listing so the team subfolder (e.g. `agent-team/`) is
      // covered without hard-coding its name.
      for (final entry in d.listSync(followLinks: false, recursive: true)) {
        if (entry is File && p.basename(entry.path).contains(deploymentId)) {
          return entry;
        }
      }
    }
    return null;
  }

  /// Build the JSON body for `POST /api/deploy` from team, mode, and
  /// extraArgs. Parses `--ticket`, `--objective`, `--repo`, and `--provider`
  /// flags from [extraArgs].
  Map<String, dynamic> _buildDeployBody(
      String team, String mode, List<String> extraArgs) {
    final body = <String, dynamic>{'team': team, 'mode': mode};
    for (var i = 0; i < extraArgs.length; i++) {
      final arg = extraArgs[i];
      if (i + 1 >= extraArgs.length) break;
      final value = extraArgs[i + 1];
      switch (arg) {
        case '--ticket':
          body['ticket'] = value;
          i++;
          break;
        case '--objective':
          body['objective'] = value;
          i++;
          break;
        case '--repo':
          body['repo'] = value;
          i++;
          break;
        case '--provider':
          body['provider'] = value;
          i++;
          break;
      }
    }
    return body;
  }
}