/// Service layer for Jira integration operations.
library;

import 'dart:convert';

import 'package:avodah_core/avodah_core.dart';
import 'package:http/http.dart' as http;

import '../config/paths.dart';

/// Result of a Jira pull operation.
class PullResult {
  final int created;
  final int updated;

  const PullResult({required this.created, required this.updated});

  @override
  String toString() => 'PullResult(created: $created, updated: $updated)';
}

/// Result of a Jira push operation.
class PushResult {
  final int pushed;
  final int failed;

  const PushResult({required this.pushed, required this.failed});

  @override
  String toString() => 'PushResult(pushed: $pushed, failed: $failed)';
}

/// Combined result of a full sync (pull + push).
class SyncResult {
  final PullResult pull;
  final PushResult push;

  const SyncResult({required this.pull, required this.push});
}

/// Status of the Jira integration.
class JiraStatus {
  final bool configured;
  final String? jiraProjectKey;
  final String? baseUrl;
  final DateTime? lastSyncAt;
  final String? lastSyncError;
  final int pendingWorklogs;
  final int linkedTasks;

  const JiraStatus({
    required this.configured,
    this.jiraProjectKey,
    this.baseUrl,
    this.lastSyncAt,
    this.lastSyncError,
    required this.pendingWorklogs,
    required this.linkedTasks,
  });
}

/// Wraps all Jira integration operations.
class JiraService {
  final AppDatabase db;
  final HybridLogicalClock clock;
  final AvodahPaths paths;
  final http.Client httpClient;

  JiraService({
    required this.db,
    required this.clock,
    required this.paths,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Saves a Jira integration document via upsert.
  Future<void> _saveConfig(JiraIntegrationDocument config) async {
    await db
        .into(db.jiraIntegrations)
        .insertOnConflictUpdate(config.toDriftCompanion());
  }

  /// Saves a task document via upsert.
  Future<void> _saveTask(TaskDocument task) async {
    await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());
  }

  /// Saves a worklog document via upsert.
  Future<void> _saveWorklog(WorklogDocument worklog) async {
    await db
        .into(db.worklogEntries)
        .insertOnConflictUpdate(worklog.toDriftCompanion());
  }

  /// Configures Jira integration.
  Future<JiraIntegrationDocument> setup({
    required String baseUrl,
    required String jiraProjectKey,
    required String credentialsPath,
  }) async {
    // Check if config already exists, update it
    final existing = await getConfig();
    if (existing != null) {
      existing.baseUrl = baseUrl;
      existing.jiraProjectKey = jiraProjectKey;
      existing.credentialsFilePath = credentialsPath;
      await _saveConfig(existing);
      return existing;
    }

    final config = JiraIntegrationDocument.create(
      clock: clock,
      baseUrl: baseUrl,
      jiraProjectKey: jiraProjectKey,
      credentialsFilePath: credentialsPath,
    );
    await _saveConfig(config);
    return config;
  }

  /// Loads the Jira integration config from DB (null if not configured).
  Future<JiraIntegrationDocument?> getConfig() async {
    final rows = await db.select(db.jiraIntegrations).get();
    if (rows.isEmpty) return null;

    final doc = JiraIntegrationDocument.fromDrift(
      integration: rows.first,
      clock: clock,
    );
    return doc.isDeleted ? null : doc;
  }

  /// Pulls issues from Jira and creates/updates local tasks.
  Future<PullResult> pull() async {
    final config = await getConfig();
    if (config == null) throw JiraNotConfiguredException();

    final creds = await config.loadCredentials();
    if (creds == null) throw JiraCredentialsNotFoundException(config.credentialsFilePath);

    final jql = config.jqlFilter ??
        'assignee=currentUser() AND project=${config.jiraProjectKey}';

    final response = await _makeRequest(
      config: config,
      creds: creds,
      method: 'GET',
      path: '/search?jql=${Uri.encodeComponent(jql)}&maxResults=50',
    );

    if (response.statusCode != 200) {
      config.recordSyncError('Pull failed: HTTP ${response.statusCode}');
      await _saveConfig(config);
      throw JiraSyncException('Pull failed: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final issues = data['issues'] as List<dynamic>? ?? [];

    // Load existing tasks keyed by issueId
    final allTasks = await db.select(db.tasks).get();
    final existingByIssueId = <String, Task>{};
    for (final row in allTasks) {
      if (row.issueId != null) {
        existingByIssueId[row.issueId!] = row;
      }
    }

    var created = 0;
    var updated = 0;

    for (final issue in issues) {
      final fields = issue['fields'] as Map<String, dynamic>? ?? {};
      final issueKey = issue['key'] as String;
      final summary = fields['summary'] as String? ?? issueKey;

      final existing = existingByIssueId[issueKey];
      if (existing != null) {
        final doc = TaskDocument.fromDrift(task: existing, clock: clock);
        doc.title = summary;
        doc.issueLastUpdated = DateTime.now();
        await _saveTask(doc);
        updated++;
      } else {
        final doc = TaskDocument.create(clock: clock, title: summary);
        doc.issueId = issueKey;
        doc.issueType = IssueType.jira;
        await _saveTask(doc);
        created++;
      }
    }

    config.recordSyncSuccess();
    await _saveConfig(config);

    return PullResult(created: created, updated: updated);
  }

  /// Pushes unsynced worklogs to Jira.
  Future<PushResult> push() async {
    final config = await getConfig();
    if (config == null) throw JiraNotConfiguredException();

    final creds = await config.loadCredentials();
    if (creds == null) throw JiraCredentialsNotFoundException(config.credentialsFilePath);

    // Find worklogs where jiraWorklogId is null AND task has issueId
    final allWorklogs = await db.select(db.worklogEntries).get();
    final allTasks = await db.select(db.tasks).get();

    final taskIssueIds = <String, String>{};
    for (final task in allTasks) {
      if (task.issueId != null) {
        taskIssueIds[task.id] = task.issueId!;
      }
    }

    final unsyncedWorklogs = allWorklogs.where((w) {
      return w.jiraWorklogId == null && taskIssueIds.containsKey(w.taskId);
    }).toList();

    var pushed = 0;
    var failed = 0;

    for (final row in unsyncedWorklogs) {
      final worklog = WorklogDocument.fromDrift(worklog: row, clock: clock);
      if (worklog.isDeleted) continue;

      final issueKey = taskIssueIds[worklog.taskId]!;
      final durationSeconds = worklog.durationMs ~/ 1000;

      final body = jsonEncode({
        'timeSpentSeconds': durationSeconds,
        'started': _formatJiraDateTime(worklog.startTime),
        if (worklog.comment != null) 'comment': {
          'type': 'doc',
          'version': 1,
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': worklog.comment},
              ],
            },
          ],
        },
      });

      try {
        final response = await _makeRequest(
          config: config,
          creds: creds,
          method: 'POST',
          path: '/issue/$issueKey/worklog',
          body: body,
        );

        if (response.statusCode == 201) {
          final respData = jsonDecode(response.body) as Map<String, dynamic>;
          final jiraWorklogId = respData['id'] as String;
          worklog.linkToJira(jiraWorklogId);
          await _saveWorklog(worklog);
          pushed++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }

    if (pushed > 0) {
      config.recordSyncSuccess();
      await _saveConfig(config);
    }

    return PushResult(pushed: pushed, failed: failed);
  }

  /// Runs a full sync: pull then push.
  Future<SyncResult> sync() async {
    final pullResult = await pull();
    final pushResult = await push();
    return SyncResult(pull: pullResult, push: pushResult);
  }

  /// Returns the current Jira integration status.
  Future<JiraStatus> status() async {
    final config = await getConfig();
    if (config == null) {
      return const JiraStatus(
        configured: false,
        pendingWorklogs: 0,
        linkedTasks: 0,
      );
    }

    // Count linked tasks
    final allTasks = await db.select(db.tasks).get();
    final linkedTasks = allTasks
        .map((row) => TaskDocument.fromDrift(task: row, clock: clock))
        .where((t) => !t.isDeleted && t.issueId != null)
        .length;

    // Count unsynced worklogs
    final taskIssueIds = <String>{};
    for (final task in allTasks) {
      if (task.issueId != null) taskIssueIds.add(task.id);
    }

    final allWorklogs = await db.select(db.worklogEntries).get();
    final pendingWorklogs = allWorklogs.where((w) {
      return w.jiraWorklogId == null && taskIssueIds.contains(w.taskId);
    }).length;

    return JiraStatus(
      configured: true,
      jiraProjectKey: config.jiraProjectKey,
      baseUrl: config.baseUrl,
      lastSyncAt: config.lastSyncAt,
      lastSyncError: config.lastSyncError,
      pendingWorklogs: pendingWorklogs,
      linkedTasks: linkedTasks,
    );
  }

  /// Makes an authenticated request to the Jira REST API.
  Future<http.Response> _makeRequest({
    required JiraIntegrationDocument config,
    required JiraCredentials creds,
    required String method,
    required String path,
    String? body,
  }) async {
    final url = Uri.parse('${config.apiUrl}$path');
    final headers = {
      'Authorization': 'Basic ${creds.basicAuth}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    switch (method) {
      case 'GET':
        return httpClient.get(url, headers: headers);
      case 'POST':
        return httpClient.post(url, headers: headers, body: body);
      case 'PUT':
        return httpClient.put(url, headers: headers, body: body);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Formats a DateTime for Jira's expected format.
  static String _formatJiraDateTime(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.toIso8601String().split('.').first}.000+0000';
  }
}

/// Thrown when Jira is not configured.
class JiraNotConfiguredException implements Exception {
  @override
  String toString() => 'Jira integration not configured. Run `avo jira setup` first.';
}

/// Thrown when Jira credentials file is not found.
class JiraCredentialsNotFoundException implements Exception {
  final String path;
  JiraCredentialsNotFoundException(this.path);

  @override
  String toString() => 'Jira credentials file not found at "$path".';
}

/// Thrown when a Jira sync operation fails.
class JiraSyncException implements Exception {
  final String message;
  JiraSyncException(this.message);

  @override
  String toString() => 'Jira sync error: $message';
}
