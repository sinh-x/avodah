# Avodah (עבודה)

> Work as worship. A local-first, P2P productivity app.

## Overview

Avodah is a Flutter-based task management and time tracking application inspired by [Super Productivity](https://github.com/johannesjo/super-productivity). It's designed to be:

- **Local-first**: All data lives on your devices, works fully offline
- **P2P Sync**: Devices sync directly using CRDTs, no central server required
- **Cross-platform**: Android and Linux desktop (iOS, Windows, macOS planned)
- **Privacy-focused**: No analytics, no telemetry, your data stays yours

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Application                       │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer (Widgets) → State Management (Riverpod)               │
│           ↓                                                      │
│  CRDT Document Layer (automatic conflict resolution)            │
│           ↓                                                      │
│  Storage (Isar) ←→ Sync Layer (P2P) ←→ Crypto (E2E)            │
└─────────────────────────────────────────────────────────────────┘
                               ↓
              Network Layer (mDNS discovery, WebSocket, Relay)
```

## Features

### Core (Phase 1)
- [ ] Task management with projects and tags
- [ ] Time tracking with start/stop timer
- [ ] Worklog history
- [ ] Offline-first with local persistence
- [ ] CRDT-based data model

### Sync (Phase 1)
- [ ] P2P device discovery (mDNS)
- [ ] Direct sync over local network
- [ ] End-to-end encryption
- [ ] Device pairing flow

### Advanced (Phase 2+)
- [ ] Pomodoro timer
- [ ] Recurring tasks
- [ ] Jira/GitHub integration
- [ ] Calendar integration
- [ ] iOS/Windows/macOS support

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Local Database**: Isar
- **CRDT**: Dart-native CRDT or Yjs via FFI
- **Networking**: WebSocket, mDNS/DNS-SD
- **Encryption**: libsodium / cryptography

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Android SDK (for Android)
- Linux development tools (for Linux desktop)

### Installation

```bash
# Clone the repository
git clone https://github.com/sinh-x/avodah.git
cd avodah

# Install dependencies
flutter pub get

# Run on Linux
flutter run -d linux

# Run on Android
flutter run -d android
```

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── crdt/          # CRDT implementations
│   ├── sync/          # P2P sync service
│   ├── storage/       # Isar database
│   └── platform/      # Platform-specific code
├── features/
│   ├── tasks/         # Task management
│   ├── projects/      # Project organization
│   ├── tags/          # Tag system
│   ├── timer/         # Time tracking
│   ├── worklog/       # Work history
│   └── settings/      # App settings
└── shared/
    ├── widgets/       # Reusable UI components
    ├── theme/         # Theming
    └── utils/         # Utilities
```

## Development

See `.kiro/specs/sp-flutter-migration/` for detailed:
- `requirements.md` - User stories and acceptance criteria
- `design.md` - Technical architecture and component design
- `tasks.md` - Implementation tasks

## Inspiration

- [Super Productivity](https://github.com/johannesjo/super-productivity) - Original Angular/Electron app
- [Anytype](https://anytype.io) - Local-first, P2P architecture

## Name

**Avodah** (עבודה) is a Hebrew word meaning "work," "service," and "worship." In Jewish tradition, it represents the idea that work itself can be a form of divine service—transforming everyday tasks into something meaningful.

## Versioning

Avodah follows [Semantic Versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for release notes.

| Version | Milestone |
|---------|-----------|
| **0.x.y** | Pre-stable — core features being built and tested |
| **0.1.0** | CLI time tracking, task management, Jira 2-way sync, daily planning, MCP server |
| **0.2.0** | Next capability area (e.g., full Jira coverage, GitHub integration) |
| **1.0.0** | Fully functional CLI + MCP integration for AI-assisted usage |
| **2.0.0** | Flutter UI with Linux & Android |

**Pre-1.0 convention:** minor bumps (0.x.0) for new capability areas or breaking changes; patch bumps (0.x.y) for bug fixes and polish within a capability.

## License

MIT

---

*Work as worship.*
