/// Service layer for project operations against the SQLite database.
library;

import 'package:avodah_core/avodah_core.dart';

/// Wraps all project-related database operations.
class ProjectService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  ProjectService({required this.db, required this.clock});

  /// Saves a project document via upsert.
  Future<void> _saveProject(ProjectDocument project) async {
    await db
        .into(db.projects)
        .insertOnConflictUpdate(project.toDriftCompanion());
  }

  /// Creates a new project with the given title and optional icon.
  Future<ProjectDocument> add({
    required String title,
    String? icon,
  }) async {
    final project = ProjectDocument.create(
      clock: clock,
      title: title,
      icon: icon,
    );

    await _saveProject(project);
    return project;
  }

  /// Lists projects from the database.
  ///
  /// By default returns only active (not archived, not deleted) projects.
  /// Set [includeArchived] to true to include archived projects.
  Future<List<ProjectDocument>> list({bool includeArchived = false}) async {
    final rows = await db.select(db.projects).get();

    return rows
        .map((row) => ProjectDocument.fromDrift(project: row, clock: clock))
        .where((project) {
          if (project.isDeleted) return false;
          if (!includeArchived && project.isArchived) return false;
          return true;
        })
        .toList();
  }

  /// Finds a project by exact ID or unique prefix match.
  ///
  /// Throws [ProjectNotFoundException] if no project matches.
  /// Throws [AmbiguousProjectIdException] if multiple projects match.
  Future<ProjectDocument> show(String idOrPrefix) async {
    // Try exact match first
    final exactRows = await (db.select(db.projects)
          ..where((p) => p.id.equals(idOrPrefix)))
        .get();

    if (exactRows.isNotEmpty) {
      return ProjectDocument.fromDrift(project: exactRows.first, clock: clock);
    }

    // Try prefix match
    final allRows = await db.select(db.projects).get();
    final matches = allRows
        .where((row) => row.id.startsWith(idOrPrefix))
        .toList();

    if (matches.isEmpty) {
      throw ProjectNotFoundException(idOrPrefix);
    }
    if (matches.length > 1) {
      throw AmbiguousProjectIdException(
        idOrPrefix,
        matches.map((r) => r.id).toList(),
      );
    }

    return ProjectDocument.fromDrift(project: matches.first, clock: clock);
  }

  /// Returns the number of active tasks for a given project.
  Future<int> taskCount(String projectId) async {
    final rows = await db.select(db.tasks).get();
    return rows
        .map((row) => TaskDocument.fromDrift(task: row, clock: clock))
        .where((task) =>
            !task.isDeleted && !task.isDone && task.projectId == projectId)
        .length;
  }
}

/// Thrown when no project matches the given ID or prefix.
class ProjectNotFoundException implements Exception {
  final String idOrPrefix;
  ProjectNotFoundException(this.idOrPrefix);

  @override
  String toString() => 'No project found matching "$idOrPrefix".';
}

/// Thrown when multiple projects match a prefix.
class AmbiguousProjectIdException implements Exception {
  final String prefix;
  final List<String> matchingIds;
  AmbiguousProjectIdException(this.prefix, this.matchingIds);

  @override
  String toString() =>
      'Multiple projects match "$prefix": ${matchingIds.map((id) => id.substring(0, 8)).join(', ')}. '
      'Use a longer prefix.';
}
