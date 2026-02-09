/// CRDT-backed Project document for conflict-free synchronization.
///
/// Projects are containers for organizing tasks. They support theming,
/// backlog management, and integration with external issue trackers.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crdt/crdt.dart';
import '../../../core/storage/database.dart';

/// Field keys for ProjectDocument.
class ProjectFields {
  ProjectFields._();

  static const String title = 'title';
  static const String isArchived = 'isArchived';
  static const String isHiddenFromMenu = 'isHiddenFromMenu';
  static const String isEnableBacklog = 'isEnableBacklog';
  static const String taskIds = 'taskIds';
  static const String backlogTaskIds = 'backlogTaskIds';
  static const String theme = 'theme';
  static const String advancedCfg = 'advancedCfg';
  static const String icon = 'icon';
  static const String created = 'created';
}

/// A CRDT-backed project document.
///
/// All fields are tracked with individual timestamps for fine-grained
/// conflict resolution during P2P sync.
class ProjectDocument extends CrdtDocument<ProjectDocument> {
  /// Creates a new project document with a generated UUID.
  factory ProjectDocument.create({
    required HybridLogicalClock clock,
    required String title,
    String? icon,
  }) {
    final doc = ProjectDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.title = title;
    doc.icon = icon;
    doc.isArchived = false;
    doc.isHiddenFromMenu = false;
    doc.isEnableBacklog = false;
    doc.createdTimestamp = DateTime.now();
    return doc;
  }

  /// Creates a project document with an existing ID.
  ProjectDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a project document from existing CRDT state.
  ProjectDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a project document from a Drift Project entity.
  factory ProjectDocument.fromDrift({
    required Project project,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(project.crdtState);

    final doc = ProjectDocument.fromState(
      id: project.id,
      clock: clock,
      state: state,
    );

    // If no CRDT state exists, initialize from Drift fields
    if (state.isEmpty) {
      doc._initializeFromDrift(project);
    }

    return doc;
  }

  /// Initializes fields from Drift entity when no CRDT state exists.
  void _initializeFromDrift(Project project) {
    setString(ProjectFields.title, project.title);
    setBool(ProjectFields.isArchived, project.isArchived);
    setBool(ProjectFields.isHiddenFromMenu, project.isHiddenFromMenu);
    setBool(ProjectFields.isEnableBacklog, project.isEnableBacklog);
    setRaw(ProjectFields.taskIds, project.taskIds);
    setRaw(ProjectFields.backlogTaskIds, project.backlogTaskIds);
    setRaw(ProjectFields.theme, project.theme);
    setRaw(ProjectFields.advancedCfg, project.advancedCfg);
    setString(ProjectFields.icon, project.icon);
    setInt(ProjectFields.created, project.created);
  }

  // ============================================================
  // Core Fields
  // ============================================================

  /// Project title/name.
  String get title => getString(ProjectFields.title) ?? '';
  set title(String value) => setString(ProjectFields.title, value);

  /// Whether the project is archived.
  bool get isArchived => getBool(ProjectFields.isArchived) ?? false;
  set isArchived(bool value) => setBool(ProjectFields.isArchived, value);

  /// Whether the project is hidden from menu.
  bool get isHiddenFromMenu => getBool(ProjectFields.isHiddenFromMenu) ?? false;
  set isHiddenFromMenu(bool value) =>
      setBool(ProjectFields.isHiddenFromMenu, value);

  /// Whether backlog feature is enabled.
  bool get isEnableBacklog => getBool(ProjectFields.isEnableBacklog) ?? false;
  set isEnableBacklog(bool value) =>
      setBool(ProjectFields.isEnableBacklog, value);

  /// Project icon (material icon name or emoji).
  String? get icon => getString(ProjectFields.icon);
  set icon(String? value) => setString(ProjectFields.icon, value);

  /// When the project was created.
  DateTime? get createdTimestamp {
    final ms = getInt(ProjectFields.created);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set createdTimestamp(DateTime? value) =>
      setInt(ProjectFields.created, value?.millisecondsSinceEpoch);

  // ============================================================
  // Task Lists
  // ============================================================

  /// Task IDs in this project (ordered).
  List<String> get taskIds {
    final json = getRaw(ProjectFields.taskIds) as String?;
    if (json == null || json.isEmpty || json == '[]') return [];
    return (jsonDecode(json) as List).cast<String>();
  }

  set taskIds(List<String> value) =>
      setRaw(ProjectFields.taskIds, jsonEncode(value));

  /// Backlog task IDs (ordered).
  List<String> get backlogTaskIds {
    final json = getRaw(ProjectFields.backlogTaskIds) as String?;
    if (json == null || json.isEmpty || json == '[]') return [];
    return (jsonDecode(json) as List).cast<String>();
  }

  set backlogTaskIds(List<String> value) =>
      setRaw(ProjectFields.backlogTaskIds, jsonEncode(value));

  /// Adds a task to this project.
  void addTask(String taskId, {bool toBacklog = false}) {
    if (toBacklog) {
      if (!backlogTaskIds.contains(taskId)) {
        backlogTaskIds = [...backlogTaskIds, taskId];
      }
    } else {
      if (!taskIds.contains(taskId)) {
        taskIds = [...taskIds, taskId];
      }
    }
  }

  /// Removes a task from this project.
  void removeTask(String taskId) {
    taskIds = taskIds.where((id) => id != taskId).toList();
    backlogTaskIds = backlogTaskIds.where((id) => id != taskId).toList();
  }

  /// Moves a task to/from backlog.
  void moveTaskToBacklog(String taskId) {
    taskIds = taskIds.where((id) => id != taskId).toList();
    if (!backlogTaskIds.contains(taskId)) {
      backlogTaskIds = [...backlogTaskIds, taskId];
    }
  }

  void moveTaskFromBacklog(String taskId) {
    backlogTaskIds = backlogTaskIds.where((id) => id != taskId).toList();
    if (!taskIds.contains(taskId)) {
      taskIds = [...taskIds, taskId];
    }
  }

  // ============================================================
  // Theme & Config
  // ============================================================

  /// Theme configuration (colors, etc.).
  Map<String, dynamic> get theme {
    final json = getRaw(ProjectFields.theme) as String?;
    if (json == null || json.isEmpty || json == '{}') return {};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  set theme(Map<String, dynamic> value) =>
      setRaw(ProjectFields.theme, jsonEncode(value));

  /// Advanced configuration (worklog export, etc.).
  Map<String, dynamic> get advancedCfg {
    final json = getRaw(ProjectFields.advancedCfg) as String?;
    if (json == null || json.isEmpty || json == '{}') return {};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  set advancedCfg(Map<String, dynamic> value) =>
      setRaw(ProjectFields.advancedCfg, jsonEncode(value));

  /// Gets the primary color from theme.
  String? get primaryColor => theme['primary'] as String?;

  /// Sets the primary color in theme.
  set primaryColor(String? value) {
    final current = theme;
    if (value == null) {
      current.remove('primary');
    } else {
      current['primary'] = value;
    }
    theme = current;
  }

  // ============================================================
  // Conversion
  // ============================================================

  /// Converts to a Drift ProjectsCompanion for insert/update.
  ProjectsCompanion toDriftCompanion() {
    return ProjectsCompanion(
      id: Value(id),
      title: Value(title),
      isArchived: Value(isArchived),
      isHiddenFromMenu: Value(isHiddenFromMenu),
      isEnableBacklog: Value(isEnableBacklog),
      taskIds: Value(jsonEncode(taskIds)),
      backlogTaskIds: Value(jsonEncode(backlogTaskIds)),
      theme: Value(jsonEncode(theme)),
      advancedCfg: Value(jsonEncode(advancedCfg)),
      icon: Value(icon),
      created: Value(createdTimestamp?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch),
      modified: Value(DateTime.now().millisecondsSinceEpoch),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  /// Converts to an immutable Project UI model.
  ProjectModel toModel() {
    return ProjectModel(
      id: id,
      title: title,
      icon: icon,
      isArchived: isArchived,
      isHiddenFromMenu: isHiddenFromMenu,
      isEnableBacklog: isEnableBacklog,
      isDeleted: isDeleted,
      taskCount: taskIds.length,
      backlogCount: backlogTaskIds.length,
      primaryColor: primaryColor,
      created: createdTimestamp,
    );
  }

  @override
  ProjectDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return ProjectDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable project model for UI consumption.
class ProjectModel {
  final String id;
  final String title;
  final String? icon;
  final bool isArchived;
  final bool isHiddenFromMenu;
  final bool isEnableBacklog;
  final bool isDeleted;
  final int taskCount;
  final int backlogCount;
  final String? primaryColor;
  final DateTime? created;

  const ProjectModel({
    required this.id,
    required this.title,
    this.icon,
    required this.isArchived,
    required this.isHiddenFromMenu,
    required this.isEnableBacklog,
    required this.isDeleted,
    required this.taskCount,
    required this.backlogCount,
    this.primaryColor,
    this.created,
  });

  /// Total tasks including backlog.
  int get totalTaskCount => taskCount + backlogCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProjectModel($id, "$title")';
}
