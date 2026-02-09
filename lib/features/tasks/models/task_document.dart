/// CRDT-backed Task document for conflict-free synchronization.
///
/// This document represents a task with all its fields tracked via CRDT
/// timestamps for per-field conflict resolution during sync.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crdt/crdt.dart';
import '../../../core/storage/database.dart';

/// Field keys for TaskDocument.
class TaskFields {
  TaskFields._();

  static const String projectId = 'projectId';
  static const String title = 'title';
  static const String notes = 'notes';
  static const String isDone = 'isDone';
  static const String created = 'created';
  static const String timeSpent = 'timeSpent';
  static const String timeEstimate = 'timeEstimate';
  static const String timeSpentOnDay = 'timeSpentOnDay';
  static const String dueWithTime = 'dueWithTime';
  static const String dueDay = 'dueDay';
  static const String tagIds = 'tagIds';
  static const String attachments = 'attachments';
  static const String reminderId = 'reminderId';
  static const String remindAt = 'remindAt';
  static const String doneOn = 'doneOn';
  static const String repeatCfgId = 'repeatCfgId';
  static const String issueId = 'issueId';
  static const String issueProviderId = 'issueProviderId';
  static const String issueType = 'issueType';
  static const String issueWasUpdated = 'issueWasUpdated';
  static const String issueLastUpdated = 'issueLastUpdated';
  static const String issueAttachmentNr = 'issueAttachmentNr';
  static const String issueTimeTracked = 'issueTimeTracked';
  static const String issuePoints = 'issuePoints';
}

/// Issue provider types for external integrations.
enum IssueType {
  jira,
  github,
  gitlab,
  redmine,
  gitea,
  caldav,
  openProject;

  String toValue() => name.toUpperCase();

  static IssueType? fromValue(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase();
    return IssueType.values.where((e) => e.name == lower).firstOrNull;
  }
}

/// A CRDT-backed task document.
///
/// All fields are tracked with individual timestamps for fine-grained
/// conflict resolution during P2P sync.
class TaskDocument extends CrdtDocument<TaskDocument> {
  /// Creates a new task document with a generated UUID.
  factory TaskDocument.create({
    required HybridLogicalClock clock,
    required String title,
    String? projectId,
  }) {
    final doc = TaskDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.title = title;
    doc.projectId = projectId;
    doc.isDone = false;
    doc.createdTimestamp = DateTime.now();
    doc.timeSpent = 0;
    doc.timeEstimate = 0;
    return doc;
  }

  /// Creates a task document with an existing ID.
  TaskDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a task document from existing CRDT state.
  TaskDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a task document from a Drift Task entity.
  factory TaskDocument.fromDrift({
    required Task task,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(task.crdtState);

    final doc = TaskDocument.fromState(
      id: task.id,
      clock: clock,
      state: state,
    );

    // If no CRDT state exists, initialize from Drift fields
    if (state.isEmpty) {
      doc._initializeFromDrift(task);
    }

    return doc;
  }

  /// Initializes fields from Drift entity when no CRDT state exists.
  void _initializeFromDrift(Task task) {
    setString(TaskFields.projectId, task.projectId);
    setString(TaskFields.title, task.title);
    setString(TaskFields.notes, task.notes);
    setBool(TaskFields.isDone, task.isDone);
    setInt(TaskFields.created, task.created);
    setInt(TaskFields.timeSpent, task.timeSpent);
    setInt(TaskFields.timeEstimate, task.timeEstimate);
    setRaw(TaskFields.timeSpentOnDay, task.timeSpentOnDay);
    setInt(TaskFields.dueWithTime, task.dueWithTime);
    setString(TaskFields.dueDay, task.dueDay);
    setRaw(TaskFields.tagIds, task.tagIds);
    setRaw(TaskFields.attachments, task.attachments);
    setString(TaskFields.reminderId, task.reminderId);
    setInt(TaskFields.remindAt, task.remindAt);
    setInt(TaskFields.doneOn, task.doneOn);
    setString(TaskFields.repeatCfgId, task.repeatCfgId);
    setString(TaskFields.issueId, task.issueId);
    setString(TaskFields.issueProviderId, task.issueProviderId);
    setString(TaskFields.issueType, task.issueType);
    setBool(TaskFields.issueWasUpdated, task.issueWasUpdated);
    setInt(TaskFields.issueLastUpdated, task.issueLastUpdated);
    setInt(TaskFields.issueAttachmentNr, task.issueAttachmentNr);
    setRaw(TaskFields.issueTimeTracked, task.issueTimeTracked);
    setInt(TaskFields.issuePoints, task.issuePoints);
  }

  // ============================================================
  // Core Fields
  // ============================================================

  /// Project this task belongs to (nullable).
  String? get projectId => getString(TaskFields.projectId);
  set projectId(String? value) => setString(TaskFields.projectId, value);

  /// Task title/description.
  String get title => getString(TaskFields.title) ?? '';
  set title(String value) => setString(TaskFields.title, value);

  /// Detailed notes/description (rich text).
  String get notes => getString(TaskFields.notes) ?? '';
  set notes(String value) => setString(TaskFields.notes, value);

  /// Whether the task is completed.
  bool get isDone => getBool(TaskFields.isDone) ?? false;
  set isDone(bool value) {
    setBool(TaskFields.isDone, value);
    if (value) {
      doneOn = DateTime.now();
    }
  }

  /// When the task was created.
  DateTime? get createdTimestamp {
    final ms = getInt(TaskFields.created);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set createdTimestamp(DateTime? value) =>
      setInt(TaskFields.created, value?.millisecondsSinceEpoch);

  // ============================================================
  // Time Tracking
  // ============================================================

  /// Total time spent on task (milliseconds).
  int get timeSpent => getInt(TaskFields.timeSpent) ?? 0;
  set timeSpent(int value) => setInt(TaskFields.timeSpent, value);

  /// Estimated time for task (milliseconds).
  int get timeEstimate => getInt(TaskFields.timeEstimate) ?? 0;
  set timeEstimate(int value) => setInt(TaskFields.timeEstimate, value);

  /// Time spent per day (JSON: {"YYYY-MM-DD": milliseconds}).
  Map<String, int> get timeSpentOnDay {
    final json = getRaw(TaskFields.timeSpentOnDay) as String?;
    if (json == null || json.isEmpty || json == '{}') return {};
    return (jsonDecode(json) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    );
  }

  set timeSpentOnDay(Map<String, int> value) =>
      setRaw(TaskFields.timeSpentOnDay, jsonEncode(value));

  /// Adds time to a specific day.
  void addTimeOnDay(String day, int milliseconds) {
    final current = timeSpentOnDay;
    current[day] = (current[day] ?? 0) + milliseconds;
    timeSpentOnDay = current;
    timeSpent = timeSpent + milliseconds;
  }

  // ============================================================
  // Due Dates
  // ============================================================

  /// Due date with specific time.
  DateTime? get dueWithTime {
    final ms = getInt(TaskFields.dueWithTime);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set dueWithTime(DateTime? value) =>
      setInt(TaskFields.dueWithTime, value?.millisecondsSinceEpoch);

  /// Due day without time (YYYY-MM-DD format).
  String? get dueDay => getString(TaskFields.dueDay);
  set dueDay(String? value) => setString(TaskFields.dueDay, value);

  /// Sets due date from DateTime (extracts just the date part).
  void setDueDate(DateTime? date) {
    if (date == null) {
      dueDay = null;
    } else {
      dueDay =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Returns true if the task is overdue.
  bool get isOverdue {
    if (isDone) return false;
    final due = dueWithTime ?? (dueDay != null ? DateTime.parse(dueDay!) : null);
    if (due == null) return false;
    return due.isBefore(DateTime.now());
  }

  // ============================================================
  // Relations
  // ============================================================

  /// Tag IDs associated with this task.
  List<String> get tagIds {
    final json = getRaw(TaskFields.tagIds) as String?;
    if (json == null || json.isEmpty || json == '[]') return [];
    return (jsonDecode(json) as List).cast<String>();
  }

  set tagIds(List<String> value) => setRaw(TaskFields.tagIds, jsonEncode(value));

  /// Adds a tag to this task.
  void addTag(String tagId) {
    if (!tagIds.contains(tagId)) {
      tagIds = [...tagIds, tagId];
    }
  }

  /// Removes a tag from this task.
  void removeTag(String tagId) {
    tagIds = tagIds.where((id) => id != tagId).toList();
  }

  // ============================================================
  // Attachments
  // ============================================================

  /// Attachment references (JSON array of attachment objects).
  List<Map<String, dynamic>> get attachments {
    final json = getRaw(TaskFields.attachments) as String?;
    if (json == null || json.isEmpty || json == '[]') return [];
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }

  set attachments(List<Map<String, dynamic>> value) =>
      setRaw(TaskFields.attachments, jsonEncode(value));

  // ============================================================
  // Reminders
  // ============================================================

  /// Reminder ID for this task.
  String? get reminderId => getString(TaskFields.reminderId);
  set reminderId(String? value) => setString(TaskFields.reminderId, value);

  /// When to remind (Unix ms).
  DateTime? get remindAt {
    final ms = getInt(TaskFields.remindAt);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set remindAt(DateTime? value) =>
      setInt(TaskFields.remindAt, value?.millisecondsSinceEpoch);

  // ============================================================
  // Completion
  // ============================================================

  /// When the task was marked done.
  DateTime? get doneOn {
    final ms = getInt(TaskFields.doneOn);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set doneOn(DateTime? value) =>
      setInt(TaskFields.doneOn, value?.millisecondsSinceEpoch);

  /// Marks task as done with current timestamp.
  void markDone() {
    isDone = true;
  }

  /// Marks task as not done, clears doneOn.
  void markUndone() {
    setBool(TaskFields.isDone, false);
    setInt(TaskFields.doneOn, null);
  }

  // ============================================================
  // Repeats
  // ============================================================

  /// Repeat configuration ID.
  String? get repeatCfgId => getString(TaskFields.repeatCfgId);
  set repeatCfgId(String? value) => setString(TaskFields.repeatCfgId, value);

  /// Returns true if this is a repeating task.
  bool get isRepeating => repeatCfgId != null;

  // ============================================================
  // Issue Integration
  // ============================================================

  /// External issue ID (e.g., JIRA-123, #456).
  String? get issueId => getString(TaskFields.issueId);
  set issueId(String? value) => setString(TaskFields.issueId, value);

  /// Integration provider ID this issue belongs to.
  String? get issueProviderId => getString(TaskFields.issueProviderId);
  set issueProviderId(String? value) =>
      setString(TaskFields.issueProviderId, value);

  /// Type of issue provider.
  IssueType? get issueType =>
      IssueType.fromValue(getString(TaskFields.issueType));
  set issueType(IssueType? value) =>
      setString(TaskFields.issueType, value?.toValue());

  /// Whether the issue was updated externally.
  bool? get issueWasUpdated => getBool(TaskFields.issueWasUpdated);
  set issueWasUpdated(bool? value) =>
      setBool(TaskFields.issueWasUpdated, value);

  /// When the issue was last synced.
  DateTime? get issueLastUpdated {
    final ms = getInt(TaskFields.issueLastUpdated);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set issueLastUpdated(DateTime? value) =>
      setInt(TaskFields.issueLastUpdated, value?.millisecondsSinceEpoch);

  /// Number of attachments on the external issue.
  int? get issueAttachmentNr => getInt(TaskFields.issueAttachmentNr);
  set issueAttachmentNr(int? value) =>
      setInt(TaskFields.issueAttachmentNr, value);

  /// Time tracked on the external issue per day.
  Map<String, int>? get issueTimeTracked {
    final json = getRaw(TaskFields.issueTimeTracked) as String?;
    if (json == null || json.isEmpty) return null;
    return (jsonDecode(json) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    );
  }

  set issueTimeTracked(Map<String, int>? value) =>
      setRaw(TaskFields.issueTimeTracked, value != null ? jsonEncode(value) : null);

  /// Story points for the issue.
  int? get issuePoints => getInt(TaskFields.issuePoints);
  set issuePoints(int? value) => setInt(TaskFields.issuePoints, value);

  /// Returns true if this task is linked to an external issue.
  bool get hasIssueLink => issueId != null && issueProviderId != null;

  /// Links this task to an external issue.
  void linkToIssue({
    required String issueId,
    required String providerId,
    required IssueType type,
    int? points,
  }) {
    this.issueId = issueId;
    issueProviderId = providerId;
    issueType = type;
    issuePoints = points;
    issueLastUpdated = DateTime.now();
  }

  /// Unlinks this task from any external issue.
  void unlinkIssue() {
    issueId = null;
    issueProviderId = null;
    issueType = null;
    issueWasUpdated = null;
    issueLastUpdated = null;
    issueAttachmentNr = null;
    issueTimeTracked = null;
    issuePoints = null;
  }

  // ============================================================
  // Conversion
  // ============================================================

  /// Converts to a Drift TasksCompanion for insert/update.
  TasksCompanion toDriftCompanion() {
    return TasksCompanion(
      id: Value(id),
      projectId: Value(projectId),
      title: Value(title),
      notes: Value(notes),
      isDone: Value(isDone),
      created: Value(createdTimestamp?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch),
      timeSpent: Value(timeSpent),
      timeEstimate: Value(timeEstimate),
      timeSpentOnDay: Value(jsonEncode(timeSpentOnDay)),
      dueWithTime: Value(dueWithTime?.millisecondsSinceEpoch),
      dueDay: Value(dueDay),
      tagIds: Value(jsonEncode(tagIds)),
      attachments: Value(jsonEncode(attachments)),
      reminderId: Value(reminderId),
      remindAt: Value(remindAt?.millisecondsSinceEpoch),
      doneOn: Value(doneOn?.millisecondsSinceEpoch),
      modified: Value(DateTime.now().millisecondsSinceEpoch),
      repeatCfgId: Value(repeatCfgId),
      issueId: Value(issueId),
      issueProviderId: Value(issueProviderId),
      issueType: Value(issueType?.toValue()),
      issueWasUpdated: Value(issueWasUpdated),
      issueLastUpdated: Value(issueLastUpdated?.millisecondsSinceEpoch),
      issueAttachmentNr: Value(issueAttachmentNr),
      issueTimeTracked:
          Value(issueTimeTracked != null ? jsonEncode(issueTimeTracked) : null),
      issuePoints: Value(issuePoints),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  /// Converts to an immutable Task UI model.
  TaskModel toModel() {
    return TaskModel(
      id: id,
      projectId: projectId,
      title: title,
      notes: notes,
      isDone: isDone,
      isDeleted: isDeleted,
      created: createdTimestamp,
      timeSpent: Duration(milliseconds: timeSpent),
      timeEstimate: Duration(milliseconds: timeEstimate),
      dueWithTime: dueWithTime,
      dueDay: dueDay,
      tagIds: tagIds,
      remindAt: remindAt,
      isOverdue: isOverdue,
      isRepeating: isRepeating,
      hasIssueLink: hasIssueLink,
      issueId: issueId,
      issueType: issueType,
    );
  }

  @override
  TaskDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return TaskDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable task model for UI consumption.
///
/// This is a read-only snapshot of a task's state, suitable for
/// use in widgets and state management.
class TaskModel {
  final String id;
  final String? projectId;
  final String title;
  final String notes;
  final bool isDone;
  final bool isDeleted;
  final DateTime? created;
  final Duration timeSpent;
  final Duration timeEstimate;
  final DateTime? dueWithTime;
  final String? dueDay;
  final List<String> tagIds;
  final DateTime? remindAt;
  final bool isOverdue;
  final bool isRepeating;
  final bool hasIssueLink;
  final String? issueId;
  final IssueType? issueType;

  const TaskModel({
    required this.id,
    this.projectId,
    required this.title,
    required this.notes,
    required this.isDone,
    required this.isDeleted,
    this.created,
    required this.timeSpent,
    required this.timeEstimate,
    this.dueWithTime,
    this.dueDay,
    required this.tagIds,
    this.remindAt,
    required this.isOverdue,
    required this.isRepeating,
    required this.hasIssueLink,
    this.issueId,
    this.issueType,
  });

  /// Returns the effective due date (prefers dueWithTime over dueDay).
  DateTime? get dueDate => dueWithTime ?? (dueDay != null ? DateTime.parse(dueDay!) : null);

  /// Returns the progress as a percentage (0.0 - 1.0).
  double get progress {
    if (timeEstimate.inMilliseconds == 0) return 0.0;
    return (timeSpent.inMilliseconds / timeEstimate.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TaskModel($id, "$title", done: $isDone)';
}
