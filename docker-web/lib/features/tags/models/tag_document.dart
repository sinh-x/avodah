/// CRDT-backed Tag document for conflict-free synchronization.
///
/// Tags are labels that can be applied to tasks for categorization.
/// They support theming similar to projects.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:avodah_core/crdt/crdt.dart';
import 'package:avodah_core/storage/database.dart';

/// Field keys for TagDocument.
class TagFields {
  TagFields._();

  static const String title = 'title';
  static const String icon = 'icon';
  static const String taskIds = 'taskIds';
  static const String theme = 'theme';
  static const String advancedCfg = 'advancedCfg';
  static const String created = 'created';
}

/// A CRDT-backed tag document.
///
/// All fields are tracked with individual timestamps for fine-grained
/// conflict resolution during P2P sync.
class TagDocument extends CrdtDocument<TagDocument> {
  /// Creates a new tag document with a generated UUID.
  factory TagDocument.create({
    required HybridLogicalClock clock,
    required String title,
    String? icon,
    String? color,
  }) {
    final doc = TagDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.title = title;
    doc.icon = icon;
    if (color != null) {
      doc.primaryColor = color;
    }
    doc.createdTimestamp = DateTime.now();
    return doc;
  }

  /// Creates a tag document with an existing ID.
  TagDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a tag document from existing CRDT state.
  TagDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a tag document from a Drift Tag entity.
  factory TagDocument.fromDrift({
    required Tag tag,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(tag.crdtState);

    final doc = TagDocument.fromState(
      id: tag.id,
      clock: clock,
      state: state,
    );

    // If no CRDT state exists, initialize from Drift fields
    if (state.isEmpty) {
      doc._initializeFromDrift(tag);
    }

    return doc;
  }

  /// Initializes fields from Drift entity when no CRDT state exists.
  void _initializeFromDrift(Tag tag) {
    setString(TagFields.title, tag.title);
    setString(TagFields.icon, tag.icon);
    setRaw(TagFields.taskIds, tag.taskIds);
    setRaw(TagFields.theme, tag.theme);
    setRaw(TagFields.advancedCfg, tag.advancedCfg);
    setInt(TagFields.created, tag.created);
  }

  // ============================================================
  // Core Fields
  // ============================================================

  /// Tag title/name.
  String get title => getString(TagFields.title) ?? '';
  set title(String value) => setString(TagFields.title, value);

  /// Tag icon (material icon name or emoji).
  String? get icon => getString(TagFields.icon);
  set icon(String? value) => setString(TagFields.icon, value);

  /// When the tag was created.
  DateTime? get createdTimestamp {
    final ms = getInt(TagFields.created);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set createdTimestamp(DateTime? value) =>
      setInt(TagFields.created, value?.millisecondsSinceEpoch);

  // ============================================================
  // Task List
  // ============================================================

  /// Task IDs that have this tag.
  List<String> get taskIds {
    final json = getRaw(TagFields.taskIds) as String?;
    if (json == null || json.isEmpty || json == '[]') return [];
    return (jsonDecode(json) as List).cast<String>();
  }

  set taskIds(List<String> value) =>
      setRaw(TagFields.taskIds, jsonEncode(value));

  /// Number of tasks with this tag.
  int get taskCount => taskIds.length;

  /// Adds a task to this tag.
  void addTask(String taskId) {
    if (!taskIds.contains(taskId)) {
      taskIds = [...taskIds, taskId];
    }
  }

  /// Removes a task from this tag.
  void removeTask(String taskId) {
    taskIds = taskIds.where((id) => id != taskId).toList();
  }

  // ============================================================
  // Theme & Config
  // ============================================================

  /// Theme configuration (colors, etc.).
  Map<String, dynamic> get theme {
    final json = getRaw(TagFields.theme) as String?;
    if (json == null || json.isEmpty || json == '{}') return {};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  set theme(Map<String, dynamic> value) =>
      setRaw(TagFields.theme, jsonEncode(value));

  /// Advanced configuration.
  Map<String, dynamic> get advancedCfg {
    final json = getRaw(TagFields.advancedCfg) as String?;
    if (json == null || json.isEmpty || json == '{}') return {};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  set advancedCfg(Map<String, dynamic> value) =>
      setRaw(TagFields.advancedCfg, jsonEncode(value));

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

  /// Converts to a Drift TagsCompanion for insert/update.
  TagsCompanion toDriftCompanion() {
    return TagsCompanion(
      id: Value(id),
      title: Value(title),
      icon: Value(icon),
      taskIds: Value(jsonEncode(taskIds)),
      theme: Value(jsonEncode(theme)),
      advancedCfg: Value(jsonEncode(advancedCfg)),
      created: Value(createdTimestamp?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch),
      modified: Value(DateTime.now().millisecondsSinceEpoch),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  /// Converts to an immutable Tag UI model.
  TagModel toModel() {
    return TagModel(
      id: id,
      title: title,
      icon: icon,
      isDeleted: isDeleted,
      taskCount: taskCount,
      primaryColor: primaryColor,
      created: createdTimestamp,
    );
  }

  @override
  TagDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return TagDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable tag model for UI consumption.
class TagModel {
  final String id;
  final String title;
  final String? icon;
  final bool isDeleted;
  final int taskCount;
  final String? primaryColor;
  final DateTime? created;

  const TagModel({
    required this.id,
    required this.title,
    this.icon,
    required this.isDeleted,
    required this.taskCount,
    this.primaryColor,
    this.created,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TagModel($id, "$title")';
}
