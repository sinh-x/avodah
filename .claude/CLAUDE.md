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
- 201+ tests across 6 service suites (Timer, Task, Worklog, Project, Jira, Plan)

## Versioning & Release

### Version format

- `X.Y.Z` in `packages/avodah_core/lib/version.dart` (source of truth)
- `X.Y.Z+N` in root `pubspec.yaml` (`+N` is Flutter build number)
- No beta suffixes — simple semver only

### Automatic release (preferred)

Version bumps are **fully automated** via CI on merge to `main`. **Do NOT bump versions manually.**

1. Work on feature branches off `develop`
2. Use conventional commit prefixes — these determine the bump type:
   - `fix:` or `fix(scope):` → **patch** bump (e.g. 0.3.0 → 0.3.1)
   - `feat:` or `feat(scope):` → **minor** bump (e.g. 0.3.1 → 0.4.0)
   - `BREAKING CHANGE` in body or `feat!:` / `fix!:` → **major** bump
   - `chore:`, `refactor:`, `docs:`, `test:` → **patch** (default)
3. Merge feature PRs to `develop`
4. When ready to release, merge `develop` → `main` via PR
5. CI automatically:
   - Detects bump type from commit messages since last tag
   - Runs `tool/bump_version.dart` (updates 5 version files + CHANGELOG)
   - Resets build number to `+1`
   - Commits as `chore: bump version to X.Y.Z`
   - Tags `vX.Y.Z` and creates GitHub Release

### Skip patterns

CI skips commits starting with:
- `chore: bump version` — prevents release workflow from re-triggering itself
- `chore(ci):` — prevents CI loops

### Manual bump (escape hatch)

Only use if CI is broken or for non-standard version jumps:

```bash
dart run tool/bump_version.dart patch|minor|major|X.Y.Z
```

### Build number

`tool/bump_build.dart` increments the `+N` build number in pubspec.yaml. Used for Flutter builds only — not tied to releases.

## Current Phase

Phase 3 (Core Features) complete. Current focus: CLI polish and E2E validation.

## Scope (MVP)

- **Platform**: Linux/NixOS only
- **Integration**: Jira only (profile-based credentials)
- **Deferred**: GitHub, TaskRepeatCfg, Note, Android/iOS, Flutter UI
