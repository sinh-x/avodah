# MCP Worklog Tracker - Design Document

> **Status**: Draft
> **Created**: 2025-02-10
> **Context**: MVP for testing CRDT data structures via CLI/MCP before building Flutter UI

---

## 0. Key Design Principles

### 0.1 Minimal MCP Footprint

The MCP server must NOT bloat Claude Code's context or degrade user experience.

**Guidelines**:
- **Few tools**: Only essential tools, avoid feature creep
- **Terse responses**: Return minimal JSON, not verbose explanations
- **No automatic polling**: Don't call `timer_status` repeatedly
- **Lazy loading**: Don't pre-load all tasks/projects on startup

**Tool response philosophy**:
```
❌ Bad: "The timer has been successfully started for the task 'Implement MCP'.
        You are now tracking time. The timer began at 14:32:05 UTC..."

✅ Good: { "status": "running", "task": "Implement MCP", "started": "14:32" }
```

### 0.2 Human-Friendly CLI

The CLI must be pleasant for humans to use directly, not just as an MCP backend.

**Guidelines**:
- **Simple commands**: `avodah start "task"` not `avodah timer start --title "task"`
- **Smart defaults**: No required flags for common operations
- **Readable output**: Formatted for terminal, not JSON dumps
- **Quick access**: Alias-friendly (e.g., `av start`, `av stop`)

**Example workflow**:
```bash
$ avo start "Fix login bug"      # Human starts timer
$ avo status                     # Quick check
Timer: Fix login bug (1h 23m)

$ avo stop                       # Human or Claude can stop
Logged 1h 23m → Fix login bug
```

### 0.3 Human ↔ Claude Interoperability

Timer state is shared. Either party can start/stop without confusion.

**Scenarios that must work**:
| Started by | Stopped by | Result |
|------------|------------|--------|
| Human (CLI) | Human (CLI) | ✅ Worklog created |
| Human (CLI) | Claude (MCP) | ✅ Worklog created |
| Claude (MCP) | Human (CLI) | ✅ Worklog created |
| Claude (MCP) | Claude (MCP) | ✅ Worklog created |

**Implementation**:
- Single source of truth: `TimerDocument` in SQLite
- No "ownership" of timer - anyone can control it
- CLI and MCP use identical business logic
- Status always reflects current reality

**Edge cases**:
- Human starts timer, walks away → Claude can report status or stop
- Claude starts timer, user runs `av status` → Shows Claude-started timer
- Both try to start simultaneously → CRDT LWW resolves (last write wins)

---

## 1. Decision Record

### 1.1 Problem Statement

Need to validate the CRDT data structures and business logic before investing in Flutter UI development. Want a practical tool that:
- Tests real-world usage patterns
- Provides immediate value (worklog tracking during development)
- Can be used by Claude Code to assist with time tracking

### 1.2 Chosen Approach: MCP Server + CLI

**Decision**: Build a Model Context Protocol (MCP) server within this repo that:
- Uses the existing CRDT document implementations
- Stores data in SQLite via Drift (same as Flutter app)
- Exposes tools for Claude Code to track work time
- Can also be used as a standalone CLI

**Rationale**:
- **Shared codebase**: MCP imports `lib/core/crdt/` directly
- **Single database**: Same SQLite file for both MCP and Flutter app
- **Practical testing**: Real usage validates the CRDT design
- **Immediate value**: Track time while building the app itself

### 1.3 Storage Decision: SQLite is Portable

Initial concern was that Drift/SQLite requires Flutter. This is **incorrect**:

| Context | SQLite Package | Works? |
|---------|----------------|--------|
| Flutter app | `sqlite3_flutter_libs` | ✅ Bundles SQLite |
| Pure Dart CLI/MCP | `sqlite3` | ✅ Uses system SQLite |
| Tests | `sqlite3` | ✅ Already used |

**Conclusion**: Both MCP and Flutter app can read/write the same `.db` file.

### 1.4 Architecture Decision

```
avodah/
├── lib/                      # Flutter app (existing)
│   ├── core/crdt/            # Pure Dart CRDT - SHARED
│   ├── core/storage/         # Drift database - SHARED
│   └── features/*/models/    # Document models - SHARED
├── mcp/                      # MCP server (new)
│   ├── bin/server.dart       # MCP entry point
│   ├── lib/
│   │   ├── tools/            # MCP tool handlers
│   │   └── cli/              # CLI commands
│   └── pubspec.yaml          # Separate Dart package
└── ~/.local/share/avodah/    # XDG data directory
    └── avodah.db             # SQLite database
```

**Key Decisions**:
1. **Separate package**: `mcp/` has its own pubspec.yaml to avoid Flutter widget deps
2. **Shared Drift schema**: Uses same database schema as Flutter app
3. **SQLite storage**: Single `.db` file, portable and consistent
4. **XDG data location**: Follows Linux standards (see Section 2.5)

---

## 2. Data System Status

### 2.1 Existing CRDT Infrastructure (Complete)

| Component | Location | Status | Description |
|-----------|----------|--------|-------------|
| `HybridLogicalClock` | `lib/core/crdt/hlc.dart` | ✅ | HLC for distributed timestamps |
| `HybridTimestamp` | `lib/core/crdt/hlc.dart` | ✅ | Packed timestamp with nodeId |
| `LWWRegister<T>` | `lib/core/crdt/lww_register.dart` | ✅ | Last-Writer-Wins register |
| `LWWMap<K,V>` | `lib/core/crdt/lww_register.dart` | ✅ | Map with per-key timestamps |
| `LWWSet<T>` | `lib/core/crdt/lww_set.dart` | ✅ | Set with add/remove tracking |
| `GCounter` | `lib/core/crdt/g_counter.dart` | ✅ | Grow-only counter |
| `CrdtDocument<T>` | `lib/core/crdt/crdt_document.dart` | ✅ | Base class for all documents |

### 2.2 Existing Domain Documents (Complete)

| Document | Location | Status | MCP Usage |
|----------|----------|--------|-----------|
| `TaskDocument` | `lib/features/tasks/models/task_document.dart` | ✅ | Track time against tasks |
| `ProjectDocument` | `lib/features/projects/models/project_document.dart` | ✅ | Organize tasks |
| `WorklogDocument` | `lib/features/worklog/models/worklog_document.dart` | ✅ | Store time entries |
| `TagDocument` | `lib/features/tags/models/tag_document.dart` | ✅ | Categorize tasks |
| `SubtaskDocument` | `lib/features/tasks/models/subtask_document.dart` | ✅ | Task breakdown |
| `JiraIntegrationDocument` | `lib/features/integrations/models/jira_integration_document.dart` | ✅ | Future: Jira sync |

### 2.3 Additional Documents Needed

- [ ] **TimerDocument** - Active timer state (NEW)

  **Purpose**: Track currently running timer with crash recovery and sync support

  **Fields**:
  | Field | Type | Description |
  |-------|------|-------------|
  | `taskId` | String? | Task being timed (null = ad-hoc) |
  | `taskTitle` | String | Denormalized for display |
  | `projectId` | String? | Project context |
  | `projectTitle` | String? | Denormalized for display |
  | `startedAt` | int | Unix ms when timer started |
  | `isRunning` | bool | Timer state |
  | `pausedAt` | int? | Unix ms when paused |
  | `accumulatedMs` | int | Time accumulated before pause |
  | `note` | String? | What you're working on |

  **State Machine**:
  ```
  [idle] ──start──> [running] ──pause──> [paused]
                        │                    │
                        └───────stop─────────┘
                                 │
                                 v
                        [WorklogDocument created]
                        [Timer reset to idle]
  ```

  **CRDT Behavior**:
  - Single timer document (well-known ID: `active-timer`)
  - Last-write-wins for all fields
  - Conflict: If started on two devices, most recent start wins

### 2.4 Storage Layer

**Existing Infrastructure** (reuse from Flutter app):
- ✅ `AppDatabase` - Drift database class (`lib/core/storage/database.dart`)
- ✅ All table definitions in `lib/core/storage/tables/`
- ✅ CRDT state columns on all tables (`crdtClock`, `crdtState`)

**Additional Needed**:

- [ ] **TimerEntries table** - Drift table for timer state (NEW)

  **Location**: `lib/core/storage/tables/timer.dart`

  ```dart
  class TimerEntries extends Table {
    TextColumn get id => text()();  // Well-known: 'active-timer'
    TextColumn get taskId => text().nullable()();
    TextColumn get taskTitle => text()();
    TextColumn get projectId => text().nullable()();
    TextColumn get projectTitle => text().nullable()();
    IntColumn get startedAt => integer()();  // Unix ms
    BoolColumn get isRunning => boolean().withDefault(const Constant(false))();
    IntColumn get pausedAt => integer().nullable()();
    IntColumn get accumulatedMs => integer().withDefault(const Constant(0))();
    TextColumn get note => text().nullable()();

    // CRDT metadata
    TextColumn get crdtClock => text().withDefault(const Constant(''))();
    TextColumn get crdtState => text().withDefault(const Constant('{}'))();

    @override
    Set<Column> get primaryKey => {id};
  }
  ```

- [ ] **Database initializer for MCP** - Pure Dart database opener (NEW)

  **Purpose**: Open Drift database without Flutter dependencies

  **Location**: `mcp/lib/storage/database_opener.dart`

  ```dart
  import 'package:drift/native.dart';
  import 'package:sqlite3/sqlite3.dart';

  AppDatabase openDatabase(String path) {
    return AppDatabase(NativeDatabase.createInBackground(File(path)));
  }
  ```

### 2.5 Linux Storage Locations (XDG Specification)

Following the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

| Purpose | XDG Variable | Default Path | Avodah Path |
|---------|--------------|--------------|-------------|
| **Data** (DB) | `XDG_DATA_HOME` | `~/.local/share` | `~/.local/share/avodah/avodah.db` |
| **Config** | `XDG_CONFIG_HOME` | `~/.config` | `~/.config/avodah/config.toml` |
| **State/Logs** | `XDG_STATE_HOME` | `~/.local/state` | `~/.local/state/avodah/logs/` |
| **Cache** | `XDG_CACHE_HOME` | `~/.cache` | `~/.cache/avodah/` |

#### Directory Structure

```
~/.local/share/avodah/
└── avodah.db                  # SQLite database (Drift)

~/.config/avodah/
├── config.toml                # User settings
├── node-id                    # Unique node identifier (auto-generated)
└── jira-credentials.json      # Future: Jira authentication

~/.local/state/avodah/
└── logs/                      # Debug logs (optional)
```

#### User Override Options

**Priority (highest to lowest)**:

1. **CLI flag**: `--data-dir /custom/path`
2. **Environment variable**: `AVODAH_DATA_DIR=/custom/path`
3. **Config file**: Setting in `~/.config/avodah/config.toml`
4. **XDG default**: `~/.local/share/avodah/`

#### Config File Format

```toml
# ~/.config/avodah/config.toml

[storage]
# Override data directory (optional)
# data_dir = "/custom/path/avodah"

[node]
# Unique node ID for CRDT (auto-generated if missing)
# id = "laptop-abc123"

[integrations.jira]
# Jira credentials file path (future)
# credentials = "~/.config/avodah/jira-credentials.json"
```

#### Path Resolution Logic

```dart
// mcp/lib/config/paths.dart

import 'dart:io';

class AvodahPaths {
  /// Get data directory following XDG spec with overrides
  static String getDataDir({String? cliOverride}) {
    // 1. CLI flag (highest priority)
    if (cliOverride != null) return cliOverride;

    // 2. Environment variable
    final envOverride = Platform.environment['AVODAH_DATA_DIR'];
    if (envOverride != null) return envOverride;

    // 3. TODO: Check config.toml

    // 4. XDG default
    final xdgData = Platform.environment['XDG_DATA_HOME']
        ?? '${Platform.environment['HOME']}/.local/share';
    return '$xdgData/avodah';
  }

  /// Get config directory
  static String getConfigDir() {
    final xdgConfig = Platform.environment['XDG_CONFIG_HOME']
        ?? '${Platform.environment['HOME']}/.config';
    return '$xdgConfig/avodah';
  }

  /// Get database file path
  static String getDatabasePath({String? dataDir}) {
    return '${dataDir ?? getDataDir()}/avodah.db';
  }

  /// Get or generate node ID
  static String getNodeId() {
    final configDir = getConfigDir();
    final nodeIdFile = File('$configDir/node-id');

    if (nodeIdFile.existsSync()) {
      return nodeIdFile.readAsStringSync().trim();
    }

    // Generate new node ID
    final nodeId = 'node-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    Directory(configDir).createSync(recursive: true);
    nodeIdFile.writeAsStringSync(nodeId);
    return nodeId;
  }
}
```

---

## 3. CLI Tools Design

### 3.1 Command Structure

```bash
avo <command> [subcommand] [options]
```

### 3.2 Timer Commands

| Command | Description | Example |
|---------|-------------|---------|
| `avo start [task]` | Start timer (new task) | `avo start "Review PR #123"` |
| `avo start --task-id <id>` | Start timer on existing task | `avo start --task-id abc123` |
| `avo stop` | Stop timer, create worklog | `avo stop` |
| `avo stop --note "Done"` | Stop with note | `avo stop --note "Fixed the bug"` |
| `avo pause` | Pause running timer | `avo pause` |
| `avo resume` | Resume paused timer | `avo resume` |
| `avo status` | Show timer status | `avo status` |
| `avo cancel` | Cancel timer without logging | `avo cancel` |

**Output Examples**:

```bash
$ avo start "Implement MCP server"
Timer started: Implement MCP server
  Started at: 14:32

$ avo status
Timer running: Implement MCP server
  Duration: 1h 23m
  Started: 14:32

$ avo stop
Logged 1h 23m on: Implement MCP server
  Task ID: abc-123
  Worklog ID: def-456
```

### 3.3 Task Commands

| Command | Description | Example |
|---------|-------------|---------|
| `avo task add <title>` | Create task | `avo task add "Fix login bug"` |
| `avo task add <title> -p <project>` | Create in project | `avo task add "API endpoint" -p backend` |
| `avo task list` | List active tasks | `avo task list` |
| `avo task list -a` | List all (inc. done) | `avo task list -a` |
| `avo task done <id>` | Mark complete | `avo task done abc123` |
| `avo task show <id>` | Show task details | `avo task show abc123` |

**Output Examples**:

```bash
$ avo task list
Active Tasks:
  [abc123] Implement MCP server (backend)    2h 15m
  [def456] Write documentation               0m
  [ghi789] PROJ-42 Fix login bug             45m     ← from Jira
  [jkl012] PROJ-99 Review PR                 30m     ← from Jira

$ avo task add "Add unit tests" -p backend
Created task: Add unit tests
  ID: mno345
  Project: backend
```

### 3.4 Worklog Commands

| Command | Description | Example |
|---------|-------------|---------|
| `avo log <duration> <task>` | Manual entry | `avo log 30m "Quick fix"` |
| `avo log <duration> --task-id <id>` | Log to existing task | `avo log 1h --task-id abc123` |
| `avo today` | Today's summary | `avo today` |
| `avo week` | This week's summary | `avo week` |
| `avo worklog list` | Recent worklogs | `avo worklog list` |

**Output Examples**:

```bash
$ avo today
Today (Mon, Feb 10):
  backend:
    Implement MCP server    2h 15m
    Add unit tests           45m
  frontend:
    Review PR #42            30m
  ─────────────────────────────
  Total:                    3h 30m

$ avo week
This Week:
  Mon    3h 30m  ████████░░
  Tue    0h  0m  ░░░░░░░░░░
  ...
  ─────────────────────────────
  Total: 3h 30m
```

### 3.5 Project Commands

| Command | Description | Example |
|---------|-------------|---------|
| `avo project add <title>` | Create project | `avo project add "Backend API"` |
| `avo project list` | List projects | `avo project list` |
| `avo project show <id>` | Show with tasks | `avo project show backend` |

### 3.6 Jira Sync Commands

| Command | Description | Example |
|---------|-------------|---------|
| `avo jira sync` | Bidirectional sync | `avo jira sync` |
| `avo jira status` | Show sync status | `avo jira status` |
| `avo jira setup` | Configure Jira connection | `avo jira setup` |

**Output Examples**:

```bash
$ avo jira sync
Syncing with Jira...
  ↓ Pulled 3 issues from PROJ
  ↑ Pushed 2 worklogs

Conflicts found (3):

1/3 Task PROJ-123 title:
    Local: "Fix login bug - updated"
    Jira:  "Fix login bug (urgent)"
    [L]ocal  [J]ira  [S]kip > L

2/3 Task PROJ-123 description:
    Local: (empty)
    Jira:  "See attached screenshot..."
    [L]ocal  [J]ira  [S]kip > J

3/3 Worklog PROJ-456 (today):
    Local: 2h 30m
    Jira:  1h 45m
    [L]ocal  [J]ira  [S]kip > L

Sync complete ✓
  Resolved: 3 conflicts
  Skipped:  0

$ avo jira status
Jira: PROJ @ company.atlassian.net
  Last sync: 10 min ago
  Pending:   1 worklog to push
  Linked:    5 tasks
```

---

## 4. MCP Server Design

### 4.1 Server Configuration

**Package**: `mcp/`
**Entry**: `mcp/bin/server.dart`
**Protocol**: MCP over stdio

**Claude Code config** (`~/.claude/settings.json`):
```json
{
  "mcpServers": {
    "avodah": {
      "command": "dart",
      "args": ["run", "/path/to/avodah/mcp/bin/server.dart"],
      "env": {
        // Optional: Override default XDG location
        // "AVODAH_DATA_DIR": "/custom/path"
      }
    }
  }
}
```

**Default paths** (no env override needed):
- Database: `~/.local/share/avodah/avodah.db`
- Config: `~/.config/avodah/config.toml`
- Node ID: `~/.config/avodah/node-id`

### 4.2 MCP Tools (Minimal Set)

> **Principle**: Fewer tools = less context bloat. Only include what's essential.

#### Core Tools (MVP)

| Tool | Parameters | Returns | Description |
|------|------------|---------|-------------|
| `timer` | `action: start\|stop\|status`, `task?: string`, `taskId?: string` | `TimerResult` | All timer operations |
| `tasks` | `action: list\|add`, `title?: string`, `projectId?: string` | `TasksResult` | List or create tasks |
| `today` | - | `DaySummary` | Today's work summary |
| `jira` | `action: pull\|push\|status` | `JiraResult` | Sync with Jira |

**Four tools for MVP.** Jira sync is explicit, not automatic.

**Jira Workflow (Simple)**:
1. Work normally with `timer` on local tasks
2. `jira(action:"sync")` → Bidirectional sync (pull issues, push worklogs)
3. `jira(action:"status")` → Show pending sync / last sync info

**Conflict Resolution**:
- Per-field/per-worklog granularity
- On sync, prompt user for each conflict: "Keep local" or "Keep Jira"
- Example: Task title changed locally AND in Jira → ask which to keep
- Example: Worklog duration differs → ask which to keep

#### TimerResult Schema (terse):
```typescript
interface TimerResult {
  ok: boolean;
  running?: boolean;
  task?: string;
  taskId?: string;
  elapsed?: string;      // "1h 23m"
  logged?: string;       // Only on stop: "1h 23m → Task name"
  error?: string;
}
```

#### TasksResult Schema (terse):
```typescript
interface TasksResult {
  ok: boolean;
  tasks?: {
    id: string;
    title: string;
    project?: string;
    time: string;        // "2h 15m"
  }[];
  created?: {            // Only on add
    id: string;
    title: string;
  };
  error?: string;
}
```

#### DaySummary Schema (terse):
```typescript
interface DaySummary {
  date: string;           // "2025-02-10"
  total: string;          // "3h 30m"
  tasks: {
    id: string;
    name: string;
    time: string;
  }[];
}
```

#### JiraResult Schema (terse):
```typescript
interface JiraResult {
  ok: boolean;
  action: "sync" | "status";
  pulled?: number;        // Issues pulled from Jira
  pushed?: number;        // Worklogs pushed to Jira
  conflicts?: {
    type: "task" | "worklog";
    id: string;
    field: string;
    local: string;
    jira: string;
  }[];
  lastSync?: string;      // ISO 8601
  pending?: number;       // Unsynced items
  error?: string;
}
```

#### Extended Tools (Phase 2, if needed)

| Tool | Parameters | Returns | Description |
|------|------------|---------|-------------|
| `task` | `action: add\|list\|done`, `title?: string`, `id?: string` | `TaskResult` | Task management |
| `log` | `task: string`, `duration: string` | `LogResult` | Manual time entry |
| `week` | - | `WeekSummary` | Week summary |

> **Note**: Start with core tools. Add extended tools only if usage patterns demand them.

### 4.3 MCP Resources

> **Principle**: Resources are read-only context. Keep them minimal.

| URI | Description |
|-----|-------------|
| `avodah://status` | Timer + today summary (combined, one read) |

### 4.4 Example Claude Code Interactions

**Starting work on new task**:
```
User: "I'm going to work on the MCP implementation"
Claude: [calls timer(action: "start", task: "MCP implementation")]
        Timer started: MCP implementation
```

**Starting work on existing task**:
```
User: "Let me continue on that bug fix"
Claude: [calls tasks(action: "list")]  → sees task id "abc123"
        [calls timer(action: "start", taskId: "abc123")]
        Timer started: Fix login bug
```

**Checking status**:
```
User: "How long have I been working?"
Claude: [calls timer(action: "status")]
        1h 23m on "MCP implementation"
```

**Stopping (by either party)**:
```
User: "I'm done for now" (or runs `avo stop` in terminal)
Claude: [calls timer(action: "stop")]
        Logged 1h 23m → MCP implementation
```

**End of day**:
```
User: "What did I work on today?"
Claude: [calls today()]
        Today: 3h 30m
        - MCP implementation: 2h 15m
        - Code review: 1h 15m
```

### 4.5 Human CLI ↔ MCP Equivalence

| Human CLI | MCP Tool Call | Same Result |
|-----------|---------------|-------------|
| `avo start "task"` | `timer(action:"start", task:"task")` | ✅ |
| `avo stop` | `timer(action:"stop")` | ✅ |
| `avo status` | `timer(action:"status")` | ✅ |
| `avo task list` | `tasks(action:"list")` | ✅ |
| `avo today` | `today()` | ✅ |
| `avo jira sync` | `jira(action:"sync")` | ✅ |
| `avo jira status` | `jira(action:"status")` | ✅ |

Both modify the same SQLite database. No conflicts, no confusion.

**Note on Jira conflicts**: When MCP triggers sync and conflicts are found, it returns conflict info. Claude can then ask user which version to keep and call sync again with resolution choices.

---

## 5. Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Create `TimerDocument` following existing patterns
- [ ] Add `TimerEntries` Drift table
- [ ] Regenerate Drift code (`flutter pub run build_runner build`)
- [ ] Create `mcp/` package structure with pubspec.yaml
- [ ] Implement `AvodahPaths` for XDG path resolution
- [ ] Implement `DatabaseOpener` for pure Dart DB access
- [ ] Test: Database opens and reads/writes correctly

### Phase 2: CLI Implementation
- [ ] CLI entry point (`mcp/bin/avo.dart`)
- [ ] Argument parser setup with `args` package
- [ ] Timer commands: `start`, `stop`, `pause`, `resume`, `status`, `cancel`
- [ ] Task commands: `add`, `list`, `done`, `show`
- [ ] Worklog commands: `log`, `today`, `week`
- [ ] Project commands: `add`, `list`
- [ ] Output formatters (human-readable terminal output)
- [ ] Install script or alias setup for `avo` command

### Phase 3: MCP Server
- [ ] MCP entry point (`mcp/bin/server.dart`)
- [ ] JSON-RPC protocol handler over stdio
- [ ] Core tools: `timer`, `tasks`, `today`, `jira`
- [ ] Resource endpoint: `avodah://status`
- [ ] Test: Human starts timer via CLI, Claude stops via MCP (and vice versa)

### Phase 4: Jira Integration
- [ ] Jira API client (using existing `JiraIntegrationDocument`)
- [ ] Pull: Fetch assigned issues → create/update local tasks
- [ ] Push: Send unsynced worklogs to Jira
- [ ] Conflict detection: Compare timestamps/values
- [ ] Conflict resolution UI: Per-field prompts in CLI
- [ ] `avo jira setup` command for initial configuration
- [ ] Store credentials in `~/.config/avodah/jira-credentials.json`

### Phase 5: Integration & Testing
- [ ] Claude Code MCP configuration
- [ ] Test with real usage (track time while developing)
- [ ] Test Jira sync with real Jira instance
- [ ] Document setup instructions in README
- [ ] Add to project CLAUDE.md

### Phase 6: Polish
- [ ] Error handling and user-friendly messages
- [ ] Config file support (config.toml)
- [ ] Logging (optional, to XDG_STATE_HOME)
- [ ] Shell completion scripts (bash/zsh)

---

## 6. Resolved Decisions

1. **Storage format**: SQLite via Drift
   - **Decision**: Use SQLite (not JSON) - both MCP and Flutter can access same DB
   - **Rationale**: Single source of truth, existing Drift schema, CRDT merge works

2. **Data location**: XDG Base Directory Specification
   - **Decision**: `~/.local/share/avodah/avodah.db`
   - **Override**: Via CLI flag, env var, or config file (see Section 2.5)

3. **Timer conflict resolution**: Last-write-wins
   - **Decision**: If timer started on two devices, most recent `startedAt` wins
   - **Rationale**: Matches CRDT semantics, simple mental model

4. **Jira integration**: Included in MVP
   - **Decision**: Bidirectional sync with manual trigger (`avo jira sync`)
   - **Conflict resolution**: Per-field/per-worklog, user chooses "Keep local" or "Keep Jira"
   - **No auto-sync**: User explicitly triggers sync to avoid surprises

## 7. Open Questions

1. **Multi-device sync**: How will different nodes sync?
   - Current: Both read/write same SQLite file (local only)
   - Future: P2P sync via CRDT merge protocol (Phase 7+)

2. **Database locking**: What if Flutter app and MCP access DB simultaneously?
   - SQLite handles this via WAL mode
   - May need to configure Drift for WAL mode explicitly

---

## Appendix A: File Structure

### Repository Structure

```
avodah/
├── lib/                              # Flutter app (shared code)
│   ├── core/
│   │   ├── crdt/                     # ✅ Pure Dart - shared with MCP
│   │   │   ├── crdt.dart
│   │   │   ├── crdt_document.dart
│   │   │   ├── hlc.dart
│   │   │   ├── lww_register.dart
│   │   │   ├── lww_set.dart
│   │   │   └── g_counter.dart
│   │   └── storage/                  # ✅ Drift schema - shared with MCP
│   │       ├── database.dart
│   │       ├── database.g.dart
│   │       └── tables/
│   │           ├── tasks.dart
│   │           ├── projects.dart
│   │           ├── worklogs.dart
│   │           ├── tags.dart
│   │           └── timer.dart        # 🆕 Timer table
│   └── features/
│       ├── tasks/models/             # ✅ Document models - shared
│       ├── projects/models/
│       ├── worklog/models/
│       ├── tags/models/
│       ├── timer/models/             # 🆕 TimerDocument
│       └── integrations/models/
├── mcp/                              # 🆕 MCP server package
│   ├── pubspec.yaml
│   ├── bin/
│   │   ├── server.dart               # MCP entry point
│   │   └── avo.dart                  # CLI entry point (`avo` command)
│   ├── lib/
│   │   ├── config/
│   │   │   └── paths.dart            # XDG path resolution
│   │   ├── storage/
│   │   │   └── database_opener.dart  # Pure Dart DB opener
│   │   ├── tools/
│   │   │   ├── timer_tools.dart
│   │   │   ├── task_tools.dart
│   │   │   ├── worklog_tools.dart
│   │   │   └── project_tools.dart
│   │   └── cli/
│   │       ├── commands.dart
│   │       └── formatters.dart
│   └── test/
├── docs/
│   └── design/
│       └── mcp-worklog-tracker.md    # This document
└── pubspec.yaml
```

### User Data Structure (XDG)

```
~/.local/share/avodah/                # XDG_DATA_HOME/avodah
└── avodah.db                         # SQLite database

~/.config/avodah/                     # XDG_CONFIG_HOME/avodah
├── config.toml                       # User configuration
├── node-id                           # Auto-generated node ID
└── jira-credentials.json             # Future: Jira auth

~/.local/state/avodah/                # XDG_STATE_HOME/avodah
└── logs/                             # Debug logs (optional)

~/.cache/avodah/                      # XDG_CACHE_HOME/avodah
└── (empty for now)                   # Future: cached data
```

---

## Appendix B: Dependencies

**mcp/pubspec.yaml**:
```yaml
name: avodah_mcp
description: MCP server for Avodah worklog tracking

environment:
  sdk: ^3.0.0

dependencies:
  # Shared code from parent (CRDT, documents, Drift schema)
  avodah:
    path: ..

  # Database (pure Dart SQLite - no Flutter)
  drift: ^2.22.1
  sqlite3: ^2.7.3

  # CLI argument parsing
  args: ^2.4.0

  # Configuration
  toml: ^0.15.0

  # MCP protocol (JSON-RPC over stdio)
  json_rpc_2: ^3.0.2
  stream_channel: ^2.1.2

  # Utilities
  uuid: ^4.0.0
  path: ^1.8.0

dev_dependencies:
  test: ^1.24.0
  drift_dev: ^2.22.1
  build_runner: ^2.4.0
```

> **Note**: The `avodah` path dependency gives MCP access to all shared code:
> - `lib/core/crdt/` - CRDT primitives
> - `lib/core/storage/` - Drift database schema
> - `lib/features/*/models/` - Document classes
