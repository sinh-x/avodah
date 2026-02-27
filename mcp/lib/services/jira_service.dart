/// Service layer for Jira integration operations.
library;

import 'dart:convert';

import 'package:avodah_core/avodah_core.dart';
import 'package:http/http.dart' as http;

import '../config/paths.dart';

/// Callback for reporting sync progress.
typedef SyncProgressCallback = void Function(String phase, int current, int total);

/// Result of a Jira pull operation.
class PullResult {
  final int created;
  final int updated;
  final int worklogsCreated;

  const PullResult({
    required this.created,
    required this.updated,
    this.worklogsCreated = 0,
  });

  @override
  String toString() =>
      'PullResult(created: $created, updated: $updated, worklogsCreated: $worklogsCreated)';
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
  final String? profileName;
  final String? baseUrl;
  final DateTime? lastSyncAt;
  final String? lastSyncError;
  final int pendingWorklogs;
  final int linkedTasks;

  const JiraStatus({
    required this.configured,
    this.jiraProjectKey,
    this.profileName,
    this.baseUrl,
    this.lastSyncAt,
    this.lastSyncError,
    required this.pendingWorklogs,
    required this.linkedTasks,
  });

  /// Project keys as a list (split from comma-separated jiraProjectKey).
  List<String> get projectKeysList =>
      (jiraProjectKey ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

/// Direction for resolving a sync mismatch.
enum SyncDirection { push, pull, skip }

/// Info about a worklog fetched from Jira.
class JiraWorklogInfo {
  final String jiraWorklogId;
  final String issueKey;
  final String localTaskId;
  final int timeSpentSeconds;
  final DateTime started;
  final DateTime created;
  final String? comment;

  const JiraWorklogInfo({
    required this.jiraWorklogId,
    required this.issueKey,
    required this.localTaskId,
    required this.timeSpentSeconds,
    required this.started,
    required this.created,
    this.comment,
  });

  int get durationMs => timeSpentSeconds * 1000;
}

/// A worklog that exists on both sides but has different data.
class WorklogMismatch {
  final WorklogDocument local;
  final JiraWorklogInfo remote;
  final bool durationDiffers;
  final bool commentDiffers;
  final bool startTimeDiffers;
  SyncDirection resolution;

  WorklogMismatch({
    required this.local,
    required this.remote,
    required this.durationDiffers,
    required this.commentDiffers,
    required this.startTimeDiffers,
    this.resolution = SyncDirection.skip,
  });
}

/// A task whose title differs between local and Jira.
class TitleMismatch {
  final TaskDocument localTask;
  final String remoteTitle;
  final String issueKey;
  SyncDirection resolution;

  TitleMismatch({
    required this.localTask,
    required this.remoteTitle,
    required this.issueKey,
    this.resolution = SyncDirection.skip,
  });
}

/// Preview of what a sync would do, without any DB writes.
class SyncPreview {
  final List<Map<String, dynamic>> newRemoteIssues;
  final List<WorklogDocument> newLocalWorklogs;
  final List<JiraWorklogInfo> newRemoteWorklogs;
  final List<WorklogMismatch> worklogMismatches;
  final List<TitleMismatch> titleMismatches;
  final int upToDateTasks;

  const SyncPreview({
    required this.newRemoteIssues,
    required this.newLocalWorklogs,
    required this.newRemoteWorklogs,
    required this.worklogMismatches,
    required this.titleMismatches,
    required this.upToDateTasks,
  });

  bool get hasChanges =>
      newRemoteIssues.isNotEmpty ||
      newLocalWorklogs.isNotEmpty ||
      newRemoteWorklogs.isNotEmpty ||
      worklogMismatches.isNotEmpty ||
      titleMismatches.isNotEmpty;

  bool get hasMismatches =>
      worklogMismatches.isNotEmpty || titleMismatches.isNotEmpty;
}

/// All context needed to execute a sync plan.
class SyncContext {
  final SyncPreview preview;
  final JiraIntegrationDocument config;
  final JiraCredentials creds;
  final String accountId;
  final Map<String, String> issueKeyToTaskId;

  const SyncContext({
    required this.preview,
    required this.config,
    required this.creds,
    required this.accountId,
    required this.issueKeyToTaskId,
  });
}

/// Result of executing a sync plan.
class SyncExecutionResult {
  final int tasksCreated;
  final int tasksUpdated;
  final int worklogsPushed;
  final int worklogsPulled;
  final int mismatchesPushed;
  final int mismatchesPulled;
  final int titlesPushed;
  final int titlesPulled;
  final int failed;

  const SyncExecutionResult({
    this.tasksCreated = 0,
    this.tasksUpdated = 0,
    this.worklogsPushed = 0,
    this.worklogsPulled = 0,
    this.mismatchesPushed = 0,
    this.mismatchesPulled = 0,
    this.titlesPushed = 0,
    this.titlesPulled = 0,
    this.failed = 0,
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

  /// Closes the underlying HTTP client so the process can exit cleanly.
  void close() => httpClient.close();

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

  /// Configures Jira integration from a profile in the config file.
  ///
  /// Loads the profile config from [paths.jiraCredentialsPath], finds the
  /// profile by [profileName] (or default if null), and stores the connection info.
  Future<JiraIntegrationDocument> setup({String? profileName}) async {
    final configFile = paths.jiraCredentialsPath;
    final profileConfig = await JiraProfileConfig.load(configFile);
    final profile = profileConfig.getProfile(profileName);
    if (profile == null) {
      throw JiraProfileNotFoundException(profileName ?? 'default');
    }

    final projectKeysJoined = profile.projectKeys.join(',');

    // Find existing config for this profile, or create a new row
    final existing = await getConfig(profileName: profile.key);
    if (existing != null) {
      existing.baseUrl = profile.baseUrl;
      existing.jiraProjectKey = projectKeysJoined;
      existing.credentialsFilePath = configFile;
      existing.profileName = profile.key;
      existing.defaultCategory = profile.defaultCategory;
      await _saveConfig(existing);
      return existing;
    }

    final config = JiraIntegrationDocument.create(
      clock: clock,
      baseUrl: profile.baseUrl,
      jiraProjectKey: projectKeysJoined,
      credentialsFilePath: configFile,
    );
    config.profileName = profile.key;
    config.defaultCategory = profile.defaultCategory;
    await _saveConfig(config);
    return config;
  }

  /// Loads a Jira integration config from DB.
  ///
  /// If [profileName] is given, returns the config for that profile.
  /// Otherwise returns the most recently modified config.
  Future<JiraIntegrationDocument?> getConfig({String? profileName}) async {
    final rows = await db.select(db.jiraIntegrations).get();
    if (rows.isEmpty) return null;

    final docs = rows
        .map((row) =>
            JiraIntegrationDocument.fromDrift(integration: row, clock: clock))
        .where((d) => !d.isDeleted)
        .toList();
    if (docs.isEmpty) return null;

    if (profileName != null) {
      return docs.cast<JiraIntegrationDocument?>().firstWhere(
          (d) => d!.profileName == profileName,
          orElse: () => null);
    }

    // Return the most recently synced, or most recently created
    docs.sort((a, b) =>
        (b.lastSyncAtMs ?? b.createdMs).compareTo(a.lastSyncAtMs ?? a.createdMs));
    return docs.first;
  }

  /// Returns all non-deleted Jira integration configs.
  Future<List<JiraIntegrationDocument>> getAllConfigs() async {
    final rows = await db.select(db.jiraIntegrations).get();
    return rows
        .map((row) =>
            JiraIntegrationDocument.fromDrift(integration: row, clock: clock))
        .where((d) => !d.isDeleted)
        .toList();
  }

  /// Gets the current Jira user's account ID.
  Future<String> _getCurrentUser({
    required JiraIntegrationDocument config,
    required JiraCredentials creds,
  }) async {
    final response = await _makeRequest(
      config: config,
      creds: creds,
      method: 'GET',
      path: '/myself',
    );
    if (response.statusCode != 200) {
      throw JiraSyncException('Failed to get current user: HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['accountId'] as String;
  }

  /// Extracts plain text from a Jira ADF comment structure.
  static String? _extractPlainText(dynamic comment) {
    if (comment is! Map) return null;
    try {
      final content = comment['content'] as List?;
      if (content == null || content.isEmpty) return null;
      final paragraph = content.first as Map;
      final inner = paragraph['content'] as List?;
      if (inner == null || inner.isEmpty) return null;
      return (inner.first as Map)['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the Jira issue status category is "done".
  static bool _isJiraDone(Map<String, dynamic> fields) {
    final status = fields['status'] as Map<String, dynamic>?;
    if (status == null) return false;
    final category = status['statusCategory'] as Map<String, dynamic>?;
    if (category == null) return false;
    final key = category['key'] as String?;
    return key == 'done';
  }

  /// Returns the Jira status name (e.g. "In Progress", "Done").
  static String? _getJiraStatusName(Map<String, dynamic> fields) {
    final status = fields['status'] as Map<String, dynamic>?;
    return status?['name'] as String?;
  }

  /// Applies common Jira field values to a [TaskDocument].
  ///
  /// Extracts status, estimate, created date, due date, and done state from
  /// the Jira [fields] map and sets them on [doc]. If [defaultCategory] is
  /// given and the task has no category yet, it is also applied.
  static void _applyJiraFields(
    TaskDocument doc,
    Map<String, dynamic> fields, {
    String? defaultCategory,
  }) {
    final jiraDone = _isJiraDone(fields);
    final jiraStatusName = _getJiraStatusName(fields);
    final estimateSec = fields['timeoriginalestimate'] as int?;
    final estimateMs = estimateSec != null ? estimateSec * 1000 : 0;
    final jiraCreatedStr = fields['created'] as String?;
    final jiraCreated =
        jiraCreatedStr != null ? DateTime.tryParse(jiraCreatedStr) : null;
    final dueDate = fields['duedate'] as String?;

    doc.issueLastUpdated = DateTime.now();
    doc.issueStatus = jiraStatusName;
    if (jiraCreated != null) doc.issueCreated = jiraCreated;
    if (estimateMs > 0) doc.timeEstimate = estimateMs;
    if (dueDate != null) doc.dueDay = dueDate;
    if (defaultCategory != null && doc.category == null) {
      doc.category = defaultCategory;
    }
    if (jiraDone && !doc.isDone) {
      doc.markDone();
    } else if (!jiraDone && doc.isDone) {
      doc.markUndone();
    }
  }

  /// Builds a JQL string for the given config and optional issue key.
  ///
  /// When [updatedSinceDays] is non-null and [issueKey] is null, appends
  /// `AND updated >= '-Nd'` to limit results to recently-changed issues.
  /// Skipped when [config.jqlFilter] is set (user owns the full JQL).
  static String _buildJql({
    required JiraIntegrationDocument config,
    String? issueKey,
    int? updatedSinceDays,
  }) {
    if (issueKey != null) return 'key = $issueKey';
    if (config.jqlFilter != null) return config.jqlFilter!;
    final keys = config.jiraProjectKey
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final base = keys.length == 1
        ? 'assignee=currentUser() AND project=${keys.first}'
        : 'assignee=currentUser() AND project in (${keys.join(', ')})';
    if (updatedSinceDays != null) {
      return "$base AND updated >= '-${updatedSinceDays}d'";
    }
    return base;
  }

  /// Fetches issues from Jira via the search API with automatic pagination.
  Future<List<Map<String, dynamic>>> _fetchIssues({
    required JiraIntegrationDocument config,
    required JiraCredentials creds,
    String? issueKey,
    int? updatedSinceDays,
  }) async {
    final jql = _buildJql(config: config, issueKey: issueKey, updatedSinceDays: updatedSinceDays);
    final allIssues = <Map<String, dynamic>>[];
    String? nextPageToken;

    while (true) {
      final body = <String, dynamic>{
        'jql': jql,
        'maxResults': 50,
        'fields': ['summary', 'status', 'priority', 'assignee', 'created', 'updated', 'issuetype', 'project', 'timeoriginalestimate', 'duedate'],
      };
      if (nextPageToken != null) body['nextPageToken'] = nextPageToken;

      final response = await _makeRequest(
        config: config,
        creds: creds,
        method: 'POST',
        path: '/search/jql',
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw JiraSyncException('Pull failed: HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final issues = (data['issues'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      allIssues.addAll(issues);

      nextPageToken = data['nextPageToken'] as String?;
      if (nextPageToken == null || issues.isEmpty) break;
    }

    return allIssues;
  }

  /// Fetches all worklogs for a Jira issue with automatic pagination.
  Future<List<Map<String, dynamic>>> _fetchWorklogs({
    required JiraIntegrationDocument config,
    required JiraCredentials creds,
    required String issueKey,
  }) async {
    final allWorklogs = <Map<String, dynamic>>[];
    var startAt = 0;

    while (true) {
      final response = await _makeRequest(
        config: config,
        creds: creds,
        method: 'GET',
        path: '/issue/$issueKey/worklog?startAt=$startAt&maxResults=50',
      );
      if (response.statusCode != 200) break;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final worklogs = (data['worklogs'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      allWorklogs.addAll(worklogs);

      final total = data['total'] as int? ?? 0;
      startAt += worklogs.length;
      if (startAt >= total || worklogs.isEmpty) break;
    }

    return allWorklogs;
  }

  /// Pulls issues from Jira and creates/updates local tasks.
  /// Also pulls worklogs for the current user from each issue.
  ///
  /// If [issueKey] is given, pulls that specific issue only.
  /// Otherwise pulls all assigned issues across configured project keys.
  /// When [updatedSinceDays] is set, only fetches issues updated in the last N days.
  Future<PullResult> pull({String? issueKey, int? updatedSinceDays}) async {
    final config = await getConfig();
    if (config == null) throw JiraNotConfiguredException();

    final creds = await config.loadCredentials();
    if (creds == null) throw JiraCredentialsNotFoundException(config.credentialsFilePath);

    List<Map<String, dynamic>> issues;
    try {
      issues = await _fetchIssues(config: config, creds: creds, issueKey: issueKey, updatedSinceDays: updatedSinceDays);
    } on JiraSyncException {
      config.recordSyncError('Pull failed');
      await _saveConfig(config);
      rethrow;
    }

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
    // Track newly created tasks by issueKey -> taskId
    final issueKeyToTaskId = <String, String>{};

    for (final issue in issues) {
      final fields = issue['fields'] as Map<String, dynamic>? ?? {};
      final key = issue['key'] as String;
      final summary = fields['summary'] as String? ?? key;

      final existing = existingByIssueId[key];
      if (existing != null) {
        final doc = TaskDocument.fromDrift(task: existing, clock: clock);
        doc.title = summary;
        _applyJiraFields(doc, fields);
        await _saveTask(doc);
        issueKeyToTaskId[key] = existing.id;
        updated++;
      } else {
        final doc = TaskDocument.create(clock: clock, title: summary);
        doc.issueId = key;
        doc.issueType = IssueType.jira;
        _applyJiraFields(doc, fields,
            defaultCategory: config.defaultCategory);
        await _saveTask(doc);
        issueKeyToTaskId[key] = doc.id;
        created++;
      }
    }

    // Pull worklogs for each issue
    var worklogsCreated = 0;
    if (issues.isNotEmpty) {
      final accountId = await _getCurrentUser(config: config, creds: creds);

      // Load existing jiraWorklogIds for dedup
      final allWorklogs = await db.select(db.worklogEntries).get();
      final existingJiraIds = <String>{};
      for (final w in allWorklogs) {
        if (w.jiraWorklogId != null) existingJiraIds.add(w.jiraWorklogId!);
      }

      for (final issue in issues) {
        final key = issue['key'] as String;
        final localTaskId = issueKeyToTaskId[key];
        if (localTaskId == null) continue;

        final worklogs = await _fetchWorklogs(
          config: config, creds: creds, issueKey: key);

        for (final wl in worklogs) {
          final jiraId = wl['id'].toString();
          final authorId = (wl['author'] as Map?)?['accountId'] as String?;
          if (authorId != accountId) continue;
          if (existingJiraIds.contains(jiraId)) continue;

          final timeSpentSeconds = wl['timeSpentSeconds'] as int;
          final started = DateTime.parse(wl['started'] as String);
          final jiraCreated = DateTime.parse(wl['created'] as String);
          final durationMs = timeSpentSeconds * 1000;
          final comment = _extractPlainText(wl['comment']);

          final worklog = WorklogDocument.create(
            clock: clock,
            taskId: localTaskId,
            start: started.millisecondsSinceEpoch,
            end: started.millisecondsSinceEpoch + durationMs,
            comment: comment,
          );
          worklog.createdMs = jiraCreated.millisecondsSinceEpoch;
          worklog.linkToJira(jiraId);
          await _saveWorklog(worklog);
          worklogsCreated++;
          existingJiraIds.add(jiraId);
        }
      }
    }

    config.recordSyncSuccess();
    await _saveConfig(config);

    return PullResult(
      created: created,
      updated: updated,
      worklogsCreated: worklogsCreated,
    );
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

  /// Pushes a single worklog to Jira by its local ID.
  ///
  /// Returns `true` if the worklog was successfully pushed, `false` if not
  /// applicable (not configured, not a Jira task, already synced, HTTP error).
  Future<bool> pushWorklog(String worklogId) async {
    // 1. Load config/creds
    final config = await getConfig();
    if (config == null) return false;
    final creds = await config.loadCredentials();
    if (creds == null) return false;

    // 2. Load worklog row
    final rows = await db.select(db.worklogEntries).get();
    final match = rows.where((w) => w.id == worklogId).toList();
    if (match.isEmpty) return false;
    final worklog = WorklogDocument.fromDrift(worklog: match.first, clock: clock);
    if (worklog.isDeleted || worklog.isSyncedToJira) return false;

    // 3. Load task to get issueKey
    final taskRows = await (db.select(db.tasks)
          ..where((t) => t.id.equals(worklog.taskId)))
        .get();
    if (taskRows.isEmpty) return false;
    final issueKey = taskRows.first.issueId;
    if (issueKey == null) return false;

    // 4. POST to Jira
    try {
      final body = _buildWorklogBody(worklog);
      final response = await _makeRequest(
        config: config,
        creds: creds,
        method: 'POST',
        path: '/issue/$issueKey/worklog',
        body: body,
      );
      if (response.statusCode != 201) return false;

      final respData = jsonDecode(response.body) as Map<String, dynamic>;
      final jiraWorklogId = respData['id'] as String;
      worklog.linkToJira(jiraWorklogId);
      _reconcileDuration(worklog, respData);
      await _saveWorklog(worklog);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates an already-synced worklog on Jira by its local ID.
  ///
  /// Returns `true` if the worklog was successfully updated, `false` if not
  /// applicable (not configured, not synced to Jira, HTTP error).
  Future<bool> updateWorklog(String worklogId) async {
    // 1. Load config/creds
    final config = await getConfig();
    if (config == null) return false;
    final creds = await config.loadCredentials();
    if (creds == null) return false;

    // 2. Load worklog row
    final rows = await db.select(db.worklogEntries).get();
    final match = rows.where((w) => w.id == worklogId).toList();
    if (match.isEmpty) return false;
    final worklog = WorklogDocument.fromDrift(worklog: match.first, clock: clock);
    if (worklog.isDeleted || !worklog.isSyncedToJira) return false;

    // 3. Load task to get issueKey
    final taskRows = await (db.select(db.tasks)
          ..where((t) => t.id.equals(worklog.taskId)))
        .get();
    if (taskRows.isEmpty) return false;
    final issueKey = taskRows.first.issueId;
    if (issueKey == null) return false;

    // 4. PUT to Jira
    try {
      final body = _buildWorklogBody(worklog);
      final response = await _makeRequest(
        config: config,
        creds: creds,
        method: 'PUT',
        path: '/issue/$issueKey/worklog/${worklog.jiraWorklogId}',
        body: body,
      );
      if (response.statusCode != 200) return false;

      final respData = jsonDecode(response.body) as Map<String, dynamic>;
      _reconcileDuration(worklog, respData);
      await _saveWorklog(worklog);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Runs a full sync: pull then push.
  ///
  /// If [issueKey] is given, only pulls that specific issue.
  /// When [updatedSinceDays] is set, only syncs issues updated in the last N days.
  Future<SyncResult> sync({String? issueKey, int? updatedSinceDays}) async {
    final pullResult = await pull(issueKey: issueKey, updatedSinceDays: updatedSinceDays);
    final pushResult = await push();
    return SyncResult(pull: pullResult, push: pushResult);
  }

  /// Computes a preview of what a 2-way sync would do, without writing to DB.
  ///
  /// Returns a [SyncContext] containing the preview and all context needed
  /// to execute the plan later via [executeSyncPlan].
  Future<SyncContext> computeSyncPreview({
    String? issueKey,
    int? updatedSinceDays,
    SyncProgressCallback? onProgress,
  }) async {
    final config = await getConfig();
    if (config == null) throw JiraNotConfiguredException();

    final creds = await config.loadCredentials();
    if (creds == null) throw JiraCredentialsNotFoundException(config.credentialsFilePath);

    final issues = await _fetchIssues(config: config, creds: creds, issueKey: issueKey, updatedSinceDays: updatedSinceDays);
    onProgress?.call('Fetching issues', issues.length, issues.length);

    // Load local state
    final allTasks = await db.select(db.tasks).get();
    final allWorklogs = await db.select(db.worklogEntries).get();

    final existingByIssueId = <String, Task>{};
    for (final row in allTasks) {
      if (row.issueId != null) existingByIssueId[row.issueId!] = row;
    }

    final newRemoteIssues = <Map<String, dynamic>>[];
    final titleMismatches = <TitleMismatch>[];
    var upToDateTasks = 0;
    final issueKeyToTaskId = <String, String>{};

    for (final issue in issues) {
      final fields = issue['fields'] as Map<String, dynamic>? ?? {};
      final key = issue['key'] as String;
      final summary = fields['summary'] as String? ?? key;

      final existing = existingByIssueId[key];
      if (existing == null) {
        newRemoteIssues.add(issue);
      } else {
        issueKeyToTaskId[key] = existing.id;
        final localDoc = TaskDocument.fromDrift(task: existing, clock: clock);

        // Always refresh metadata fields from Jira
        _applyJiraFields(localDoc, fields);
        await _saveTask(localDoc);

        if (localDoc.title != summary) {
          titleMismatches.add(TitleMismatch(
            localTask: localDoc,
            remoteTitle: summary,
            issueKey: key,
          ));
        } else {
          upToDateTasks++;
        }
      }
    }

    // Get current user for worklog filtering
    final accountId = issues.isNotEmpty
        ? await _getCurrentUser(config: config, creds: creds)
        : '';

    // Build index of existing jira worklog IDs → local worklog
    final localByJiraId = <String, WorklogDocument>{};
    final existingJiraIds = <String>{};
    for (final w in allWorklogs) {
      if (w.jiraWorklogId != null) {
        existingJiraIds.add(w.jiraWorklogId!);
        localByJiraId[w.jiraWorklogId!] = WorklogDocument.fromDrift(worklog: w, clock: clock);
      }
    }

    final newRemoteWorklogs = <JiraWorklogInfo>[];
    final worklogMismatches = <WorklogMismatch>[];

    // Count existing issues (not new) for worklog fetching progress
    final existingIssueCount = issues.where((i) =>
        issueKeyToTaskId.containsKey(i['key'] as String)).length;
    var worklogFetchIndex = 0;

    for (final issue in issues) {
      final key = issue['key'] as String;
      final localTaskId = issueKeyToTaskId[key];
      if (localTaskId == null) continue; // new issue, handled separately

      final worklogs = await _fetchWorklogs(
        config: config, creds: creds, issueKey: key);
      worklogFetchIndex++;
      onProgress?.call('Fetching worklogs', worklogFetchIndex, existingIssueCount);

      for (final wl in worklogs) {
        final jiraId = wl['id'].toString();
        final authorId = (wl['author'] as Map?)?['accountId'] as String?;
        if (authorId != accountId) continue;

        final timeSpentSeconds = wl['timeSpentSeconds'] as int;
        final started = DateTime.parse(wl['started'] as String);
        final wlCreated = DateTime.parse(wl['created'] as String);
        final comment = _extractPlainText(wl['comment']);

        final info = JiraWorklogInfo(
          jiraWorklogId: jiraId,
          issueKey: key,
          localTaskId: localTaskId,
          timeSpentSeconds: timeSpentSeconds,
          started: started,
          created: wlCreated,
          comment: comment,
        );

        if (!existingJiraIds.contains(jiraId)) {
          newRemoteWorklogs.add(info);
        } else {
          // Compare for mismatch
          final localWl = localByJiraId[jiraId]!;
          final durationDiffers = localWl.durationMs ~/ 1000 != timeSpentSeconds;
          final commentDiffers = (localWl.comment ?? '') != (comment ?? '');
          final startTimeDiffers = localWl.startMs != started.millisecondsSinceEpoch;
          if (durationDiffers || commentDiffers || startTimeDiffers) {
            worklogMismatches.add(WorklogMismatch(
              local: localWl,
              remote: info,
              durationDiffers: durationDiffers,
              commentDiffers: commentDiffers,
              startTimeDiffers: startTimeDiffers,
            ));
          }
        }
      }
    }

    // Find local worklogs not yet pushed (jiraWorklogId == null, task has issueId)
    final taskIssueIds = <String, String>{};
    for (final task in allTasks) {
      if (task.issueId != null) taskIssueIds[task.id] = task.issueId!;
    }

    final newLocalWorklogs = <WorklogDocument>[];
    for (final row in allWorklogs) {
      if (row.jiraWorklogId == null && taskIssueIds.containsKey(row.taskId)) {
        final wl = WorklogDocument.fromDrift(worklog: row, clock: clock);
        if (!wl.isDeleted) newLocalWorklogs.add(wl);
      }
    }

    return SyncContext(
      preview: SyncPreview(
        newRemoteIssues: newRemoteIssues,
        newLocalWorklogs: newLocalWorklogs,
        newRemoteWorklogs: newRemoteWorklogs,
        worklogMismatches: worklogMismatches,
        titleMismatches: titleMismatches,
        upToDateTasks: upToDateTasks,
      ),
      config: config,
      creds: creds,
      accountId: accountId,
      issueKeyToTaskId: issueKeyToTaskId,
    );
  }

  /// Executes a sync plan after the user has resolved mismatches.
  ///
  /// Takes a [SyncContext] (from [computeSyncPreview]) with resolutions
  /// set on each mismatch. Applies the approved changes.
  Future<SyncExecutionResult> executeSyncPlan(
    SyncContext context, {
    SyncProgressCallback? onProgress,
  }) async {
    final config = context.config;
    final creds = context.creds;
    var tasksCreated = 0;
    var tasksUpdated = 0;
    var worklogsPushed = 0;
    var worklogsPulled = 0;
    var mismatchesPushed = 0;
    var mismatchesPulled = 0;
    var titlesPushed = 0;
    var titlesPulled = 0;
    var failed = 0;

    // Compute total operations for progress tracking
    final preview = context.preview;
    final totalOps = preview.newRemoteIssues.length +
        preview.newLocalWorklogs.length +
        preview.newRemoteWorklogs.length +
        preview.worklogMismatches.length +
        preview.titleMismatches.length;
    var completedOps = 0;

    // 1. Create new tasks from new remote issues
    for (final issue in preview.newRemoteIssues) {
      final fields = issue['fields'] as Map<String, dynamic>? ?? {};
      final key = issue['key'] as String;
      final summary = fields['summary'] as String? ?? key;

      final doc = TaskDocument.create(clock: clock, title: summary);
      doc.issueId = key;
      doc.issueType = IssueType.jira;
      _applyJiraFields(doc, fields,
          defaultCategory: config.defaultCategory);
      await _saveTask(doc);
      tasksCreated++;
      completedOps++;
      onProgress?.call('Applying changes', completedOps, totalOps);
    }

    // Build reverse map after creating new tasks
    final taskIdToIssueKey = await _buildTaskIdToIssueKey();

    // 2. Push new local worklogs
    for (final worklog in preview.newLocalWorklogs) {
      final issueKey = taskIdToIssueKey[worklog.taskId];
      if (issueKey == null) { failed++; completedOps++; onProgress?.call('Applying changes', completedOps, totalOps); continue; }

      final body = _buildWorklogBody(worklog);
      try {
        final response = await _makeRequest(
          config: config, creds: creds,
          method: 'POST',
          path: '/issue/$issueKey/worklog',
          body: body,
        );
        if (response.statusCode == 201) {
          final respData = jsonDecode(response.body) as Map<String, dynamic>;
          final jiraWorklogId = respData['id'] as String;
          worklog.linkToJira(jiraWorklogId);
          _reconcileDuration(worklog, respData);
          await _saveWorklog(worklog);
          worklogsPushed++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
      completedOps++;
      onProgress?.call('Applying changes', completedOps, totalOps);
    }

    // 3. Pull new remote worklogs
    for (final info in preview.newRemoteWorklogs) {
      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: info.localTaskId,
        start: info.started.millisecondsSinceEpoch,
        end: info.started.millisecondsSinceEpoch + info.durationMs,
        comment: info.comment,
      );
      worklog.createdMs = info.created.millisecondsSinceEpoch;
      worklog.linkToJira(info.jiraWorklogId);
      await _saveWorklog(worklog);
      worklogsPulled++;
      completedOps++;
      onProgress?.call('Applying changes', completedOps, totalOps);
    }

    // 4. Resolve worklog mismatches
    for (final m in preview.worklogMismatches) {
      switch (m.resolution) {
        case SyncDirection.push:
          final issueKey = m.remote.issueKey;
          final body = _buildWorklogBody(m.local);
          try {
            final response = await _makeRequest(
              config: config, creds: creds,
              method: 'PUT',
              path: '/issue/$issueKey/worklog/${m.remote.jiraWorklogId}',
              body: body,
            );
            if (response.statusCode == 200) {
              final respData = jsonDecode(response.body) as Map<String, dynamic>;
              _reconcileDuration(m.local, respData);
              await _saveWorklog(m.local);
              mismatchesPushed++;
            } else {
              failed++;
            }
          } catch (_) {
            failed++;
          }
        case SyncDirection.pull:
          m.local.startMs = m.remote.started.millisecondsSinceEpoch;
          m.local.durationMs = m.remote.durationMs;
          m.local.endMs = m.local.startMs + m.remote.durationMs;
          m.local.comment = m.remote.comment;
          m.local.updatedMs = DateTime.now().millisecondsSinceEpoch;
          await _saveWorklog(m.local);
          mismatchesPulled++;
        case SyncDirection.skip:
          break;
      }
      completedOps++;
      onProgress?.call('Applying changes', completedOps, totalOps);
    }

    // 5. Resolve title mismatches
    for (final m in preview.titleMismatches) {
      switch (m.resolution) {
        case SyncDirection.push:
          try {
            final response = await _makeRequest(
              config: config, creds: creds,
              method: 'PUT',
              path: '/issue/${m.issueKey}',
              body: jsonEncode({'fields': {'summary': m.localTask.title}}),
            );
            if (response.statusCode == 204 || response.statusCode == 200) {
              titlesPushed++;
            } else {
              failed++;
            }
          } catch (_) {
            failed++;
          }
        case SyncDirection.pull:
          m.localTask.title = m.remoteTitle;
          m.localTask.issueLastUpdated = DateTime.now();
          await _saveTask(m.localTask);
          titlesPulled++;
        case SyncDirection.skip:
          break;
      }
      completedOps++;
      onProgress?.call('Applying changes', completedOps, totalOps);
    }

    config.recordSyncSuccess();
    await _saveConfig(config);

    return SyncExecutionResult(
      tasksCreated: tasksCreated,
      tasksUpdated: tasksUpdated,
      worklogsPushed: worklogsPushed,
      worklogsPulled: worklogsPulled,
      mismatchesPushed: mismatchesPushed,
      mismatchesPulled: mismatchesPulled,
      titlesPushed: titlesPushed,
      titlesPulled: titlesPulled,
      failed: failed,
    );
  }

  /// Builds a Jira worklog JSON body from a local worklog.
  String _buildWorklogBody(WorklogDocument worklog) {
    return jsonEncode({
      'timeSpentSeconds': worklog.durationMs ~/ 1000,
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
  }

  /// Reconciles local worklog duration with Jira's response (handles rounding).
  void _reconcileDuration(WorklogDocument worklog, Map<String, dynamic> respData) {
    final jiraSeconds = respData['timeSpentSeconds'] as int?;
    if (jiraSeconds == null) return;
    final reconciledMs = jiraSeconds * 1000;
    if (worklog.durationMs != reconciledMs) {
      worklog.durationMs = reconciledMs;
      worklog.endMs = worklog.startMs + reconciledMs;
      worklog.updatedMs = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// Builds a taskId → issueKey reverse map from the DB.
  Future<Map<String, String>> _buildTaskIdToIssueKey() async {
    final allTasks = await db.select(db.tasks).get();
    final map = <String, String>{};
    for (final task in allTasks) {
      if (task.issueId != null) map[task.id] = task.issueId!;
    }
    return map;
  }

  /// Loads the username from the credentials file for the current profile.
  ///
  /// Returns null if not configured or credentials can't be loaded.
  Future<String?> getProfileUsername() async {
    final config = await getConfig();
    if (config == null) return null;

    try {
      final profileConfig = await JiraProfileConfig.load(config.credentialsFilePath);
      final profile = profileConfig.getProfile(config.profileName);
      return profile?.username;
    } catch (_) {
      return null;
    }
  }

  /// Returns the Jira integration status for the active (most recent) profile.
  Future<JiraStatus> status() async {
    final all = await statusAll();
    if (all.isEmpty) {
      return const JiraStatus(
        configured: false,
        pendingWorklogs: 0,
        linkedTasks: 0,
      );
    }
    return all.first;
  }

  /// Returns Jira integration status for all configured profiles.
  Future<List<JiraStatus>> statusAll() async {
    final configs = await getAllConfigs();
    if (configs.isEmpty) return [];

    // Load all tasks and worklogs once
    final allTasks = await db.select(db.tasks).get();
    final taskDocs = allTasks
        .map((row) => TaskDocument.fromDrift(task: row, clock: clock))
        .where((t) => !t.isDeleted)
        .toList();
    final allWorklogs = await db.select(db.worklogEntries).get();

    // Build a map of taskId → issueId for linked tasks
    final taskIssueMap = <String, String?>{};
    for (final t in taskDocs) {
      taskIssueMap[t.id] = t.issueId;
    }

    final results = <JiraStatus>[];
    for (final config in configs) {
      final projectKeys = config.jiraProjectKey
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Count tasks whose issueId matches this profile's project keys
      final linkedTasks = taskDocs.where((t) {
        final issue = t.issueId;
        if (issue == null) return false;
        return projectKeys.any((key) => issue.startsWith('$key-'));
      }).length;

      // Count unsynced worklogs for those tasks
      final linkedTaskIds = taskDocs
          .where((t) {
            final issue = t.issueId;
            if (issue == null) return false;
            return projectKeys.any((key) => issue.startsWith('$key-'));
          })
          .map((t) => t.id)
          .toSet();

      final pendingWorklogs = allWorklogs.where((w) {
        return w.jiraWorklogId == null && linkedTaskIds.contains(w.taskId);
      }).length;

      results.add(JiraStatus(
        configured: true,
        jiraProjectKey: config.jiraProjectKey,
        profileName: config.profileName,
        baseUrl: config.baseUrl,
        lastSyncAt: config.lastSyncAt,
        lastSyncError: config.lastSyncError,
        pendingWorklogs: pendingWorklogs,
        linkedTasks: linkedTasks,
      ));
    }

    // Sort: most recently synced first
    results.sort((a, b) =>
        (b.lastSyncAt?.millisecondsSinceEpoch ?? 0)
            .compareTo(a.lastSyncAt?.millisecondsSinceEpoch ?? 0));
    return results;
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

/// Thrown when a Jira profile is not found in the config file.
class JiraProfileNotFoundException implements Exception {
  final String profileName;
  JiraProfileNotFoundException(this.profileName);

  @override
  String toString() => 'Jira profile "$profileName" not found in config file.';
}

/// Thrown when a Jira sync operation fails.
class JiraSyncException implements Exception {
  final String message;
  JiraSyncException(this.message);

  @override
  String toString() => 'Jira sync error: $message';
}
