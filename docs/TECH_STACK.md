# Avodah — Tech Stack

> Version 0.4.2 | Last updated: 2026-03-10

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Avodah Ecosystem                      │
├──────────────┬──────────────┬──────────────┬────────────┤
│  Flutter App  │   CLI (avo)  │  MCP Server  │ Phone App  │
│   lib/        │  mcp/bin/    │  mcp/bin/    │  phone/    │
│   (desktop)   │  avo.dart    │  server.dart │  (viewer)  │
├──────────────┴──────┬───────┴──────────────┴────────────┤
│                     │                                    │
│   avodah_core       │        Sync Server                 │
│   packages/         │        mcp/bin/sync_server.dart    │
│   (shared CRDT)     │        (WebSocket push)            │
├─────────────────────┴────────────────────────────────────┤
│                    SQLite (Drift)                         │
│                ~/.local/share/avodah/avodah.db           │
└──────────────────────────────────────────────────────────┘
```

## Languages & Runtimes

| Component | Language | SDK Constraint |
|-----------|----------|----------------|
| Flutter app (`lib/`) | Dart | ^3.10.8 |
| MCP/CLI (`mcp/`) | Dart (pure, no Flutter) | ^3.0.0 |
| Shared core (`packages/avodah_core/`) | Dart | ^3.10.8 |
| Phone viewer (`phone/`) | Dart (Flutter) | ^3.10.8 |
| Build system | Nix (flake) | nixos-unstable |

## Package Structure

```
avodah/
├── lib/                          # Flutter desktop app (UI shell)
│   ├── core/                     # CRDT, storage, database
│   ├── features/                 # tasks, projects, tags, timer, settings
│   └── shared/                   # router, scaffold, theme
├── packages/avodah_core/         # Shared Dart package (CRDT, documents)
│   └── lib/
│       ├── crdt/                 # HLC, LWW register, G-counter, LWW set
│       ├── documents/            # Task, Project, Tag, Worklog documents
│       └── version.dart          # Single source of truth for version
├── mcp/                          # CLI + MCP server (pure Dart)
│   ├── bin/
│   │   ├── avo.dart              # CLI entry point
│   │   ├── server.dart           # MCP server (stdio)
│   │   └── sync_server.dart      # WebSocket sync server
│   ├── lib/cli/                  # CLI commands
│   ├── lib/services/             # Business logic
│   ├── lib/storage/              # Drift database
│   ├── lib/config/               # Jira profiles, AvoConfig
│   └── lib/tools/                # MCP tool handlers
├── phone/                        # Read-only Android viewer
│   └── lib/
│       ├── models/               # Snapshot models (plain Dart)
│       ├── screens/              # Dashboard UI
│       └── services/             # WebSocket client
├── tool/                         # Dev scripts
│   ├── bump_version.dart         # Semver bumping
│   └── bump_build.dart           # Build number (+N)
├── completions/                  # Shell completions
│   └── avo.fish                  # Fish dynamic completions
└── .github/workflows/            # CI/CD
    ├── ci.yml                    # Build + test + build-number bump
    └── release.yml               # Semver bump + tag + GitHub Release
```

## Database

| Aspect | Details |
|--------|---------|
| Engine | SQLite |
| ORM | Drift 2.22.1+ |
| Schema version | 10 |
| Location | `~/.local/share/avodah/avodah.db` |
| Code generation | `drift_dev` via `build_runner` |

### Tables (9)

| Table | Purpose |
|-------|---------|
| `tasks` | Task entries with CRDT state |
| `subtasks` | Sub-tasks (schema ready, feature deferred) |
| `projects` | Project grouping |
| `tags` | Tagging system (schema ready, feature deferred) |
| `worklog_entries` | Time tracking records |
| `jira_integrations` | Jira sync metadata |
| `timer_entries` | Current timer state |
| `daily_plan_entries` | Daily planning containers |
| `day_plan_tasks` | Task ↔ daily plan links |

## State Management

| Library | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | 3.1.0 | Reactive UI state |
| riverpod_annotation | 4.0.0 | Declarative provider definitions |
| riverpod_generator | 4.0.0+1 | Provider code generation |

## CRDT (Conflict-free Replicated Data Types)

Custom implementation in `packages/avodah_core/lib/crdt/`:

| Primitive | Description |
|-----------|-------------|
| **HLC** (Hybrid Logical Clock) | `{physicalTime}-{counter}-{nodeId}` — per-field timestamps |
| **LWW Register** (Last-Write-Wins) | Single-value conflict resolution by timestamp |
| **LWW Map** | Per-field LWW tracking across all document fields |
| **LWW Set** | Soft-delete support via `isDeleted` flag |
| **G-Counter** | Monotonic grow-only counter |

### Document Pattern

```
Fields class    → Constants for field keys
Document class  → Extends CrdtDocument<T> with .create(), .fromDrift(), .fromState()
Model class     → Immutable UI representation (@freezed)
```

Node ID persisted at `~/.local/share/avodah/node_id.txt`.

## CLI Framework

| Library | Version | Purpose |
|---------|---------|---------|
| args | 2.4.0 | Command runner, argument parsing |
| dart_console | 4.1.2 | Readline with arrow keys, interactive picker |

### Commands

Top-level: `start`, `stop`, `status`, `pause`, `resume`, `cancel`, `log`, `recent`, `today`, `daily`, `week`, `plan`

Subcommands: `task {add,list,show,done,undone,delete,undelete,due,cat,note}`, `project {add,list,show,delete}`, `worklog {add,edit,list,delete}`, `jira {sync,push,pull,status}`, `db {info,tables,query,vacuum}`

## MCP Server

| Aspect | Details |
|--------|---------|
| Protocol | JSON-RPC 2.0 |
| Transport | stdio (stdin/stdout) |
| Implementation | `mcp/lib/tools/mcp_server.dart` |

### MCP Tools

`timer`, `tasks`, `worklog`, `project`, `plan`, `today`, `daily`, `week`, `status`, `jira`

### MCP Resources

`avodah://status` — Current timer + today summary (read-only)

## Sync System

| Aspect | Details |
|--------|---------|
| Protocol | WebSocket over HTTP |
| Direction | One-way: server → client (push) |
| Default port | 9847 |
| Interval | 30 seconds (configurable) |
| Deduplication | Skips broadcast if JSON unchanged |
| Payload | `DaySnapshot` JSON (timer, plan, tasks, worklogs) |

### Phone Viewer

Separate Flutter app (`phone/`) — read-only dashboard:
- WebSocket client with auto-reconnect (exponential backoff)
- Displays: timer bar, plan-vs-actual table, planned tasks, worklog summary
- Connection state indicator
- Dependencies: `web_socket_channel: ^3.0.0`, `shared_preferences: ^2.2.0`

## External Integrations

### Jira (MVP scope)

| Aspect | Details |
|--------|---------|
| HTTP client | `http: ^1.2.0` |
| Auth | API token per profile |
| Sync | 2-way (Avodah ↔ Jira) |
| Config | `~/.config/avodah/jira/profiles/<name>.json` |
| Features | Issue sync, worklog sync, auto-categorization, dirty flag tracking |

**Deferred**: GitHub, GitLab, Redmine, CalDAV

## Configuration

### User config (`~/.config/avodah/config.json`)

```json
{
  "categories": ["Learning", "Working", "Side-project", "Family & Friends", "Personal"],
  "sync": {
    "port": 9847,
    "intervalSeconds": 30
  }
}
```

### Jira profile (`~/.config/avodah/jira/profiles/<name>.json`)

```json
{
  "name": "work",
  "baseUrl": "https://jira.company.com",
  "username": "user@company.com",
  "apiToken": "...",
  "defaultCategory": "Working",
  "workStatuses": ["In Progress", "In Review"]
}
```

## Code Generation

| Tool | Generates |
|------|-----------|
| `build_runner` 2.4.13 | Orchestrates all generators |
| `freezed` 3.2.3 | Immutable data classes with `.copyWith()`, `.fromJson()` |
| `json_serializable` 6.8.0 | JSON serialization/deserialization |
| `drift_dev` 2.22.1 | Database schema, type-safe queries |
| `riverpod_generator` 4.0.0+1 | Riverpod providers |

```bash
# Regenerate all
flutter pub run build_runner build --delete-conflicting-outputs
```

## Testing

| Suite | Location | Runner |
|-------|----------|--------|
| Timer, Task, Worklog, Plan, Project, Jira, SyncSnapshot, DbCommands | `mcp/test/` | `dart test` |
| CRDT, Documents, Database, Format | `test/` | `flutter test` |

**~266 tests** across 8+ suites, ~5000 lines of test code.

Test runner script: `tool/run_tests.sh` (JSON reporter, clean summary)

## CI/CD (GitHub Actions)

### `ci.yml` — Build & Test
- **Trigger**: push/PR to `main`, `develop`
- Flutter setup → `pub get` → `dart test` (MCP) → `flutter build linux --debug`
- On `develop`: bumps `+N` build number after success

### `release.yml` — Versioning & Release
- **Trigger**: push to `main`
- Detects `Bump: patch|minor|major|X.Y.Z` trailer in commit body
- Bumps version → resets `+N` to 1 → git tag → GitHub Release
- No trailer = tests only, no version change

### Skip patterns
`chore: bump version`, `chore: bump build`, `chore(ci):`

## Build System (Nix)

### Dev shell provides
- Flutter SDK + Dart SDK
- Android SDK (cmdLineTools 11.0, platformTools 35.0.2, buildTools 35.0.0, platforms 34+35)
- JDK 17
- Linux desktop deps: GTK3, glib, cairo, pango, harfbuzz, X11, libGL, sqlite
- CMake, Ninja, Clang, pkg-config

### Nix packages
- `packages.default` / `packages.avo` — CLI built with `buildDartApplication`
- `overlays.default` — NixOS overlay for system-wide install

### Dev shell scripts
| Script | Command |
|--------|---------|
| `avo-run` | `flutter run -d linux` |
| `avo-run-android` | `flutter run -d android` |
| `avo-build` | `flutter build linux --release` |
| `avo-build-android` | `flutter build apk --release` |
| `avo-test` | `flutter test` |
| `avo-analyze` | `flutter analyze` |
| `avo-clean` | `flutter clean && flutter pub get` |
| `avo` | Native-compiled CLI |
| `avodah-mcp` | Native-compiled MCP server |
| `avodah-sync` | Native-compiled sync server |

## Shell Completions

Fish shell (`completions/avo.fish`):
- Dynamic task/project ID completions via `avo task list --format completion`
- Subcommand, option, and flag completions
- Installed via Nix: `installShellCompletion --fish`

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux desktop | **MVP** ✓ | Primary target, GTK3 |
| Android | Buildable | APK builds, not primary focus |
| Web (Chrome) | Functional | Debug mode works, UI incomplete |
| Windows | Deferred | Not in MVP scope |
| macOS | Deferred | Not in MVP scope |
| iOS | Deferred | Not in MVP scope |

## Linting

| Package | Lint rules |
|---------|------------|
| Flutter app | `flutter_lints: ^6.0.0` |
| MCP/CLI | `lints: ^5.0.0` |
| Phone viewer | `flutter_lints: ^6.0.0` |
| Shared core | `lints: ^5.1.1` |
