# Avodah Data Model Specification

This document describes the data model for Avodah, aligned with Super Productivity's data structures for compatibility and future migration support.

## Overview

All entities use:
- **String IDs**: UUID-based identifiers
- **Unix Milliseconds**: All timestamps stored as Unix milliseconds (not seconds)
- **JSON Strings**: Complex nested data stored as JSON strings in the database
- **CRDT Metadata**: Each entity includes `crdtClock` and `crdtState` for conflict-free sync

### Scope

**Phase 2 (Current) - Linux/NixOS MVP:**
- Task ✅, Subtask, Project, Tag, WorklogEntry
- JiraIntegration (external credentials file, no in-app storage)

**Deferred:**
- Platform secure storage (Android Keystore, iOS Keychain) - later phase
- GitHubIntegration - later phase
- Other integrations (GitLab, Trello, etc.) - later phase
- TaskRepeatCfg (recurring tasks) - later phase

---

## Core Entities

### 1. Task

The central entity for task management. Tasks can have subtasks (parent-child relationships), belong to projects, and have multiple tags.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (UUID) |
| `projectId` | String? | Parent project ID |
| `title` | String | Task title/name |
| `description` | String? | Task description (supports markdown) |
| `isDone` | Boolean | Completion status |
| `created` | Integer | Creation timestamp (Unix ms) |

#### Time Tracking

| Field | Type | Description |
|-------|------|-------------|
| `timeEstimate` | Integer | Estimated time in milliseconds (user input) |

> **Note**: `timeSpent` and `timeSpentOnDay` are derived from WorklogEntry records at query time. No duplication needed.

#### Due Dates

| Field | Type | Description |
|-------|------|-------------|
| `dueWithTime` | Integer? | Due date with specific time (Unix ms) |
| `dueDay` | String? | Due date without time: `"2024-01-15"` |

#### Relations

| Field | Type | Description |
|-------|------|-------------|
| `tagIds` | JSON | Array of tag IDs: `["tag1", "tag2"]` |

> **Note**: Subtasks are separate simple entities (see Subtask below), not nested Tasks. Query subtasks by `taskId`.

#### Attachments & Reminders

| Field | Type | Description |
|-------|------|-------------|
| `attachments` | JSON | Array of attachment objects (see Attachment schema below) |
| `reminderId` | String? | Associated reminder ID |
| `remindAt` | Integer? | Reminder timestamp (Unix ms) |

#### Completion

| Field | Type | Description |
|-------|------|-------------|
| `doneOn` | Integer? | Completion timestamp (Unix ms) |

> **Note**: `modified` timestamp is tracked internally by CRDT via `_modifiedAt`. No separate field needed.

#### Repeating Tasks

| Field | Type | Description |
|-------|------|-------------|
| `repeatCfgId` | String? | Associated repeat configuration ID |

#### Issue Integration

For linking tasks to external issue trackers (Jira, GitHub, etc.). One task links to at most one external issue.

| Field | Type | Description |
|-------|------|-------------|
| `issueId` | String? | External issue ID (e.g., "PROJ-123") |
| `issueProviderId` | String? | Issue provider configuration ID |
| `issueType` | String? | Provider type: `JIRA`, `GITHUB`, `GITLAB`, etc. |
| `issueWasUpdated` | Boolean? | Whether issue was updated externally |
| `issueLastUpdated` | Integer? | Last sync timestamp (Unix ms) |
| `issueAttachmentNr` | Integer? | Number of attachments on external issue |
| `issuePoints` | Integer? | Story points (Jira/agile) |

> **Note**: `issueTimeTracked` removed - derive from WorklogEntry records filtered by provider.

#### CRDT Metadata

| Field | Type | Description |
|-------|------|-------------|
| `crdtClock` | String | Hybrid Logical Clock value |
| `crdtState` | JSON | Serialized CRDT state for conflict resolution |

---

### 2. Subtask

Simple checklist items for mental task breakdown. **No time tracking** - all time is tracked at the parent Task level.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (UUID) |
| `taskId` | String | Parent task ID |
| `title` | String | Subtask title |
| `isDone` | Boolean | Completion status |
| `order` | Integer | Position within task (for ordering) |
| `notes` | String? | Optional notes |
| `created` | Integer | Creation timestamp (Unix ms) |
| `modified` | Integer? | Last modification timestamp (Unix ms) |

**Design Decision**: Unlike Super Productivity where subtasks are full Task entities with `parentId`, Avodah treats subtasks as simple checklist items. This simplifies:
- Time tracking (always at Task level)
- Issue integration (always at Task level)
- Data relationships (flat, not nested)

**Jira Mapping**: Jira subtasks sync to this model:
| Jira Field | Subtask Field |
|------------|---------------|
| `summary` | `title` |
| `description` | `notes` |
| `status` (Done/Not Done) | `isDone` |
| Display order | `order` |

Jira worklog on subtasks is **ignored** - all time tracking syncs at parent issue level.

**GitHub Mapping**:
- GitHub Issue → Task (1:1)
- GitHub task lists (markdown checkboxes) → **NOT synced**
- GitHub sub-issues (beta feature) → **NOT supported for now**
- Create subtasks locally in Avodah if needed

---

### 3. Project

Projects group tasks and contain configuration for integrations and theming.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (UUID) |
| `title` | String | Project name |
| `icon` | String? | Icon identifier or emoji |
| `isArchived` | Boolean | Whether project is archived |
| `isHiddenFromMenu` | Boolean | Hide from navigation menu |
| `isEnableBacklog` | Boolean | Enable backlog feature |

#### Task Lists

| Field | Type | Description |
|-------|------|-------------|
| `taskIds` | JSON | Active task IDs: `["id1", "id2"]` |
| `backlogTaskIds` | JSON | Backlog task IDs: `["id3", "id4"]` |

#### Configuration

| Field | Type | Description |
|-------|------|-------------|
| `theme` | JSON | Theme configuration (see Theme schema) |
| `advancedCfg` | JSON | Advanced settings (worklog export, etc.) |

> **Note**: Issue integration configs moved to separate `JiraIntegration` table (Option B+). See [Integration Tables](#integration-tables) section.

#### Timestamps

| Field | Type | Description |
|-------|------|-------------|
| `created` | Integer | Creation timestamp (Unix ms) |
| `modified` | Integer? | Last modification timestamp (Unix ms) |

---

### 4. Tag

Tags provide flexible categorization across projects. They share the WorkContextCommon interface with Projects.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (UUID) |
| `title` | String | Tag name |
| `icon` | String? | Icon identifier or emoji |
| `taskIds` | JSON | Task IDs with this tag: `["id1", "id2"]` |
| `theme` | JSON | Theme configuration |
| `advancedCfg` | JSON | Advanced settings |
| `created` | Integer | Creation timestamp (Unix ms) |
| `modified` | Integer? | Last modification timestamp (Unix ms) |

---

### 5. Worklog Entry

Individual time tracking sessions. Each entry represents a continuous work period on a task.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (UUID) |
| `taskId` | String | Associated task ID |
| `start` | Integer | Start timestamp (Unix ms) |
| `end` | Integer | End timestamp (Unix ms) |
| `duration` | Integer | Duration in milliseconds |
| `date` | String | Date for grouping: `"2024-01-15"` |
| `comment` | String? | Optional work notes |
| `jiraWorklogId` | String? | Synced Jira worklog ID |
| `created` | Integer | Creation timestamp (Unix ms) |
| `updated` | Integer | Last update timestamp (Unix ms) |

---

## Integration Tables

Integration configurations are stored in **separate tables per provider** (Option B+) rather than embedded JSON in Project. This enables:
- Parallel development (each integration is isolated)
- Type-safe fields (not buried in JSON)
- External credential management (not stored in app)

### MVP Architecture (Linux/NixOS)

For initial development, credentials are **externalized** - Avodah stores a path to a credentials file, not the credentials themselves.

```
┌─────────────────────────────────────────────────────────────────────────┐
│  SQLite (JiraIntegration table)                                          │
├─────────────────────────────────────────────────────────────────────────┤
│  id, projectId, baseUrl, jiraProjectKey, syncEnabled, ...               │
│  credentialsFilePath: "~/.config/avodah/jira-creds.json"                │
│                        ↑                                                 │
│                        └── Path to external file (user manages)         │
└─────────────────────────────────────────────────────────────────────────┘
                    │
                    │ Read at runtime (not stored)
                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  External Credentials File (user-managed)                                │
├─────────────────────────────────────────────────────────────────────────┤
│  Options:                                                                │
│  - Plain file with chmod 600                                            │
│  - sops-nix encrypted file                                              │
│  - agenix secret                                                         │
│  - Environment variable path                                             │
├─────────────────────────────────────────────────────────────────────────┤
│  File: ~/.config/avodah/jira-creds.json                                 │
│  {                                                                       │
│    "email": "user@company.com",                                         │
│    "apiToken": "ATATT3xFfGF0..."                                        │
│  }                                                                       │
└─────────────────────────────────────────────────────────────────────────┘
```

**Benefits:**
- No credential storage in app = no security responsibility
- Works with NixOS secret management (sops-nix, agenix)
- User controls credential lifecycle
- Simple to implement

**Future:** Add platform secure storage when targeting Android/iOS.

### 6. JiraIntegration

Configuration for Jira issue sync. Credentials read from external file at runtime.

#### Core Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (UUID) |
| `projectId` | String? | Links to Avodah Project (null = global) |

#### Connection Settings

| Field | Type | Description |
|-------|------|-------------|
| `baseUrl` | String | Jira instance URL: `https://company.atlassian.net` |
| `jiraProjectKey` | String | Jira project key: `PROJ` |
| `boardId` | String? | Jira board ID for sprint tracking |

#### Credentials (External)

| Field | Type | Description |
|-------|------|-------------|
| `credentialsFilePath` | String | Path to JSON credentials file |

Expected file format:
```json
{
  "email": "user@company.com",
  "apiToken": "ATATT3xFfGF0..."
}
```

> **Note**: Avodah reads this file at runtime, never stores credentials in SQLite.

#### Sync Settings

| Field | Type | Description |
|-------|------|-------------|
| `jqlFilter` | String? | Custom JQL for issue filtering |
| `syncEnabled` | Boolean | Enable/disable sync |
| `syncSubtasks` | Boolean | Sync Jira subtasks |
| `syncWorklogs` | Boolean | Push worklogs to Jira |
| `syncIntervalMinutes` | Integer | Auto-sync interval (default: 15) |

#### Sync Status (Operational)

| Field | Type | Description |
|-------|------|-------------|
| `lastSyncAt` | Integer? | Last successful sync (Unix ms) |
| `lastSyncError` | String? | Last error message |

#### Timestamps & CRDT

| Field | Type | Description |
|-------|------|-------------|
| `created` | Integer | Creation timestamp (Unix ms) |
| `modified` | Integer? | Last modification (Unix ms) |
| `crdtClock` | String | HLC value |
| `crdtState` | JSON | CRDT state |

#### Jira Sync Flow

```
Jira                                    Avodah
─────                                   ──────
Project (PROJ)  ◄─────────────────────► Project + JiraIntegration
   │                                       │
   ▼                                       ▼
Issue (PROJ-123) ◄────────────────────► Task (issueId="PROJ-123")
   │                                       │
   ├── Subtasks ◄─────────────────────► Subtask (title, isDone, order)
   │                                       │
   └── Worklogs ◄─────────────────────► WorklogEntry (jiraWorklogId)
```

---

### 7. Task Repeat Configuration (DEFERRED)

Configuration for recurring/repeating tasks.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (UUID) |
| `projectId` | String? | Default project for created tasks |
| `title` | String? | Template title |
| `tagIds` | JSON | Default tags: `["tag1"]` |
| `order` | Integer | Sort order |

#### Defaults for Created Tasks

| Field | Type | Description |
|-------|------|-------------|
| `defaultEstimate` | Integer? | Default time estimate (ms) |
| `startTime` | String? | Default start time: `"09:00"` |
| `remindAt` | String? | Reminder option ID |

#### Repeat Settings

| Field | Type | Description |
|-------|------|-------------|
| `isPaused` | Boolean | Pause recurring creation |
| `quickSetting` | String | Quick setting: `DAILY`, `WEEKLY_CURRENT_WEEKDAY`, `MONTHLY_CURRENT_DATE`, `MONDAY_TO_FRIDAY`, `YEARLY_CURRENT_DATE`, `CUSTOM` |
| `repeatCycle` | String | Cycle type: `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY` |
| `startDate` | String? | Start date: `"2024-01-15"` |
| `repeatEvery` | Integer | Repeat every N cycles |

#### Weekday Flags (for weekly repeats)

| Field | Type | Description |
|-------|------|-------------|
| `monday` | Boolean | Repeat on Monday |
| `tuesday` | Boolean | Repeat on Tuesday |
| `wednesday` | Boolean | Repeat on Wednesday |
| `thursday` | Boolean | Repeat on Thursday |
| `friday` | Boolean | Repeat on Friday |
| `saturday` | Boolean | Repeat on Saturday |
| `sunday` | Boolean | Repeat on Sunday |

#### Subtask Templates

| Field | Type | Description |
|-------|------|-------------|
| `subTaskTemplates` | JSON | Array of subtask templates |
| `notes` | String? | Default notes for created tasks |

#### Tracking

| Field | Type | Description |
|-------|------|-------------|
| `lastTaskCreation` | Integer? | Last task creation timestamp (Unix ms) |
| `lastTaskCreationDay` | String? | Last creation date: `"2024-01-15"` |
| `deletedInstanceDates` | JSON | Skipped dates: `["2024-01-20"]` |

---

## Nested Schemas

### Theme Configuration

Stored as JSON in `theme` field:

```json
{
  "primary": "#6750A4",
  "accent": "#625B71",
  "warn": "#B3261E",
  "huePrimary": 500,
  "hueAccent": 500,
  "hueWarn": 500,
  "isAutoContrast": true,
  "isDisableBackgroundTint": false,
  "backgroundImageDark": null,
  "backgroundImageLight": null
}
```

### Advanced Configuration

Stored as JSON in `advancedCfg` field:

```json
{
  "worklogExportSettings": {
    "roundWorkTimeTo": "QUARTER",
    "roundStartTimeTo": null,
    "roundEndTimeTo": null,
    "separateTasksBy": "\n",
    "cols": ["DATE", "START", "END", "TITLES", "TIME_CLOCK"],
    "groupBy": "DATE"
  }
}
```

### Task Attachment

Stored in `attachments` JSON array:

```json
[
  {
    "id": "att-uuid",
    "type": "IMG",
    "title": "screenshot.png",
    "originalImgPath": "/path/to/image.png",
    "icon": null
  }
]
```

Attachment types: `IMG`, `LINK`, `FILE`

### Subtask Template

Stored in `subTaskTemplates` JSON array:

```json
[
  {
    "title": "Code review",
    "timeEstimate": 1800000,
    "notes": "Review PR and provide feedback"
  }
]
```

---

## Issue Provider Types

Supported issue tracker integrations:

| Key | Description |
|-----|-------------|
| `JIRA` | Atlassian Jira |
| `GITHUB` | GitHub Issues |
| `GITLAB` | GitLab Issues |
| `CALDAV` | CalDAV Tasks |
| `ICAL` | iCal Calendar |
| `OPEN_PROJECT` | OpenProject |
| `GITEA` | Gitea Issues |
| `TRELLO` | Trello Cards |
| `REDMINE` | Redmine Issues |
| `LINEAR` | Linear Issues |
| `CLICKUP` | ClickUp Tasks |

---

## Task Status Values

| Value | Description |
|-------|-------------|
| `isDone: false` | Open/In Progress |
| `isDone: true` | Completed |

Note: Super Productivity uses a simple boolean for completion status rather than multiple states.

---

## Reminder Option IDs

| ID | Description |
|----|-------------|
| `DoNotRemind` | No reminder |
| `AtStart` | At due time |
| `m5` | 5 minutes before |
| `m10` | 10 minutes before |
| `m15` | 15 minutes before |
| `m30` | 30 minutes before |
| `h1` | 1 hour before |

---

## Entity Relationships

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PHASE 2 ENTITIES                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────┐         1:N          ┌───────────────┐                   │
│  │    Project    │◄─────────────────────│     Task      │                   │
│  └───────────────┘                      └───────────────┘                   │
│         │                                      │                            │
│         │ 1:N                                  │ 1:N                        │
│         ▼                                      ▼                            │
│  ┌───────────────┐                      ┌───────────────┐                   │
│  │JiraIntegration│                      │   Subtask     │                   │
│  └───────────────┘                      └───────────────┘                   │
│         │                                                                    │
│         │ reads credentials                                                  │
│         ▼                                                                    │
│  ┌───────────────┐                      ┌───────────────┐                   │
│  │ External File │                      │ WorklogEntry  │◄── Task (1:N)     │
│  │ (user-managed)│                      └───────────────┘                   │
│  └───────────────┘                                                          │
│                                                                              │
│               ┌───────────────┐                                             │
│               │      Tag      │◄── Task.tagIds (M:N via JSON)               │
│               └───────────────┘                                             │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│  DEFERRED: TaskRepeatCfg, GitHubIntegration                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Entity Summary

| # | Entity | Table | Status |
|---|--------|-------|--------|
| 1 | Task | `Tasks` | ✅ Finalized |
| 2 | Subtask | `Subtasks` | ✅ Approved |
| 3 | Project | `Projects` | ✅ Approved (removed issueIntegrationCfgs) |
| 4 | Tag | `Tags` | ✅ Approved |
| 5 | WorklogEntry | `WorklogEntries` | ✅ Approved |
| 6 | JiraIntegration | `JiraIntegrations` | ✅ Approved (external credentials) |
| 7 | TaskRepeatCfg | `TaskRepeatCfgs` | ⏸️ Deferred |

**Key Design Decisions:**
- Subtasks are simple checklist items, not full Task entities
- All time tracking happens at Task level only
- Subtasks have no tags, no issue integration, no time tracking
- JiraIntegration uses external credentials file (not stored in app)

**Jira Subtask Sync:**
- Jira subtasks map to our simplified Subtask model
- Only sync: title, description (as notes), order, done status
- Do NOT sync worklog from Jira subtasks
- Worklog always syncs at parent Jira issue → Task level

---

## Time Tracking Flow

1. **Start Timer**: Create active session in memory
2. **Stop Timer**: Create `WorklogEntry` with start, end, duration, date
3. **Manual Entry**: Create `WorklogEntry` directly
4. **Display**: Query WorklogEntry, aggregate by taskId for totals

> **Design Principle**: WorklogEntry is the single source of truth for time tracking. Task only stores `timeEstimate` (user input). All other time values are derived at query time.

---

## CRDT Synchronization

Each entity includes CRDT metadata for conflict-free replication:

- **`crdtClock`**: Hybrid Logical Clock (HLC) timestamp for ordering operations
- **`crdtState`**: Serialized CRDT state containing:
  - Last-Writer-Wins (LWW) registers for scalar fields
  - LWW-Sets for array fields (tagIds, subTaskIds)
  - Grow-only counters where applicable

### Merge Strategy

When syncing between devices:
1. Compare `crdtClock` values
2. For each field, apply LWW semantics (later timestamp wins)
3. For sets, merge with union + tombstone tracking
4. Persist merged state

---

## Migration from Super Productivity

Data can be imported from Super Productivity JSON exports:

1. Parse SP JSON export file
2. Map fields to Avodah schema (1:1 mapping for most fields)
3. Generate CRDT initial state for each entity
4. Insert into Drift database

Key differences:
- SP uses IndexedDB (browser) / LevelDB (Electron)
- Avodah uses SQLite via Drift
- Timestamps are compatible (both use Unix milliseconds)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.3.0 | 2026-02-09 | Option B+ architecture: Separate JiraIntegration table with external credentials file. Removed Note entity, issueIntegrationCfgs from Project, GitHub (deferred). Linux/NixOS MVP scope. |
| 0.2.0 | 2026-02-09 | Removed derived fields (timeSpent, timeSpentOnDay, issueTimeTracked, modified). Single source of truth: WorklogEntry for time, CRDT for modified. |
| 0.1.0 | 2024-02-08 | Initial schema aligned with Super Productivity |

---

**Related Documents**:
- [Design Document](./design.md)
- [Requirements](./requirements.md)
- [Implementation Tasks](./tasks.md)
