# Super Productivity Flutter Migration Requirements

## 1. Introduction

This document specifies the requirements for migrating Super Productivity from an Angular/Electron application to a Flutter-based, local-first, peer-to-peer application. The goal is to create a lighter, more reliable, cross-platform productivity app that works fully offline and syncs between devices without requiring a central server.

**Architecture Overview**: Local-first application using CRDTs (Conflict-free Replicated Data Types) for automatic conflict resolution, with P2P sync capabilities inspired by Anytype's architecture. The app will be built in Flutter/Dart, targeting Android and Linux desktop initially.

## 2. User Stories

### Core Productivity

- **As a user**, I want to manage my tasks with projects and tags, so that I can organize my work effectively
- **As a user**, I want to track time spent on tasks, so that I can understand where my time goes
- **As a user**, I want the app to work completely offline, so that I can be productive without internet
- **As a user**, I want my data to sync automatically between my devices, so that I have access everywhere

### Multi-Device Experience

- **As a user**, I want to use the app on my Android phone, so that I can manage tasks on the go
- **As a user**, I want to use the app on my Linux desktop, so that I have a native experience
- **As a user**, I want my edits from any device to merge automatically, so that I never lose work due to conflicts

### Data Ownership

- **As a user**, I want all my data stored locally on my devices, so that I maintain full ownership
- **As a user**, I want P2P sync without a central server, so that my data remains private
- **As a user**, I want optional end-to-end encryption, so that sync is secure

## 3. Acceptance Criteria

### Offline-First Requirements

- **WHEN** the app starts without network, **THEN** the system **SHALL** load all data from local storage and be fully functional
- **WHEN** the user creates/edits/deletes data offline, **THEN** the system **SHALL** persist changes locally immediately
- **WHEN** network becomes available, **THEN** the system **SHALL** sync pending changes automatically
- **IF** the app has never synced, **THEN** the system **SHALL** function as a standalone app indefinitely

### CRDT Sync Requirements

- **WHEN** the same data is edited on multiple devices, **THEN** the system **SHALL** merge changes automatically without user intervention
- **WHEN** conflicts occur, **THEN** the system **SHALL** resolve them deterministically using CRDT semantics
- **WHEN** a device comes online after offline edits, **THEN** the system **SHALL** sync all changes without data loss
- **IF** sync fails partially, **THEN** the system **SHALL** retry and maintain consistency

### P2P Communication Requirements

- **WHEN** two devices are on the same local network, **THEN** the system **SHALL** discover each other automatically
- **WHEN** devices are discovered, **THEN** the system **SHALL** sync data directly without external servers
- **IF** a user sets up an optional relay node, **THEN** the system **SHALL** sync through it when direct connection fails
- **WHEN** syncing over network, **THEN** the system **SHALL** encrypt all data in transit

### Core Feature Requirements

- **WHEN** user creates a task, **THEN** the system **SHALL** store it with title, description, project, tags, and time estimates
- **WHEN** user starts a timer, **THEN** the system **SHALL** track elapsed time accurately
- **WHEN** user views worklog, **THEN** the system **SHALL** display time entries with accurate durations
- **WHEN** user organizes tasks, **THEN** the system **SHALL** support projects, tags, and due dates

### User Experience Requirements

- **WHEN** the app launches, **THEN** the system **SHALL** be interactive within 2 seconds
- **WHEN** performing any action, **THEN** the system **SHALL** provide immediate visual feedback
- **WHEN** syncing in background, **THEN** the system **SHALL** not block UI interactions
- **IF** sync status changes, **THEN** the system **SHALL** display a non-intrusive indicator

### Performance Requirements

- **WHEN** loading task list with 1000+ tasks, **THEN** the system **SHALL** render within 500ms
- **WHEN** saving changes, **THEN** the system **SHALL** persist to local storage within 100ms
- **WHEN** idle, **THEN** the system **SHALL** use minimal battery/CPU resources

### Security Requirements

- **WHEN** syncing between devices, **THEN** the system **SHALL** use end-to-end encryption
- **WHEN** storing sensitive data locally, **THEN** the system **SHALL** use platform secure storage where available
- **IF** user enables encryption key, **THEN** the system **SHALL** require it for sync pairing

## 4. Technical Architecture

### Frontend Architecture

- **Framework**: Flutter 3.x
- **State Management**: Riverpod (preferred) or Bloc
- **UI Components**: Material 3 with custom theming
- **Styling**: Flutter's built-in styling with theme extensions

### Data Layer Architecture

- **Local Storage**: Isar or Hive for persistent storage
- **CRDT Library**: Dart-native CRDT implementation or Yjs/Automerge via FFI
- **Data Models**: Dart classes with CRDT document wrappers

### Sync Architecture

- **Protocol**: Custom P2P protocol over WebSocket/WebRTC
- **Discovery**: mDNS/DNS-SD for local network discovery
- **Encryption**: libsodium or similar for E2E encryption
- **Optional Relay**: Self-hostable relay node for remote sync

### Key Libraries & Dependencies

- **State**: `riverpod` or `flutter_bloc` for state management
- **Storage**: `isar` or `hive` for local database
- **Networking**: `web_socket_channel`, `nsd` for discovery
- **Crypto**: `cryptography` or `sodium_libs` for encryption

## 5. Feature Specifications

### Core Features

1. **Task Management**: Create, edit, delete, organize tasks with full offline support
2. **Time Tracking**: Start/stop timer, manual time entries, worklog history
3. **Projects**: Group tasks by project, project-level settings
4. **Tags**: Flexible tagging system, tag-based views

### Advanced Features

1. **CRDT Sync**: Automatic conflict-free synchronization
2. **P2P Discovery**: Local network device discovery
3. **Data Migration**: Import data from existing Super Productivity installation

### Platform-Specific Features

1. **Android**: Background sync, notifications, widgets (future)
2. **Linux**: System tray, keyboard shortcuts, native file integration
3. **Future Platforms**: Windows, macOS, iOS (architecture supports expansion)

## 6. Success Criteria

### User Experience

- **WHEN** user completes migration, **THEN** users **SHALL** have all previous data accessible
- **WHEN** using daily, **THEN** users **SHALL** experience zero data loss from sync
- **WHEN** switching devices, **THEN** users **SHALL** see consistent data within 30 seconds of sync

### Technical Performance

- **WHEN** running on mid-range Android (2020+), **THEN** the system **SHALL** maintain 60fps UI
- **WHEN** running on Linux desktop, **THEN** the system **SHALL** use <100MB RAM idle
- **WHEN** syncing 1000 items, **THEN** the system **SHALL** complete within 10 seconds on LAN

### Personal Goals

- **WHEN** compared to Electron version, **THEN** the system **SHALL** feel lighter and more responsive
- **WHEN** using offline, **THEN** the system **SHALL** be indistinguishable from online usage
- **WHEN** setting up new device, **THEN** the system **SHALL** sync via simple pairing flow

## 7. Assumptions and Dependencies

### Technical Assumptions

- Flutter stable supports Linux and Android adequately
- Dart CRDT libraries are mature enough or FFI to Rust/JS is viable
- Local network P2P is achievable on both platforms without store restrictions

### External Dependencies

- Flutter SDK and toolchain
- CRDT library (to be evaluated: crdt, yrs via FFI, custom)
- Networking libraries for P2P

### Resource Assumptions

- Single developer (personal project)
- Incremental development over extended period
- Can reference existing TypeScript implementation for logic

## 8. Constraints and Limitations

### Technical Constraints

- Must work offline-first (no server dependency)
- Must support Android and Linux as primary targets
- Bundle size should be reasonable for mobile (<50MB)

### Scope Constraints

- Initial version focuses on core task/time features
- Advanced features (Jira sync, Pomodoro, etc.) are Phase 2+
- iOS/Windows/macOS are future considerations, not initial scope

### Platform Constraints

- Android: Play Store policies for background services
- Linux: Variety of distributions to consider

## 9. Risk Assessment

### Technical Risks

- **Risk**: CRDT library limitations or bugs
  - **Likelihood**: Medium
  - **Impact**: High
  - **Mitigation**: Evaluate multiple libraries early, have fallback to simpler sync

- **Risk**: P2P networking complexity across platforms
  - **Likelihood**: Medium
  - **Impact**: Medium
  - **Mitigation**: Start with file-based sync, add P2P incrementally

- **Risk**: Flutter Linux stability issues
  - **Likelihood**: Low
  - **Impact**: Medium
  - **Mitigation**: Test early, have web fallback option

### Migration Risks

- **Risk**: Data migration from old format fails
  - **Likelihood**: Low
  - **Impact**: High
  - **Mitigation**: Build robust import tool, keep old app available

## 10. Non-Functional Requirements

### Scalability

- Support 10,000+ tasks without performance degradation
- Support unlimited projects and tags
- Sync efficiently with large datasets

### Availability

- App must work 100% offline
- Sync should be resilient to network interruptions
- No single point of failure (no central server)

### Maintainability

- Clean architecture with separation of concerns
- Comprehensive test coverage for core logic
- Well-documented CRDT and sync layer

### Usability

- Familiar UX for existing Super Productivity users
- Intuitive sync pairing process
- Clear sync status indicators

## 11. Future Considerations

### Phase 2 Features

- Pomodoro timer integration
- Recurring tasks
- Jira/GitHub integration
- Calendar integration

### Platform Expansion

- iOS app
- Windows desktop
- macOS desktop
- Web version (via Flutter web)

### Advanced Sync

- Selective sync (choose what syncs)
- Backup to cloud storage (encrypted)
- Shared projects (multi-user)

---

**Document Status**: Draft

**Last Updated**: 2025-02-06

**Stakeholders**: Personal project

**Related Documents**:

- Original Super Productivity: https://github.com/johannesjo/super-productivity
- Anytype (architecture inspiration): https://anytype.io

**Version**: 0.1
