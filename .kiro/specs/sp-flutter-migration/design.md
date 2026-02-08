# Super Productivity Flutter Migration Design Document

## Overview

This document details the technical design for rebuilding Super Productivity as a Flutter-based, local-first, P2P application. The architecture follows Anytype's principles: data lives locally, syncs peer-to-peer using CRDTs, and works fully offline without any server dependency.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Application                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    UI Layer (Widgets)                    │   │
│  │  - Screens (Tasks, Projects, Timer, Settings)           │   │
│  │  - Reusable Components                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              State Management (Riverpod)                 │   │
│  │  - Providers read from CRDT documents                    │   │
│  │  - Actions mutate CRDT documents                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   CRDT Document Layer                    │   │
│  │  - Task documents, Project documents, etc.               │   │
│  │  - Automatic merge on sync                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│          ┌───────────────────┼───────────────────┐              │
│          ▼                   ▼                   ▼              │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│  │   Storage    │   │  Sync Layer  │   │   Crypto     │        │
│  │   (Drift)    │   │   (P2P)      │   │   (E2E)      │        │
│  └──────────────┘   └──────────────┘   └──────────────┘        │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                               ▼
              ┌────────────────────────────────┐
              │        Network Layer           │
              │  - Local discovery (mDNS)      │
              │  - Direct P2P (WebSocket)      │
              │  - Optional relay node         │
              └────────────────────────────────┘
```

### Technology Stack

**Frontend Components**

- **Flutter 3.x**: Cross-platform UI framework
- **Riverpod**: State management with dependency injection
- **Material 3**: Design system with custom theming
- **go_router**: Navigation and routing

**Data Layer**

- **Drift**: SQLite-based reactive database for Flutter
- **CRDT Package**: `crdt` (Dart native) or `yrs` (Yjs Rust bindings via FFI)
- **freezed**: Immutable data classes with code generation

**Sync & Networking**

- **nsd**: Network Service Discovery for local peer finding
- **web_socket_channel**: WebSocket communication
- **cryptography**: Encryption for secure sync

**Infrastructure**

- **GitHub Actions**: CI/CD for builds
- **Fastlane**: Android release automation
- **Flutter Linux packaging**: Snap or Flatpak distribution

## Components and Interfaces

### Core Components

#### 1. Task Document (CRDT)

```dart
/// CRDT-backed task document
/// All fields are CRDT types for automatic conflict resolution
class TaskDocument {
  final String id;
  final LWWRegister<String> title;
  final LWWRegister<String?> description;
  final LWWRegister<String?> projectId;
  final LWWSet<String> tagIds;
  final LWWRegister<TaskStatus> status;
  final LWWRegister<int> timeEstimate; // in seconds
  final LWWRegister<int> timeSpent;    // in seconds
  final LWWRegister<DateTime?> dueDate;
  final LWWRegister<DateTime> createdAt;
  final LWWRegister<DateTime> updatedAt;
  final GCounter completedCount; // for recurring tasks

  // External issue tracking links
  final LWWRegister<String?> jiraIssueKey;      // e.g., "PROJ-123"
  final LWWRegister<String?> githubIssueNumber; // e.g., "owner/repo#42"

  // Merge with another document (from sync)
  TaskDocument merge(TaskDocument other);

  // Convert to/from storage format
  Map<String, dynamic> toJson();
  factory TaskDocument.fromJson(Map<String, dynamic> json);
}
```

#### 2. Jira Integration Document (CRDT)

```dart
/// CRDT-backed Jira integration configuration
class JiraIntegrationDocument {
  final String id;
  final LWWRegister<String> siteUrl;
  final LWWRegister<String?> cloudId;
  final LWWRegister<String?> defaultProjectKey;
  final LWWRegister<String?> userEmail;
  final LWWRegister<bool> isEnabled;
  final LWWRegister<Map<String, String>> statusMapping; // TaskStatus -> Jira transition
  final LWWRegister<DateTime> createdAt;
  final LWWRegister<DateTime> updatedAt;

  JiraIntegrationDocument merge(JiraIntegrationDocument other);
  Map<String, dynamic> toJson();
  factory JiraIntegrationDocument.fromJson(Map<String, dynamic> json);
}
```

#### 3. GitHub Integration Document (CRDT)

```dart
/// CRDT-backed GitHub integration configuration
class GitHubIntegrationDocument {
  final String id;
  final LWWRegister<String> owner;
  final LWWRegister<String> repo;
  final LWWRegister<String?> defaultLabels;
  final LWWRegister<bool> isEnabled;
  final LWWRegister<bool> syncWorklogs;
  final LWWRegister<DateTime> createdAt;
  final LWWRegister<DateTime> updatedAt;

  GitHubIntegrationDocument merge(GitHubIntegrationDocument other);
  Map<String, dynamic> toJson();
  factory GitHubIntegrationDocument.fromJson(Map<String, dynamic> json);
}
```

#### 4. Issue Link Document (CRDT)

```dart
/// CRDT-backed link between local task and external issue
class IssueLinkDocument {
  final String id;
  final LWWRegister<String> taskId;
  final LWWRegister<IssueLinkType> type;
  final LWWRegister<String> externalId;        // Jira key or GitHub issue#
  final LWWRegister<String> externalUrl;
  final LWWRegister<String?> externalTitle;    // Cached from external
  final LWWRegister<String?> externalStatus;   // Cached from external
  final LWWRegister<DateTime> linkedAt;
  final LWWRegister<DateTime?> lastSyncedAt;

  IssueLinkDocument merge(IssueLinkDocument other);
  Map<String, dynamic> toJson();
  factory IssueLinkDocument.fromJson(Map<String, dynamic> json);
}

enum IssueLinkType { jira, github }
```

#### 5. Sync Service

```dart
abstract class SyncService {
  /// Current sync status stream
  Stream<SyncStatus> get statusStream;

  /// Discovered peers on local network
  Stream<List<Peer>> get peersStream;

  /// Start sync service (discovery + listening)
  Future<void> start();

  /// Stop sync service
  Future<void> stop();

  /// Manually trigger sync with a specific peer
  Future<SyncResult> syncWithPeer(Peer peer);

  /// Sync with all available peers
  Future<List<SyncResult>> syncAll();

  /// Pair with a new device using pairing code
  Future<PairingResult> pairDevice(String pairingCode);

  /// Generate pairing code for this device
  Future<String> generatePairingCode();
}

enum SyncStatus {
  idle,
  discovering,
  syncing,
  error,
}

class Peer {
  final String id;
  final String displayName;
  final String address;
  final bool isOnline;
  final DateTime lastSeen;
}
```

#### 3. Storage Repository

```dart
abstract class StorageRepository<T> {
  /// Get all documents
  Future<List<T>> getAll();

  /// Get document by ID
  Future<T?> getById(String id);

  /// Save document (creates or updates)
  Future<void> save(T document);

  /// Delete document by ID
  Future<void> delete(String id);

  /// Watch all documents (reactive)
  Stream<List<T>> watchAll();

  /// Watch single document (reactive)
  Stream<T?> watchById(String id);

  /// Get documents modified since timestamp (for sync)
  Future<List<T>> getModifiedSince(DateTime timestamp);

  /// Apply remote changes from sync
  Future<void> applyRemoteChanges(List<T> documents);
}
```

### Data Models

#### Database Schema (Drift)

```dart
/// Tasks table
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get tagIds => text()(); // JSON array
  TextColumn get status => text()(); // TaskStatus enum as string
  IntColumn get timeEstimate => integer().withDefault(const Constant(0))();
  IntColumn get timeSpent => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // External issue links
  TextColumn get jiraIssueKey => text().nullable()();
  TextColumn get githubIssueNumber => text().nullable()();

  // CRDT metadata
  TextColumn get crdtClock => text()(); // Vector clock or HLC
  TextColumn get crdtState => text()(); // Serialized CRDT state

  @override
  Set<Column> get primaryKey => {id};
}

/// Projects table
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get crdtClock => text()();
  TextColumn get crdtState => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Worklogs table
class Worklogs extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get duration => integer()(); // in seconds
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get crdtClock => text()();
  TextColumn get crdtState => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Jira integration configuration
class JiraIntegrations extends Table {
  TextColumn get id => text()();
  TextColumn get siteUrl => text()();           // e.g., "https://company.atlassian.net"
  TextColumn get cloudId => text().nullable()();
  TextColumn get defaultProjectKey => text().nullable()();
  TextColumn get userEmail => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get statusMappingJson => text()(); // JSON serialized Map<String, String>
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get crdtClock => text()();
  TextColumn get crdtState => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// GitHub integration configuration
class GitHubIntegrations extends Table {
  TextColumn get id => text()();
  TextColumn get owner => text()();             // Repository owner/org
  TextColumn get repo => text()();              // Repository name
  TextColumn get defaultLabels => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get syncWorklogs => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get crdtClock => text()();
  TextColumn get crdtState => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Links a local task to an external issue (Jira or GitHub)
class IssueLinks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get type => text()();              // 'jira' or 'github'
  TextColumn get externalId => text()();        // Jira issue key or GitHub issue#
  TextColumn get externalUrl => text()();
  TextColumn get externalTitle => text().nullable()();
  TextColumn get externalStatus => text().nullable()();
  DateTimeColumn get linkedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get crdtClock => text()();
  TextColumn get crdtState => text()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### State Models

```dart
@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? description,
    String? projectId,
    required List<String> tagIds,
    required TaskStatus status,
    required int timeEstimate,
    required int timeSpent,
    DateTime? dueDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;
}

enum TaskStatus {
  todo,
  inProgress,
  done,
}

@freezed
class AppState with _$AppState {
  const factory AppState({
    required List<Task> tasks,
    required List<Project> projects,
    required List<Tag> tags,
    required TimerState timer,
    required SyncState sync,
  }) = _AppState;
}
```

### Riverpod Providers

```dart
// CRDT Document providers
final taskDocumentsProvider = StreamProvider<List<TaskDocument>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});

// Derived state (UI-friendly)
final tasksProvider = Provider<List<Task>>((ref) {
  final docs = ref.watch(taskDocumentsProvider).valueOrNull ?? [];
  return docs.map((doc) => doc.toTask()).toList();
});

// Filtered views
final tasksByProjectProvider = Provider.family<List<Task>, String?>((ref, projectId) {
  final tasks = ref.watch(tasksProvider);
  if (projectId == null) return tasks;
  return tasks.where((t) => t.projectId == projectId).toList();
});

// Actions
final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref.watch(taskRepositoryProvider));
});

class TaskActions {
  final TaskRepository _repository;

  TaskActions(this._repository);

  Future<void> create(TaskCreateInput input) async {
    final doc = TaskDocument.create(input);
    await _repository.save(doc);
  }

  Future<void> update(String id, TaskUpdateInput input) async {
    final doc = await _repository.getById(id);
    if (doc == null) return;
    doc.applyUpdate(input);
    await _repository.save(doc);
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
  }
}
```

## P2P Sync Protocol

### Discovery Phase

```
Device A                           Device B
    │                                  │
    │──── mDNS announce ──────────────>│
    │<─── mDNS announce ───────────────│
    │                                  │
    │ (Both devices now aware of each other)
    │                                  │
```

### Pairing Phase (First Time)

```
Device A                           Device B
    │                                  │
    │   [User initiates pairing]       │
    │──── Display pairing code ────>   │
    │                                  │
    │   [User enters code on B]        │
    │<─── Pairing request + code ──────│
    │                                  │
    │──── Key exchange (X25519) ──────>│
    │<─── Key exchange ────────────────│
    │                                  │
    │ (Shared secret established)      │
    │──── Encrypted ACK ──────────────>│
    │<─── Encrypted ACK ───────────────│
    │                                  │
    │ (Devices are now paired)         │
```

### Sync Phase

```
Device A                           Device B
    │                                  │
    │──── Sync request ───────────────>│
    │     (my vector clock)            │
    │                                  │
    │<─── Sync response ───────────────│
    │     (your missing changes)       │
    │     (my vector clock)            │
    │                                  │
    │──── Changes ────────────────────>│
    │     (B's missing changes)        │
    │                                  │
    │ (Both apply CRDT merge)          │
    │                                  │
    │<─── ACK ─────────────────────────│
    │──── ACK ────────────────────────>│
    │                                  │
```

### Message Format

```dart
sealed class SyncMessage {
  String get type;
  Map<String, dynamic> toJson();
}

class SyncRequest extends SyncMessage {
  final String deviceId;
  final Map<String, String> vectorClock; // collection -> clock

  @override
  String get type => 'sync_request';
}

class SyncResponse extends SyncMessage {
  final String deviceId;
  final Map<String, String> vectorClock;
  final List<DocumentChange> changes;

  @override
  String get type => 'sync_response';
}

class DocumentChange {
  final String collection;
  final String documentId;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic>? data;
  final String crdtState;
}
```

## Error Handling

### Error Categories

```dart
sealed class AppError {
  String get message;
  String get userMessage;
}

class StorageError extends AppError {
  final String operation;
  final Object? cause;

  @override
  String get message => 'Storage error during $operation: $cause';

  @override
  String get userMessage => 'Failed to save data. Please try again.';
}

class SyncError extends AppError {
  final SyncErrorType type;
  final String? peerId;

  @override
  String get message => 'Sync error ($type) with peer $peerId';

  @override
  String get userMessage => switch (type) {
    SyncErrorType.networkUnavailable => 'Network unavailable. Changes saved locally.',
    SyncErrorType.peerUnreachable => 'Device not reachable. Will retry automatically.',
    SyncErrorType.conflictResolutionFailed => 'Sync conflict. Please check your data.',
    SyncErrorType.encryptionFailed => 'Encryption error. Check device pairing.',
  };
}

enum SyncErrorType {
  networkUnavailable,
  peerUnreachable,
  conflictResolutionFailed,
  encryptionFailed,
}
```

## Testing Strategy

### Unit Tests (70%)

```dart
group('TaskDocument CRDT', () {
  test('merge combines changes from both sides', () {
    final doc1 = TaskDocument.create(title: 'Task 1');
    final doc2 = TaskDocument.fromJson(doc1.toJson());

    doc1.title.set('Updated on device 1');
    doc2.description.set('Added on device 2');

    final merged = doc1.merge(doc2);

    expect(merged.title.value, 'Updated on device 1');
    expect(merged.description.value, 'Added on device 2');
  });

  test('concurrent edits resolve deterministically', () {
    final doc1 = TaskDocument.create(title: 'Original');
    final doc2 = TaskDocument.fromJson(doc1.toJson());

    // Simulate concurrent edits
    doc1.title.set('Edit A', timestamp: DateTime(2024, 1, 1, 10, 0));
    doc2.title.set('Edit B', timestamp: DateTime(2024, 1, 1, 10, 1));

    final merged1 = doc1.merge(doc2);
    final merged2 = doc2.merge(doc1);

    // Both merge directions should produce same result
    expect(merged1.title.value, merged2.title.value);
    expect(merged1.title.value, 'Edit B'); // Later timestamp wins
  });
});
```

### Integration Tests (20%)

```dart
group('Sync Integration', () {
  test('full sync cycle between two devices', () async {
    final device1 = TestDevice();
    final device2 = TestDevice();

    // Create data on device 1
    await device1.createTask(title: 'Task from device 1');

    // Sync
    await device1.syncWith(device2);

    // Verify device 2 has the task
    final tasks = await device2.getAllTasks();
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Task from device 1');
  });
});
```

### E2E Tests (10%)

```dart
group('User Workflows', () {
  testWidgets('create task and track time', (tester) async {
    await tester.pumpWidget(SuperProductivityApp());

    // Create task
    await tester.tap(find.byIcon(Icons.add));
    await tester.enterText(find.byType(TextField), 'New Task');
    await tester.tap(find.text('Save'));

    // Start timer
    await tester.tap(find.text('New Task'));
    await tester.tap(find.byIcon(Icons.play_arrow));

    // Verify timer running
    expect(find.byIcon(Icons.stop), findsOneWidget);
  });
});
```

## Platform-Specific Considerations

### Android Features

```dart
class AndroidPlatformService implements PlatformService {
  @override
  Future<void> setupBackgroundSync() async {
    // Use WorkManager for periodic background sync
    await Workmanager().registerPeriodicTask(
      'sync',
      'backgroundSync',
      frequency: Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  @override
  Future<void> showNotification(String title, String body) async {
    await FlutterLocalNotificationsPlugin().show(
      0, title, body, notificationDetails,
    );
  }
}
```

### Linux Features

```dart
class LinuxPlatformService implements PlatformService {
  @override
  Future<void> setupSystemTray() async {
    await SystemTray().initSystemTray(
      title: 'Super Productivity',
      iconPath: 'assets/icon.png',
    );
  }

  @override
  Future<void> registerGlobalShortcuts() async {
    await hotKey.register(
      HotKey(KeyCode.space, modifiers: [KeyModifier.control, KeyModifier.alt]),
      callback: () => showQuickAdd(),
    );
  }
}
```

### Cross-Platform Abstraction

```dart
abstract class PlatformService {
  Future<void> initialize();
  Future<void> setupBackgroundSync();
  Future<void> showNotification(String title, String body);
  Future<String> getDeviceName();
  Future<Directory> getDataDirectory();
}

PlatformService getPlatformService() {
  if (Platform.isAndroid) return AndroidPlatformService();
  if (Platform.isLinux) return LinuxPlatformService();
  throw UnsupportedError('Platform not supported');
}
```

## Performance Considerations

### Performance Requirements

- App launch to interactive: <2 seconds
- Task list render (1000 items): <500ms
- Local save operation: <100ms
- Sync 100 changes: <5 seconds on LAN

### Optimization Strategies

- **Lazy loading**: Paginate task lists, load on demand
- **Incremental sync**: Only sync changed documents
- **Background processing**: Heavy CRDT operations off main thread
- **Efficient serialization**: Use binary format for CRDT state

### Monitoring

- Track sync duration per operation
- Monitor local storage size
- Log CRDT merge conflicts for debugging

## Security Considerations

### Encryption

- All sync traffic encrypted with XChaCha20-Poly1305
- Key exchange via X25519
- Device pairing uses time-limited codes

### Local Security

- Sensitive data (if any) in platform secure storage
- No analytics or telemetry
- All data stays on user devices

## Migration Strategy

### From Existing Super Productivity

```dart
class MigrationService {
  /// Import data from Super Productivity JSON export
  Future<MigrationResult> importFromJson(String jsonData) async {
    final data = json.decode(jsonData);

    // Parse and convert to new format
    final tasks = _parseTasks(data['tasks']);
    final projects = _parseProjects(data['projects']);
    final worklogs = _parseWorklogs(data['worklogs']);

    // Create CRDT documents
    for (final task in tasks) {
      await _taskRepository.save(TaskDocument.fromLegacy(task));
    }
    // ... repeat for other entities

    return MigrationResult(
      tasksImported: tasks.length,
      projectsImported: projects.length,
    );
  }
}
```

### Rollback Plan

- Keep existing Super Productivity installation functional
- Export functionality in new app for data backup
- No destructive migration (import only)

## Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── crdt/
│   │   ├── crdt_document.dart
│   │   ├── lww_register.dart
│   │   ├── lww_set.dart
│   │   └── vector_clock.dart
│   ├── sync/
│   │   ├── sync_service.dart
│   │   ├── peer_discovery.dart
│   │   ├── sync_protocol.dart
│   │   └── encryption.dart
│   ├── storage/
│   │   ├── database.dart
│   │   └── repositories/
│   └── platform/
│       ├── platform_service.dart
│       ├── android_service.dart
│       └── linux_service.dart
│
├── features/
│   ├── tasks/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── projects/
│   ├── tags/
│   ├── timer/
│   ├── worklog/
│   ├── sync/
│   ├── integrations/
│   │   ├── models/
│   │   │   ├── jira_integration_document.dart
│   │   │   ├── github_integration_document.dart
│   │   │   └── issue_link_document.dart
│   │   ├── data/
│   │   │   ├── jira_repository.dart
│   │   │   ├── github_repository.dart
│   │   │   └── issue_link_repository.dart
│   │   └── providers/
│   └── settings/
│
├── shared/
│   ├── widgets/
│   ├── theme/
│   └── utils/
│
└── generated/
    └── ... (freezed, drift, etc.)
```

---

**Requirements Traceability**: This design addresses all requirements from requirements.md, specifically:

- Offline-First: Storage + CRDT layer
- CRDT Sync: CRDT Document Layer + Sync Protocol
- P2P Communication: Sync Service + Discovery
- Core Features: Feature modules
- Platform-Specific: Platform abstraction layer

**Review Status**: Draft

**Last Updated**: 2025-02-06

**Reviewers**: Self-review (personal project)
