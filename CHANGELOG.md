# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Version Roadmap

| Version   | Theme                                               | Issues                  |
|-----------|-----------------------------------------------------|-------------------------|
| **0.3.2** | Safety — worklog guards, undone/undelete             | #72, #73                |
| **0.3.3** | Reliability — Jira re-sync fix, markdown notes       | #70, #74                |
| **0.3.4** | CLI polish — picker fix, fish completions, db tools  | #60, #58, #75           |
| **0.3.5** | Jira — selective sync                                | #71                     |
| **0.4.0** | Wire dormant schema — subtasks, tags, estimates      | #76, #77, #78, #79      |
| **0.5.0** | Filtering & search                                   | #80, #81, #82           |
| **0.6.0** | Reporting & export                                   | #83, #84                |
| **0.7.0** | Data management — backup, import/export, soft-delete | #85, #86, #87           |
| **0.8.0** | Recurring tasks                                      | #88                     |
| **0.9.0** | Schema freeze & hardening                            | #89, #90, #91           |
| **1.0.0** | Stable CLI + MCP — quality gate                      | No critical bugs        |
| **2.0.0** | Flutter UI + multi-user + GitHub sync                | #54, #59, Flutter app   |

## [0.4.0] - 2026-02-27

_No conventional commits since 0.3.1._

## [0.3.1] - 2026-02-25

### Added
- MCP server full CLI parity — 10 tools: timer, tasks, worklog, project, plan, today, daily, week, status, jira (#69)
- Cancel/uncancel status for plan tasks (#64)
- Auto-compiling `avodah-mcp` devshell wrapper for MCP server binary

### Fixed
- Devshell avo wrapper watches avodah_core for recompilation (#68)
- Migrate devshell builds from `dart compile exe` to `dart build cli`

### Changed
- Remove beta workflow — use simple `X.Y.Z+N` versioning on develop
- Cache interactive picker filter results (#65)
- Add auto version bump workflow for releases (#66)

## [0.3.0] - 2026-02-19

### Added
- Add tasks to daily plan with category-grouped display

### Fixed
- Auto-sync worklog to Jira on manual log

### Changed
- Merge pull request #57 from sinh-x/develop
- Merge branch 'feat/day-plan-tasks' into develop
- Merge pull request #55 from sinh-x/bugfix/worklog-auto-sync-jira

## [0.2.0] - 2026-02-18

### Added
- Avo daily command and avo week enhancements (#53)

## [0.1.1] - 2026-02-18

### Added
- Help text audit and consolidate log/worklog commands (#37) (#49)
- Worklog add/edit with start time, duration, and description (#48)
- Centralized version management with bump script and CHANGELOG (#46)
- Jira sync progress, auto-push worklog, stop flags (#44)
- Due dates, task categories, and daily time planning (#43)
- Package avo CLI with buildDartApplication + fish completions
- Interactive task picker for `avo start` with no args
- Sync improvements — metadata, worklogs, filters, status (#36)
- Jira UX polish — setup wizard, multi-profile, done-status sync (#34)
- CLI polish — time display, delete, task show, log, recent (#33)
- 2-way Jira sync with conflict resolution and profile credentials (#16)
- Implement JiraService and wire Jira integration (#9) (#14)
- Wire services into MCP server protocol (#8)
- Implement ProjectService and wire project CLI commands (#7)
- Implement WorklogService and wire today/week CLI commands (#6)
- Implement TaskService and wire task CLI commands (#5) (#10)
- Implement timer CLI and MCP server scaffold (#4)

### Fixed
- Support task ID prefix matching in start command (#24)
- Resolve timer creating orphaned worklogs (#17) (#18)

### Changed
- Add .claude/todos.md to .gitignore
- Merge pull request #41 from sinh-x/feat/interactive-task-picker
- Rename av-* commands to avo-* and fix Flutter version display (#23)
- Native avo binary + CLI default commands (#19, #20, #21) (#22)
- Merge pull request #13 from sinh-x/feat/mcp-server-impl
- Merge pull request #12 from sinh-x/feat/cli-project-service
- Merge pull request #11 from sinh-x/feat/cli-worklog-queries
- Extract avodah_core shared package (#2)
- Add MCP worklog tracker design spec (#1)

## [0.1.0] - 2026-02-13

First tagged release — CLI-first time tracking with Jira integration.

### Added

**Timer & Time Tracking**
- Timer with start, stop, pause, resume, and cancel
- Automatic worklog creation on timer stop
- Manual time entry via `avo log <task> <duration>` (e.g., `1h30m`)
- Today's work summary by task (`avo today`)
- Weekly work summary with bar chart (`avo week`)
- Recent worklogs view (`avo recent`)
- Worklog deletion (`avo worklog delete`)

**Task Management**
- Task CRUD: add, list, show, done, delete
- Task ID prefix matching (type first few chars instead of full UUID)
- Interactive task picker for `avo start` with no arguments
- Due dates with overdue tracking (`avo task due`)
- Task categories: Learning, Working, Side-project, Family & Friends, Personal (`avo task cat`)
- Filter tasks by source, project, Jira profile, or local-only
- Task descriptions and time estimates

**Project Management**
- Project CRUD: add, list, show, delete
- Project icons
- Task count per project

**Daily Planning**
- Plan time by category (`avo plan add`)
- Plan-vs-actual comparison with progress indicators (`avo plan list`)
- Configurable categories via `~/.config/avodah/config.json`

**Jira Integration**
- 2-way sync: pull issues from Jira, push worklogs to Jira
- Multi-profile support (e.g., work, personal Jira instances)
- Interactive setup wizard (`avo jira setup`)
- Credentials template generator (`avo jira init`)
- Conflict resolution for title/duration mismatches
- Sync preview with dry-run mode (`--dry-run`)
- Auto-push worklogs on timer stop
- Sync progress indicators
- Per-profile default category for auto-categorization
- Done-status sync between Jira and local tasks

**Dashboard**
- `avo status` dashboard: active timer, today's summary, open tasks, daily plan
- `avo` with no arguments runs status + help hint
- Smart defaults: `avo jira` → status, `avo plan` → list

**MCP Server**
- JSON-RPC 2.0 over stdio (MCP protocol 2024-11-05)
- Tools: timer, tasks, today, jira
- Resources: `avodah://status` (current state as JSON)

**Architecture**
- CRDT-based documents for future P2P sync (Task, Worklog, Timer, Project, DailyPlan, JiraIntegration)
- Hybrid logical clocks with persistent node IDs
- Drift (SQLite) database with 8 tables (schema v7)
- Shared `avodah_core` package between Flutter app and CLI
- Service layer with dependency injection (db + clock)

**Infrastructure**
- Nix flake: devShell with Flutter + Dart + Android SDK
- Nix package: `buildDartApplication` for native `avo` binary
- Fish shell completions for all commands and subcommands
- Auto-compiling `avo` wrapper in devShell (recompiles on source changes)

**Flutter App (scaffold)**
- App shell with bottom navigation
- Screens: Tasks, Timer, Projects, Settings
- Material Design theming

[0.1.0]: https://github.com/sinh-x/avodah/releases/tag/v0.1.0
