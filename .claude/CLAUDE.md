# Avodah - Project Instructions for Claude

## Build Commands

This is a **multi-package** project:

```bash
# Flutter app (root)
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter test

# MCP/CLI subpackage (uses dart, NOT flutter)
cd mcp && dart pub get
cd mcp && dart test
dart run mcp/bin/avo.dart       # CLI entry point
dart run mcp/bin/server.dart    # MCP server entry point
```

## Project Structure

```
avodah/
├── lib/                        # Flutter app
│   ├── core/                   # CRDT, storage utilities
│   └── features/               # Feature modules (tasks, projects, tags, timer, settings)
├── packages/avodah_core/       # Shared core package (documents, CRDT)
├── mcp/                        # CLI + MCP server (pure Dart)
│   ├── bin/                    # Entry points (avo.dart, server.dart)
│   ├── lib/cli/                # CLI command classes
│   ├── lib/services/           # Business logic (Timer, Task, Worklog, Project, Jira)
│   ├── lib/storage/            # Drift database
│   ├── lib/config/             # Jira profile config
│   └── lib/tools/              # MCP server tool handlers
├── test/                       # Flutter app tests (mirrors lib/)
└── docs/design/                # Design specs
```

## CRDT Document Pattern

1. **Fields class** - Constants for field keys
2. **Document class** - Extends `CrdtDocument<T>` with `.create()`, `.fromDrift()`, `.fromState()`
3. **Model class** - Immutable UI model

Reference: `lib/features/tasks/models/task_document.dart`

## Service Pattern (mcp/)

- Thin wrappers with `db` + `clock` injection
- Upsert via `insertOnConflictUpdate`
- ID prefix matching: exact first, then prefix, throw on ambiguous

## Testing

- Flutter app: `flutter test`
- MCP/CLI: `cd mcp && dart test`
- 92 tests across 5 service suites (Timer, Task, Worklog, Project, Jira)

## Current Phase

Phase 3 (Core Features) complete. Current focus: CLI polish and E2E validation.

## Scope (MVP)

- **Platform**: Linux/NixOS only
- **Integration**: Jira only (profile-based credentials)
- **Deferred**: GitHub, TaskRepeatCfg, Note, Android/iOS, Flutter UI
