# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Version Roadmap

| Version | Scope |
|---------|-------|
| **0.x.y** | Pre-stable — key features being built and tested |
| **0.2.0** | Next capability milestone (e.g., full Jira coverage, GitHub integration) |
| **1.0.0** | Fully functional CLI + MCP integration for AI usage |
| **2.0.0** | Flutter UI with Linux & Android |

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
