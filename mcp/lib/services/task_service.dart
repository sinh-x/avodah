/// Service layer for task operations against the SQLite database.
library;

import 'package:avodah_core/avodah_core.dart';

/// Wraps all task-related database operations.
class TaskService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  TaskService({required this.db, required this.clock});

  /// Saves a task document via upsert.
  Future<void> _saveTask(TaskDocument task) async {
    await db
        .into(db.tasks)
        .insertOnConflictUpdate(task.toDriftCompanion());
  }

  /// Creates a new task with the given title and optional project ID.
  Future<TaskDocument> add({
    required String title,
    String? projectId,
  }) async {
    final task = TaskDocument.create(
      clock: clock,
      title: title,
      projectId: projectId,
    );

    await _saveTask(task);
    return task;
  }

  /// Lists tasks from the database.
  ///
  /// By default returns only active (not done, not deleted) tasks.
  /// Set [includeCompleted] to true to include completed tasks.
  Future<List<TaskDocument>> list({bool includeCompleted = false}) async {
    final rows = await db.select(db.tasks).get();

    return rows
        .map((row) => TaskDocument.fromDrift(task: row, clock: clock))
        .where((task) {
          if (task.isDeleted) return false;
          if (!includeCompleted && task.isDone) return false;
          return true;
        })
        .toList();
  }

  /// Finds a task by exact ID or unique prefix match.
  ///
  /// Throws [TaskNotFoundException] if no task matches.
  /// Throws [AmbiguousTaskIdException] if multiple tasks match the prefix.
  Future<TaskDocument> show(String idOrPrefix) async {
    // Try exact match first
    final exactRows = await (db.select(db.tasks)
          ..where((t) => t.id.equals(idOrPrefix)))
        .get();

    if (exactRows.isNotEmpty) {
      return TaskDocument.fromDrift(task: exactRows.first, clock: clock);
    }

    // Try prefix match
    final allRows = await db.select(db.tasks).get();
    final matches = allRows
        .where((row) => row.id.startsWith(idOrPrefix))
        .toList();

    if (matches.isEmpty) {
      throw TaskNotFoundException(idOrPrefix);
    }
    if (matches.length > 1) {
      throw AmbiguousTaskIdException(
        idOrPrefix,
        matches.map((r) => r.id).toList(),
      );
    }

    return TaskDocument.fromDrift(task: matches.first, clock: clock);
  }

  /// Soft-deletes a task by exact ID or prefix match.
  ///
  /// Throws [TaskNotFoundException] if no task matches.
  /// Throws [AmbiguousTaskIdException] if multiple tasks match.
  Future<TaskDocument> delete(String idOrPrefix) async {
    final task = await show(idOrPrefix);
    task.delete();
    await _saveTask(task);
    return task;
  }

  /// Marks a task as done by exact ID or prefix match.
  ///
  /// Throws [TaskNotFoundException] if no task matches.
  /// Throws [AmbiguousTaskIdException] if multiple tasks match.
  /// Throws [TaskAlreadyDoneException] if the task is already completed.
  Future<TaskDocument> done(String idOrPrefix) async {
    final task = await show(idOrPrefix);

    if (task.isDone) {
      throw TaskAlreadyDoneException(task);
    }

    task.markDone();
    await _saveTask(task);
    return task;
  }
}

/// Thrown when no task matches the given ID or prefix.
class TaskNotFoundException implements Exception {
  final String idOrPrefix;
  TaskNotFoundException(this.idOrPrefix);

  @override
  String toString() => 'No task found matching "$idOrPrefix".';
}

/// Thrown when multiple tasks match a prefix.
class AmbiguousTaskIdException implements Exception {
  final String prefix;
  final List<String> matchingIds;
  AmbiguousTaskIdException(this.prefix, this.matchingIds);

  @override
  String toString() =>
      'Multiple tasks match "$prefix": ${matchingIds.map((id) => id.substring(0, 8)).join(', ')}. '
      'Use a longer prefix.';
}

/// Thrown when trying to mark an already-done task as done.
class TaskAlreadyDoneException implements Exception {
  final TaskDocument task;
  TaskAlreadyDoneException(this.task);

  @override
  String toString() => 'Task "${task.title}" is already done.';
}
