/// CRDT-backed JiraIntegration document for conflict-free synchronization.
///
/// Stores configuration for Jira integration. Credentials are stored
/// externally in a JSON file (path stored here, not the credentials).
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:avodah_core/crdt/crdt.dart';
import 'package:avodah_core/storage/database.dart';

/// Field keys for JiraIntegrationDocument.
class JiraIntegrationFields {
  JiraIntegrationFields._();

  static const String projectId = 'projectId';
  static const String baseUrl = 'baseUrl';
  static const String jiraProjectKey = 'jiraProjectKey';
  static const String boardId = 'boardId';
  static const String credentialsFilePath = 'credentialsFilePath';
  static const String jqlFilter = 'jqlFilter';
  static const String syncEnabled = 'syncEnabled';
  static const String syncSubtasks = 'syncSubtasks';
  static const String syncWorklogs = 'syncWorklogs';
  static const String syncIntervalMinutes = 'syncIntervalMinutes';
  static const String fieldMappings = 'fieldMappings';
  static const String statusMappings = 'statusMappings';
  static const String lastSyncAt = 'lastSyncAt';
  static const String lastSyncError = 'lastSyncError';
  static const String created = 'created';
}

/// Jira credentials loaded from external file.
class JiraCredentials {
  final String email;
  final String apiToken;

  const JiraCredentials({
    required this.email,
    required this.apiToken,
  });

  factory JiraCredentials.fromJson(Map<String, dynamic> json) {
    return JiraCredentials(
      email: json['email'] as String,
      apiToken: json['apiToken'] as String,
    );
  }

  /// Creates Basic auth header value.
  String get basicAuth => base64Encode(utf8.encode('$email:$apiToken'));
}

/// A CRDT-backed Jira integration document.
///
/// All fields are tracked with individual timestamps for fine-grained
/// conflict resolution during P2P sync.
class JiraIntegrationDocument extends CrdtDocument<JiraIntegrationDocument> {
  /// Creates a new Jira integration with a generated UUID.
  factory JiraIntegrationDocument.create({
    required HybridLogicalClock clock,
    required String baseUrl,
    required String jiraProjectKey,
    required String credentialsFilePath,
    String? projectId,
  }) {
    final doc = JiraIntegrationDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.baseUrl = baseUrl;
    doc.jiraProjectKey = jiraProjectKey;
    doc.credentialsFilePath = credentialsFilePath;
    doc.projectId = projectId;
    doc.syncEnabled = true;
    doc.syncSubtasks = true;
    doc.syncWorklogs = false;
    doc.syncIntervalMinutes = 15;
    doc.createdMs = DateTime.now().millisecondsSinceEpoch;
    return doc;
  }

  /// Creates a Jira integration document with an existing ID.
  JiraIntegrationDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a Jira integration document from existing CRDT state.
  JiraIntegrationDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a Jira integration document from a Drift JiraIntegration entity.
  factory JiraIntegrationDocument.fromDrift({
    required JiraIntegration integration,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(integration.crdtState);

    final doc = JiraIntegrationDocument.fromState(
      id: integration.id,
      clock: clock,
      state: state,
    );

    // If no CRDT state exists, initialize from Drift fields
    if (state.isEmpty) {
      doc._initializeFromDrift(integration);
    }

    return doc;
  }

  /// Initializes fields from Drift entity when no CRDT state exists.
  void _initializeFromDrift(JiraIntegration integration) {
    setString(JiraIntegrationFields.projectId, integration.projectId);
    setString(JiraIntegrationFields.baseUrl, integration.baseUrl);
    setString(JiraIntegrationFields.jiraProjectKey, integration.jiraProjectKey);
    setString(JiraIntegrationFields.boardId, integration.boardId);
    setString(
        JiraIntegrationFields.credentialsFilePath, integration.credentialsFilePath);
    setString(JiraIntegrationFields.jqlFilter, integration.jqlFilter);
    setBool(JiraIntegrationFields.syncEnabled, integration.syncEnabled);
    setBool(JiraIntegrationFields.syncSubtasks, integration.syncSubtasks);
    setBool(JiraIntegrationFields.syncWorklogs, integration.syncWorklogs);
    setInt(JiraIntegrationFields.syncIntervalMinutes,
        integration.syncIntervalMinutes);
    setRaw(JiraIntegrationFields.fieldMappings, integration.fieldMappings);
    setRaw(JiraIntegrationFields.statusMappings, integration.statusMappings);
    setInt(JiraIntegrationFields.lastSyncAt, integration.lastSyncAt);
    setString(JiraIntegrationFields.lastSyncError, integration.lastSyncError);
    setInt(JiraIntegrationFields.created, integration.created);
  }

  // ============================================================
  // Core Fields
  // ============================================================

  /// Linked Avodah project ID (null = global).
  String? get projectId => getString(JiraIntegrationFields.projectId);
  set projectId(String? value) =>
      setString(JiraIntegrationFields.projectId, value);

  /// Jira instance URL.
  String get baseUrl => getString(JiraIntegrationFields.baseUrl) ?? '';
  set baseUrl(String value) => setString(JiraIntegrationFields.baseUrl, value);

  /// Jira project key (e.g., "PROJ").
  String get jiraProjectKey =>
      getString(JiraIntegrationFields.jiraProjectKey) ?? '';
  set jiraProjectKey(String value) =>
      setString(JiraIntegrationFields.jiraProjectKey, value);

  /// Jira board ID for sprint tracking.
  String? get boardId => getString(JiraIntegrationFields.boardId);
  set boardId(String? value) =>
      setString(JiraIntegrationFields.boardId, value);

  /// Path to credentials JSON file.
  String get credentialsFilePath =>
      getString(JiraIntegrationFields.credentialsFilePath) ?? '';
  set credentialsFilePath(String value) =>
      setString(JiraIntegrationFields.credentialsFilePath, value);

  /// Created timestamp (Unix ms).
  int get createdMs => getInt(JiraIntegrationFields.created) ?? 0;
  set createdMs(int value) => setInt(JiraIntegrationFields.created, value);

  // ============================================================
  // Sync Settings
  // ============================================================

  /// Custom JQL filter for issues.
  String? get jqlFilter => getString(JiraIntegrationFields.jqlFilter);
  set jqlFilter(String? value) =>
      setString(JiraIntegrationFields.jqlFilter, value);

  /// Whether sync is enabled.
  bool get syncEnabled => getBool(JiraIntegrationFields.syncEnabled) ?? true;
  set syncEnabled(bool value) =>
      setBool(JiraIntegrationFields.syncEnabled, value);

  /// Whether to sync Jira subtasks.
  bool get syncSubtasks => getBool(JiraIntegrationFields.syncSubtasks) ?? true;
  set syncSubtasks(bool value) =>
      setBool(JiraIntegrationFields.syncSubtasks, value);

  /// Whether to push worklogs to Jira.
  bool get syncWorklogs => getBool(JiraIntegrationFields.syncWorklogs) ?? false;
  set syncWorklogs(bool value) =>
      setBool(JiraIntegrationFields.syncWorklogs, value);

  /// Sync interval in minutes.
  int get syncIntervalMinutes =>
      getInt(JiraIntegrationFields.syncIntervalMinutes) ?? 15;
  set syncIntervalMinutes(int value) =>
      setInt(JiraIntegrationFields.syncIntervalMinutes, value);

  // ============================================================
  // Mappings
  // ============================================================

  /// Field mappings (Jira field -> local field).
  Map<String, String> get fieldMappings {
    final json = getRaw(JiraIntegrationFields.fieldMappings) as String?;
    if (json == null || json.isEmpty || json == '{}') return {};
    return (jsonDecode(json) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
  }

  set fieldMappings(Map<String, String> value) =>
      setRaw(JiraIntegrationFields.fieldMappings, jsonEncode(value));

  /// Status mappings (Jira status -> local status).
  Map<String, String> get statusMappings {
    final json = getRaw(JiraIntegrationFields.statusMappings) as String?;
    if (json == null || json.isEmpty || json == '{}') return {};
    return (jsonDecode(json) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
  }

  set statusMappings(Map<String, String> value) =>
      setRaw(JiraIntegrationFields.statusMappings, jsonEncode(value));

  // ============================================================
  // Sync Status
  // ============================================================

  /// Last successful sync timestamp (Unix ms).
  int? get lastSyncAtMs => getInt(JiraIntegrationFields.lastSyncAt);
  set lastSyncAtMs(int? value) =>
      setInt(JiraIntegrationFields.lastSyncAt, value);

  /// Last sync as DateTime.
  DateTime? get lastSyncAt =>
      lastSyncAtMs != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncAtMs!) : null;

  /// Last sync error message.
  String? get lastSyncError => getString(JiraIntegrationFields.lastSyncError);
  set lastSyncError(String? value) =>
      setString(JiraIntegrationFields.lastSyncError, value);

  /// Whether the last sync had an error.
  bool get hasError => lastSyncError != null;

  /// Records a successful sync.
  void recordSyncSuccess() {
    lastSyncAtMs = DateTime.now().millisecondsSinceEpoch;
    lastSyncError = null;
  }

  /// Records a sync failure.
  void recordSyncError(String error) {
    lastSyncError = error;
  }

  // ============================================================
  // Credentials
  // ============================================================

  /// Loads credentials from the external file.
  ///
  /// Returns null if file doesn't exist or is invalid.
  /// Throws [FileSystemException] if file cannot be read.
  Future<JiraCredentials?> loadCredentials() async {
    if (credentialsFilePath.isEmpty) return null;

    // Expand ~ to home directory
    var path = credentialsFilePath;
    if (path.startsWith('~/')) {
      final home = Platform.environment['HOME'] ?? '';
      path = path.replaceFirst('~', home);
    }

    final file = File(path);
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return JiraCredentials.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Checks if credentials file exists.
  Future<bool> credentialsExist() async {
    if (credentialsFilePath.isEmpty) return false;

    var path = credentialsFilePath;
    if (path.startsWith('~/')) {
      final home = Platform.environment['HOME'] ?? '';
      path = path.replaceFirst('~', home);
    }

    return File(path).exists();
  }

  // ============================================================
  // URL Helpers
  // ============================================================

  /// Returns the full URL for an issue.
  String issueUrl(String issueKey) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$base/browse/$issueKey';
  }

  /// Returns the API base URL.
  String get apiUrl {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$base/rest/api/3';
  }

  // ============================================================
  // Conversion
  // ============================================================

  /// Converts to a Drift JiraIntegrationsCompanion for insert/update.
  JiraIntegrationsCompanion toDriftCompanion() {
    return JiraIntegrationsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      baseUrl: Value(baseUrl),
      jiraProjectKey: Value(jiraProjectKey),
      boardId: Value(boardId),
      credentialsFilePath: Value(credentialsFilePath),
      jqlFilter: Value(jqlFilter),
      syncEnabled: Value(syncEnabled),
      syncSubtasks: Value(syncSubtasks),
      syncWorklogs: Value(syncWorklogs),
      syncIntervalMinutes: Value(syncIntervalMinutes),
      fieldMappings: Value(jsonEncode(fieldMappings)),
      statusMappings: Value(jsonEncode(statusMappings)),
      lastSyncAt: Value(lastSyncAtMs),
      lastSyncError: Value(lastSyncError),
      created: Value(createdMs),
      modified: Value(DateTime.now().millisecondsSinceEpoch),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  /// Converts to an immutable JiraIntegration UI model.
  JiraIntegrationModel toModel() {
    return JiraIntegrationModel(
      id: id,
      projectId: projectId,
      baseUrl: baseUrl,
      jiraProjectKey: jiraProjectKey,
      syncEnabled: syncEnabled,
      syncSubtasks: syncSubtasks,
      syncWorklogs: syncWorklogs,
      syncIntervalMinutes: syncIntervalMinutes,
      lastSyncAt: lastSyncAt,
      hasError: hasError,
      lastSyncError: lastSyncError,
      isDeleted: isDeleted,
    );
  }

  @override
  JiraIntegrationDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return JiraIntegrationDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable Jira integration model for UI consumption.
class JiraIntegrationModel {
  final String id;
  final String? projectId;
  final String baseUrl;
  final String jiraProjectKey;
  final bool syncEnabled;
  final bool syncSubtasks;
  final bool syncWorklogs;
  final int syncIntervalMinutes;
  final DateTime? lastSyncAt;
  final bool hasError;
  final String? lastSyncError;
  final bool isDeleted;

  const JiraIntegrationModel({
    required this.id,
    this.projectId,
    required this.baseUrl,
    required this.jiraProjectKey,
    required this.syncEnabled,
    required this.syncSubtasks,
    required this.syncWorklogs,
    required this.syncIntervalMinutes,
    this.lastSyncAt,
    required this.hasError,
    this.lastSyncError,
    required this.isDeleted,
  });

  /// Display name for the integration.
  String get displayName => jiraProjectKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JiraIntegrationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'JiraIntegrationModel($id, $jiraProjectKey)';
}
