# Avodah - Project Instructions for Claude

## Build Commands

This is a **multi-package** project:

```bash
# Core package (pure Dart)
cd packages/avodah_core && dart pub get
cd packages/avodah_core && dart test

# MCP/CLI subpackage (uses dart, NOT flutter)
cd mcp && dart pub get
cd mcp && dart test
dart run mcp/bin/avo.dart       # CLI entry point
dart run mcp/bin/server.dart    # MCP server entry point

# Phone viewer app (Flutter)
cd phone && flutter pub get
cd phone && flutter test
cd phone && flutter build web --release
```

## Project Structure

```
avodah/
├── packages/avodah_core/       # Shared core package (documents, CRDT, storage)
│   ├── lib/crdt/               # CRDT primitives (HLC, LWW registers, counters)
│   ├── lib/documents/          # CRDT document types (task, project, tag, worklog, etc.)
│   ├── lib/storage/            # Drift database schema and tables
│   └── test/                   # Core package tests
├── mcp/                        # CLI + MCP server (pure Dart)
│   ├── bin/                    # Entry points (avo.dart, server.dart)
│   ├── lib/cli/                # CLI command classes
│   ├── lib/services/           # Business logic (Timer, Task, Worklog, Project, Jira)
│   ├── lib/storage/            # Drift database
│   ├── lib/config/             # Jira profile config
│   └── lib/tools/              # MCP server tool handlers
├── phone/                      # Flutter viewer app (web + android)
│   ├── lib/                    # App code
│   ├── android/                # Android build
│   └── web/                    # Web build template
└── docs/design/                # Design specs
```

## CRDT Document Pattern

1. **Fields class** - Constants for field keys
2. **Document class** - Extends `CrdtDocument<T>` with `.create()`, `.fromDrift()`, `.fromState()`
3. **Model class** - Immutable UI model

Reference: `packages/avodah_core/lib/documents/task_document.dart`

## Service Pattern (mcp/)

- Thin wrappers with `db` + `clock` injection
- Upsert via `insertOnConflictUpdate`
- ID prefix matching: exact first, then prefix, throw on ambiguous

## Testing

- Core package: `cd packages/avodah_core && dart test`
- MCP/CLI: `cd mcp && dart test`
- Phone viewer: `cd phone && flutter test`
- 700+ tests across core, CLI services, and viewer

## Versioning & Release

### Version format

- `X.Y.Z` in `packages/avodah_core/lib/version.dart` (source of truth)
- `X.Y.Z+N` in root `pubspec.yaml` (`+N` is Flutter build number)
- No beta suffixes — simple semver only

### CI behavior on push

**develop branch:** CI bumps only the build number `+N` in pubspec.yaml and version.dart. No semver change, no tag.

**main branch (no `Bump:` trailer):** CI runs tests only. No version changes, no commits.

**main branch (with `Bump:` trailer):** Add `Bump: <type>` trailer to the commit body (on its own line):
- `Bump: patch` → 0.4.0 → 0.4.1, reset `+N` to 1
- `Bump: minor` → 0.4.1 → 0.5.0, reset `+N` to 1
- `Bump: major` → 0.5.0 → 1.0.0, reset `+N` to 1
- `Bump: X.Y.Z` → exact version, reset `+N` to 1

Only explicit bumps create a git tag + GitHub Release. Build numbers (`+N`) are for develop tracking only.

### Workflow

1. Work on feature branches off `develop`
2. Merge feature PRs to `develop` (CI bumps `+N`)
3. When ready to release, squash-merge `develop` → `main` with `Bump: patch|minor|major` in the commit body
4. CI runs tests, bumps version, tags, and creates GitHub Release
5. Sync develop from main after release (no conflicts — main doesn't auto-commit `+N`)

### Skip patterns

CI skips commits starting with:
- `chore: bump version` — prevents release workflow re-trigger
- `chore: bump build` — prevents build bump loops
- `chore(ci):` — prevents CI loops

### Manual bump (escape hatch)

Only use if CI is broken or for non-standard version jumps:

```bash
dart run tool/bump_version.dart patch|minor|major|X.Y.Z
dart run tool/bump_build.dart                              # +N only
```

## Current Phase

Phase 3 (Core Features) complete. Current focus: CLI polish and E2E validation.

## Scope (MVP)

- **Platform**: Linux/NixOS only
- **Integration**: Jira only (profile-based credentials)
- **Deferred**: GitHub, TaskRepeatCfg, Note, Android/iOS, Flutter UI
