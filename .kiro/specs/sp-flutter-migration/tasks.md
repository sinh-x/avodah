# Super Productivity Flutter Migration - Implementation Tasks

## Task Overview

This document breaks down the Flutter migration into actionable tasks. The project creates a new Flutter application with local-first, P2P sync architecture inspired by Anytype.

**Current Scope**: Linux/NixOS MVP with Jira integration

**Total Estimated Tasks**: 35+ tasks organized into 6 phases

**Requirements Reference**: `requirements.md`

**Design Reference**: `design.md`

**Data Model Reference**: `data-model.md`

**Repository**: `avodah`

## Implementation Tasks

### Phase 1: Project Foundation ✅

- [x] **1.1** Create new Flutter repository ✅
  - **Description**: Initialize new Flutter project with proper structure, linting, and CI setup
  - **Deliverables**:
    - `super-productivity-flutter` GitHub repository
    - Flutter project with Android + Linux targets enabled
    - `.github/workflows/` CI configuration
    - `analysis_options.yaml` with strict linting
    - Basic README with project overview
  - **Requirements**: Technical Architecture
  - **Dependencies**: None

- [x] **1.2** Setup core dependencies ✅
  - **Description**: Add and configure essential packages for state management, storage, and code generation
  - **Deliverables**:
    - `pubspec.yaml` with core dependencies:
      - `riverpod` / `flutter_riverpod`
      - `drift` / `sqlite3_flutter_libs`
      - `freezed` / `freezed_annotation`
      - `json_serializable`
      - `go_router`
    - `build.yaml` for code generation
    - Working `build_runner` setup
  - **Requirements**: Technical Architecture
  - **Dependencies**: 1.1
  - **Status**: Complete

- [x] **1.3** Implement base app shell ✅
  - **Description**: Create app entry point, theme setup, and navigation structure
  - **Deliverables**:
    - `lib/main.dart` - App entry point
    - `lib/app.dart` - MaterialApp with Riverpod
    - `lib/shared/theme/` - Material 3 theme configuration
    - `lib/shared/router/` - GoRouter setup with shell routes
    - Basic screens: Home, Tasks, Settings (empty shells)
  - **Requirements**: User Experience Requirements
  - **Dependencies**: 1.2
  - **Status**: Complete

- [x] **1.4** Setup Drift database ✅
  - **Description**: Configure Drift (SQLite) for local persistence with initial schema
  - **Deliverables**:
    - `lib/core/storage/database.dart` - Database initialization
    - `lib/core/storage/tables/` - Entity table definitions
    - Database migration strategy (schema versioning)
    - Unit tests for database operations
  - **Requirements**: Offline-First Requirements
  - **Dependencies**: 1.2
  - **Status**: Complete (schema v4)

- [ ] **1.5** Define Jira integration data model
  - **Description**: Create CRDT-backed data model for Jira integration. Uses external credentials file (not stored in app).
  - **Deliverables**:
    - `lib/features/integrations/models/jira_integration_document.dart` - Jira config CRDT document
    - `lib/core/storage/tables/jira_integrations.dart` - Drift table (already exists, update if needed)
    - Unit tests for CRDT merge operations
  - **Requirements**: Core Feature Requirements (Integration Data Models)
  - **Dependencies**: 1.2, 1.4
  - **Note**: Credentials read from external file at runtime. GitHub integration deferred.

### Phase 2: CRDT Foundation

- [x] **2.1** Implement CRDT primitives ✅
  - **Description**: Build or integrate CRDT types for conflict-free data
  - **Deliverables**:
    - `lib/core/crdt/hlc.dart` - Hybrid Logical Clock
    - `lib/core/crdt/lww_register.dart` - Last-Writer-Wins Register
    - `lib/core/crdt/lww_map.dart` - Last-Writer-Wins Map
    - Comprehensive unit tests for merge operations (99 tests)
  - **Requirements**: CRDT Sync Requirements
  - **Dependencies**: 1.2
  - **Status**: Complete (commit `various`)

- [x] **2.2** Create CRDT document base class ✅
  - **Description**: Abstract base for all CRDT-backed documents
  - **Deliverables**:
    - `lib/core/crdt/crdt_document.dart` - Base document class (318 lines)
    - Serialization to/from JSON (`toCrdtState()`)
    - Merge operation interface
    - Typed accessors (getString, setInt, getDateTime, getList, etc.)
    - Soft delete with delete()/restore()
    - Unit tests (34 tests)
  - **Requirements**: CRDT Sync Requirements
  - **Dependencies**: 2.1
  - **Status**: Complete (commit `a5bcf7b`)

- [x] **2.3** Implement Task document ✅
  - **Description**: CRDT-backed task model with all fields including Jira issue link
  - **Deliverables**:
    - `lib/features/tasks/models/task_document.dart` (~500 lines)
    - All task fields as CRDT types
    - Jira issue link fields (`issueId`, `issueType`, `issueProviderId`)
    - `linkToIssue()` / `unlinkIssue()` helpers
    - Conversion to/from UI model (`TaskModel`)
    - Conversion to/from Drift entity
    - Unit tests including concurrent edit scenarios (40 tests)
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 2.2, 1.4
  - **Status**: Complete (commit `f7578aa`)

- [x] **2.4** Implement Project, Tag, and Subtask documents
  - **Description**: CRDT-backed project, tag, and subtask models
  - **Deliverables**:
    - `lib/features/projects/models/project_document.dart`
    - `lib/features/tags/models/tag_document.dart`
    - `lib/features/tasks/models/subtask_document.dart`
    - Conversion utilities
    - Unit tests
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 2.2, 1.4
  - **Status**: Complete (commit `a235193`)

- [x] **2.5** Implement Worklog and JiraIntegration documents
  - **Description**: CRDT-backed time tracking entries and Jira config
  - **Deliverables**:
    - `lib/features/worklog/models/worklog_document.dart`
    - `lib/features/integrations/models/jira_integration_document.dart`
    - Link to task document
    - External credentials loading (`loadCredentials()`)
    - Duration calculations
    - Unit tests
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 2.2, 1.4
  - **Status**: Complete (commit `4b64044`)

### Phase 3: Core Features (Offline)

- [ ] **3.1** Build Task repository
  - **Description**: Data access layer for tasks with reactive streams
  - **Deliverables**:
    - `lib/features/tasks/data/task_repository.dart`
    - CRUD operations
    - Reactive `watchAll()` and `watchById()` streams
    - Query methods (by project, by tag, by status)
    - Integration tests with Drift
  - **Requirements**: Offline-First Requirements
  - **Dependencies**: 2.3

- [ ] **3.2** Build Task providers and actions
  - **Description**: Riverpod providers for task state management
  - **Deliverables**:
    - `lib/features/tasks/providers/task_providers.dart`
    - `tasksProvider` - all tasks stream
    - `taskByIdProvider` - single task
    - `taskActionsProvider` - create/update/delete
    - Derived providers (filtered, sorted)
    - Unit tests for providers
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 3.1

- [ ] **3.3** Build Task list screen
  - **Description**: Main task list UI with grouping and filtering
  - **Deliverables**:
    - `lib/features/tasks/screens/task_list_screen.dart`
    - Task list widget with pull-to-refresh
    - Task item widget
    - Filter/sort controls
    - Empty state
    - Widget tests
  - **Requirements**: User Experience Requirements
  - **Dependencies**: 3.2, 1.3

- [ ] **3.4** Build Task detail/edit screen
  - **Description**: Create and edit task UI
  - **Deliverables**:
    - `lib/features/tasks/screens/task_detail_screen.dart`
    - Form with all task fields
    - Project picker
    - Tag picker (multi-select)
    - Due date picker
    - Validation
    - Widget tests
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 3.2, 1.3

- [ ] **3.5** Build Project management
  - **Description**: Project CRUD and UI
  - **Deliverables**:
    - `lib/features/projects/data/project_repository.dart`
    - `lib/features/projects/providers/`
    - `lib/features/projects/screens/project_list_screen.dart`
    - `lib/features/projects/screens/project_detail_screen.dart`
    - Color picker for projects
    - Tests
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 2.4, 1.3

- [ ] **3.6** Build Tag management
  - **Description**: Tag CRUD and UI
  - **Deliverables**:
    - `lib/features/tags/data/tag_repository.dart`
    - `lib/features/tags/providers/`
    - `lib/features/tags/screens/tag_list_screen.dart`
    - Tag chip widgets
    - Tests
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 2.4, 1.3

- [ ] **3.7** Build Timer feature
  - **Description**: Time tracking with start/stop/pause
  - **Deliverables**:
    - `lib/features/timer/providers/timer_provider.dart`
    - `lib/features/timer/widgets/timer_widget.dart`
    - `lib/features/timer/widgets/timer_controls.dart`
    - Background timer handling
    - Persist timer state across app restarts
    - Auto-create worklog on stop
    - Tests
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 2.5, 3.2

- [ ] **3.8** Build Worklog feature
  - **Description**: View and manage time entries
  - **Deliverables**:
    - `lib/features/worklog/data/worklog_repository.dart`
    - `lib/features/worklog/providers/`
    - `lib/features/worklog/screens/worklog_screen.dart`
    - Daily/weekly summary views
    - Manual entry creation
    - Tests
  - **Requirements**: Core Feature Requirements
  - **Dependencies**: 2.5, 3.7

- [ ] **3.9** Build Jira integration repository and providers
  - **Description**: Data access layer for Jira integration config
  - **Deliverables**:
    - `lib/features/integrations/data/jira_repository.dart`
    - `lib/features/integrations/providers/jira_providers.dart`
    - CRUD operations for Jira integration configs
    - Credentials loading from external file
    - Integration tests with Drift
  - **Requirements**: Core Feature Requirements (Integration Data Models)
  - **Dependencies**: 1.5, 2.5
  - **Note**: No API sync yet - data layer only. GitHub integration deferred.

### Phase 4: P2P Sync

- [ ] **4.1** Implement device identity
  - **Description**: Unique device ID and key pair generation
  - **Deliverables**:
    - `lib/core/sync/device_identity.dart`
    - Persistent device ID
    - X25519 key pair generation and storage
    - Device name configuration
    - Secure storage for keys
  - **Requirements**: Security Requirements
  - **Dependencies**: 1.4

- [ ] **4.2** Implement local network discovery
  - **Description**: Find other devices on LAN using mDNS
  - **Deliverables**:
    - `lib/core/sync/peer_discovery.dart`
    - mDNS service registration
    - Peer discovery stream
    - Peer metadata (device name, ID)
    - Handle network changes
    - Integration tests
  - **Requirements**: P2P Communication Requirements
  - **Dependencies**: 4.1

- [ ] **4.3** Implement pairing protocol
  - **Description**: Secure device pairing with code exchange
  - **Deliverables**:
    - `lib/core/sync/pairing_service.dart`
    - Pairing code generation (time-limited)
    - Key exchange protocol
    - Paired device storage
    - Pairing UI screens
    - Tests
  - **Requirements**: P2P Communication Requirements, Security Requirements
  - **Dependencies**: 4.1, 4.2

- [ ] **4.4** Implement sync protocol
  - **Description**: Core sync message exchange logic
  - **Deliverables**:
    - `lib/core/sync/sync_protocol.dart`
    - `lib/core/sync/sync_messages.dart`
    - Vector clock comparison
    - Change detection (modified since)
    - Message serialization
    - Unit tests for protocol logic
  - **Requirements**: CRDT Sync Requirements
  - **Dependencies**: 2.2

- [ ] **4.5** Implement sync transport (WebSocket)
  - **Description**: Network transport for sync messages
  - **Deliverables**:
    - `lib/core/sync/sync_transport.dart`
    - WebSocket server (for receiving)
    - WebSocket client (for sending)
    - Connection management
    - Reconnection logic
    - Tests
  - **Requirements**: P2P Communication Requirements
  - **Dependencies**: 4.4

- [ ] **4.6** Implement encryption layer
  - **Description**: E2E encryption for sync traffic
  - **Deliverables**:
    - `lib/core/sync/encryption.dart`
    - XChaCha20-Poly1305 encryption
    - Key derivation from pairing
    - Encrypt/decrypt sync messages
    - Tests
  - **Requirements**: Security Requirements
  - **Dependencies**: 4.3

- [ ] **4.7** Implement full sync service
  - **Description**: Orchestrate all sync components
  - **Deliverables**:
    - `lib/core/sync/sync_service.dart`
    - Start/stop sync
    - Sync status stream
    - Manual sync trigger
    - Background sync scheduling
    - Error handling and retry
    - Integration tests
  - **Requirements**: CRDT Sync Requirements, P2P Communication Requirements
  - **Dependencies**: 4.2, 4.4, 4.5, 4.6

- [ ] **4.8** Build Sync UI
  - **Description**: User interface for sync status and device management
  - **Deliverables**:
    - `lib/features/sync/screens/sync_settings_screen.dart`
    - `lib/features/sync/screens/pairing_screen.dart`
    - `lib/features/sync/widgets/sync_status_indicator.dart`
    - Paired devices list
    - Sync now button
    - Widget tests
  - **Requirements**: User Experience Requirements
  - **Dependencies**: 4.7, 4.3

### Phase 5: Platform Builds

- [ ] **5.1** Android build configuration
  - **Description**: Production-ready Android build
  - **Deliverables**:
    - `android/` configuration for release builds
    - Signing configuration
    - ProGuard rules if needed
    - Background service for sync (WorkManager)
    - Notification channel setup
    - App icon and splash screen
    - Test on physical device
  - **Requirements**: Platform-Specific Features (Android)
  - **Dependencies**: 4.7, 3.7

- [ ] **5.2** Linux build configuration
  - **Description**: Production-ready Linux build
  - **Deliverables**:
    - `linux/` configuration
    - Desktop entry file
    - System tray integration
    - Global keyboard shortcuts
    - Package as AppImage/Flatpak/Snap
    - Test on target distribution
  - **Requirements**: Platform-Specific Features (Linux)
  - **Dependencies**: 4.7, 3.7

- [ ] **5.3** Implement platform service abstraction
  - **Description**: Cross-platform service for platform-specific features
  - **Deliverables**:
    - `lib/core/platform/platform_service.dart` - Interface
    - `lib/core/platform/android_platform_service.dart`
    - `lib/core/platform/linux_platform_service.dart`
    - Background sync, notifications, device name
    - Tests with platform mocks
  - **Requirements**: Platform-Specific Features
  - **Dependencies**: 5.1, 5.2

### Phase 6: Migration & Polish

- [ ] **6.1** Build data migration tool
  - **Description**: Import data from existing Super Productivity
  - **Deliverables**:
    - `lib/features/migration/migration_service.dart`
    - Parse Super Productivity JSON export
    - Convert to new CRDT documents
    - Progress reporting
    - Error handling for malformed data
    - `lib/features/migration/screens/migration_screen.dart`
    - Tests with sample exports
  - **Requirements**: Migration Strategy
  - **Dependencies**: 2.3, 2.4, 2.5

- [ ] **6.2** Settings screen
  - **Description**: User preferences and configuration
  - **Deliverables**:
    - `lib/features/settings/screens/settings_screen.dart`
    - Theme selection (light/dark/system)
    - Default project setting
    - Timer settings
    - Data export
    - About/version info
  - **Requirements**: User Experience Requirements
  - **Dependencies**: 1.3

- [ ] **6.3** Feature parity validation
  - **Description**: Verify all core features work correctly
  - **Deliverables**:
    - Feature checklist document
    - Manual testing protocol
    - Bug fixes as needed
    - Performance profiling
  - **Requirements**: Success Criteria
  - **Dependencies**: All previous tasks

- [ ] **6.4** Documentation
  - **Description**: User and developer documentation
  - **Deliverables**:
    - README with setup instructions
    - Architecture documentation
    - Sync protocol documentation
    - Contributing guide
  - **Requirements**: Maintainability
  - **Dependencies**: All previous tasks

- [ ] **6.5** Release preparation
  - **Description**: Prepare for initial release
  - **Deliverables**:
    - Version 0.1.0 tagging
    - GitHub release with binaries
    - Release notes
    - (Optional) Play Store listing draft
  - **Requirements**: Success Criteria
  - **Dependencies**: 6.3, 6.4

## Task Guidelines

### Task Completion Criteria

Each task is considered complete when:

- [ ] All deliverables are implemented and functional
- [ ] Unit tests are written and passing
- [ ] Code follows project coding standards (lint clean)
- [ ] Documentation updated (if applicable)
- [ ] Works on both Android and Linux (where applicable)

### Testing Requirements

- **Unit Tests**: Required for all CRDT logic, repositories, providers
- **Widget Tests**: Required for complex UI components
- **Integration Tests**: Required for database and sync operations
- **Manual Tests**: Required for platform-specific features

### Code Quality Standards

- All code must pass `flutter analyze` with zero issues
- Use `freezed` for immutable data classes
- Follow Riverpod best practices
- Document public APIs
- Keep functions small and focused

## Progress Tracking

### Milestone Checkpoints

- **Milestone 1**: Phase 1 Complete - Project foundation ready ✅
- **Milestone 2**: Phase 2 Complete - CRDT layer working (Tasks 2.1-2.3 done)
- **Milestone 3**: Phase 3 Complete - Fully functional offline app with Jira integration data layer
- **Milestone 4**: Phase 4 Complete - P2P sync working
- **Milestone 5**: Phase 5 Complete - Linux build ready (NixOS)
- **Milestone 6**: Phase 6 Complete - Ready for personal use

### Definition of Done

A task is considered "Done" when:

1. **Functionality**: All specified functionality implemented
2. **Testing**: All tests written and passing
3. **Quality**: Lint clean, no warnings
4. **Platform**: Works on target platforms
5. **Documentation**: Code documented where needed

## Risk Mitigation

### Technical Risks

- **Risk**: CRDT implementation complexity
  - **Mitigation**: Start with simple LWW types, add complexity incrementally
  - **Affected Tasks**: 2.1, 2.2

- **Risk**: P2P networking challenges
  - **Mitigation**: Get basic LAN sync working first, defer relay node
  - **Affected Tasks**: 4.2, 4.5

- **Risk**: Flutter Linux platform issues
  - **Mitigation**: Test early, have web fallback option
  - **Affected Tasks**: 5.2

### Dependency Risks

- **Risk**: Third-party package breaking changes
  - **Mitigation**: Pin versions, test upgrades carefully
  - **Affected Tasks**: All

## Resource Requirements

### Development Environment

- Flutter SDK (stable channel)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator for testing
- Linux machine for desktop testing
- Git

### External Dependencies

- `riverpod` - State management
- `drift` - Local database (SQLite)
- `freezed` - Code generation
- `go_router` - Navigation
- `nsd` or `bonsoir` - mDNS discovery
- `cryptography` - Encryption

## Git Tracking

**Repository**: `avodah`

**Branch Strategy**:

- `main` - Stable releases
- `develop` - Integration branch
- `feature/*` - Feature branches

---

**Task Status**: In Progress

**Current Phase**: Phase 2 (CRDT Foundation)

**Overall Progress**: ~8/35 tasks completed (~23%)
- Phase 1: ✅ Complete (5 tasks)
- Phase 2: 3/5 tasks done (2.1, 2.2, 2.3 ✅)

**Commits**: 15+ commits, 5 ahead of origin

**Tests**: 171 passing

**Last Updated**: 2026-02-09

**Assigned Developer**: Personal project

**Estimated Completion**: Incremental, no fixed deadline

**Platform**: Linux/NixOS (MVP), Android/iOS deferred
