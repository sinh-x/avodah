/// Avodah Core - Pure Dart package with CRDT and storage logic.
///
/// This package is shared between:
/// - Flutter app (with flutter-specific database opener)
/// - MCP server / CLI (with pure Dart database opener)
library;

// CRDT primitives
export 'crdt/crdt.dart';

// Storage (Drift database)
export 'storage/database.dart';
export 'storage/tables/tasks.dart';
export 'storage/tables/subtasks.dart';
export 'storage/tables/projects.dart';
export 'storage/tables/tags.dart';
export 'storage/tables/worklogs.dart';
export 'storage/tables/jira_integrations.dart';
export 'storage/tables/timer.dart';

// CRDT Document types
export 'documents/jira_integration_document.dart';
export 'documents/project_document.dart';
export 'documents/task_document.dart';
export 'documents/timer_document.dart';
export 'documents/worklog_document.dart';
