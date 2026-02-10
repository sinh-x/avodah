/// CRDT-backed Timer document for conflict-free synchronization.
///
/// Tracks the currently running timer state. Only one timer can be active
/// at a time (well-known ID: 'active-timer'). Supports crash recovery
/// and sync across devices.
library;

import 'package:drift/drift.dart';
import '../crdt/crdt.dart';
import '../storage/database.dart';

/// Well-known ID for the singleton active timer.
const String activeTimerId = 'active-timer';

/// Field keys for TimerDocument.
class TimerFields {
  TimerFields._();

  static const String taskId = 'taskId';
  static const String taskTitle = 'taskTitle';
  static const String projectId = 'projectId';
  static const String projectTitle = 'projectTitle';
  static const String startedAt = 'startedAt';
  static const String isRunning = 'isRunning';
  static const String pausedAt = 'pausedAt';
  static const String accumulatedMs = 'accumulatedMs';
  static const String note = 'note';
}

/// A CRDT-backed timer document.
///
/// All fields are tracked with individual timestamps for fine-grained
/// conflict resolution during P2P sync.
class TimerDocument extends CrdtDocument<TimerDocument> {
  /// Creates or gets the singleton active timer.
  factory TimerDocument.active({
    required HybridLogicalClock clock,
  }) {
    return TimerDocument(
      id: activeTimerId,
      clock: clock,
    );
  }

  /// Starts a new timer session.
  factory TimerDocument.start({
    required HybridLogicalClock clock,
    required String taskTitle,
    String? taskId,
    String? projectId,
    String? projectTitle,
    String? note,
  }) {
    final doc = TimerDocument(
      id: activeTimerId,
      clock: clock,
    );
    doc.taskId = taskId;
    doc.taskTitle = taskTitle;
    doc.projectId = projectId;
    doc.projectTitle = projectTitle;
    doc.note = note;
    doc.startedAtMs = DateTime.now().millisecondsSinceEpoch;
    doc.isRunning = true;
    doc.pausedAtMs = null;
    doc.accumulatedMs = 0;
    return doc;
  }

  /// Creates a timer document with an existing ID.
  TimerDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a timer document from existing CRDT state.
  TimerDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a timer document from a Drift TimerEntry entity.
  factory TimerDocument.fromDrift({
    required TimerEntry timer,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(timer.crdtState);

    final doc = TimerDocument.fromState(
      id: timer.id,
      clock: clock,
      state: state,
    );

    // If no CRDT state exists, initialize from Drift fields
    if (state.isEmpty) {
      doc._initializeFromDrift(timer);
    }

    return doc;
  }

  /// Initializes fields from Drift entity when no CRDT state exists.
  void _initializeFromDrift(TimerEntry timer) {
    setString(TimerFields.taskId, timer.taskId);
    setString(TimerFields.taskTitle, timer.taskTitle);
    setString(TimerFields.projectId, timer.projectId);
    setString(TimerFields.projectTitle, timer.projectTitle);
    setInt(TimerFields.startedAt, timer.startedAt);
    setBool(TimerFields.isRunning, timer.isRunning);
    setInt(TimerFields.pausedAt, timer.pausedAt);
    setInt(TimerFields.accumulatedMs, timer.accumulatedMs);
    setString(TimerFields.note, timer.note);
  }

  // ============================================================
  // Core Fields
  // ============================================================

  /// Task ID being timed (null for ad-hoc tasks).
  String? get taskId => getString(TimerFields.taskId);
  set taskId(String? value) => setString(TimerFields.taskId, value);

  /// Task title (denormalized for display).
  String get taskTitle => getString(TimerFields.taskTitle) ?? '';
  set taskTitle(String value) => setString(TimerFields.taskTitle, value);

  /// Project ID (null if no project).
  String? get projectId => getString(TimerFields.projectId);
  set projectId(String? value) => setString(TimerFields.projectId, value);

  /// Project title (denormalized for display).
  String? get projectTitle => getString(TimerFields.projectTitle);
  set projectTitle(String? value) =>
      setString(TimerFields.projectTitle, value);

  /// Optional note about current work.
  String? get note => getString(TimerFields.note);
  set note(String? value) => setString(TimerFields.note, value);

  // ============================================================
  // Timer State
  // ============================================================

  /// When the timer was started (Unix ms).
  int? get startedAtMs => getInt(TimerFields.startedAt);
  set startedAtMs(int? value) => setInt(TimerFields.startedAt, value);

  /// When the timer was started as DateTime.
  DateTime? get startedAt => startedAtMs != null
      ? DateTime.fromMillisecondsSinceEpoch(startedAtMs!)
      : null;

  /// Whether the timer is currently running.
  bool get isRunning => getBool(TimerFields.isRunning) ?? false;
  set isRunning(bool value) => setBool(TimerFields.isRunning, value);

  /// When the timer was paused (Unix ms, null if not paused).
  int? get pausedAtMs => getInt(TimerFields.pausedAt);
  set pausedAtMs(int? value) => setInt(TimerFields.pausedAt, value);

  /// When the timer was paused as DateTime.
  DateTime? get pausedAt => pausedAtMs != null
      ? DateTime.fromMillisecondsSinceEpoch(pausedAtMs!)
      : null;

  /// Whether the timer is currently paused.
  bool get isPaused => pausedAtMs != null && isRunning;

  /// Time accumulated before pause (ms).
  int get accumulatedMs => getInt(TimerFields.accumulatedMs) ?? 0;
  set accumulatedMs(int value) => setInt(TimerFields.accumulatedMs, value);

  /// Whether the timer is idle (not started).
  bool get isIdle => !isRunning && startedAtMs == null;

  // ============================================================
  // Elapsed Time Calculation
  // ============================================================

  /// Total elapsed time including current session.
  Duration get elapsed {
    if (startedAtMs == null) return Duration.zero;

    final accumulated = Duration(milliseconds: accumulatedMs);

    if (isPaused) {
      // Timer is paused, return accumulated time only
      return accumulated;
    }

    if (!isRunning) {
      // Timer is stopped
      return accumulated;
    }

    // Timer is running, calculate current session
    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionMs = now - startedAtMs!;
    return accumulated + Duration(milliseconds: sessionMs);
  }

  /// Elapsed time formatted as "Xh Ym" or "Xm".
  String get elapsedFormatted {
    final d = elapsed;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // ============================================================
  // Timer Actions
  // ============================================================

  /// Pauses the timer.
  void pause() {
    if (!isRunning || isPaused) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Add current session to accumulated
    if (startedAtMs != null) {
      accumulatedMs = accumulatedMs + (now - startedAtMs!);
    }
    pausedAtMs = now;
  }

  /// Resumes a paused timer.
  void resume() {
    if (!isPaused) return;

    // Reset start time to now (accumulated already saved)
    startedAtMs = DateTime.now().millisecondsSinceEpoch;
    pausedAtMs = null;
  }

  /// Stops the timer and returns total elapsed milliseconds.
  int stop() {
    final totalMs = elapsed.inMilliseconds;

    // Reset all timer state
    isRunning = false;
    startedAtMs = null;
    pausedAtMs = null;
    accumulatedMs = 0;
    taskId = null;
    taskTitle = '';
    projectId = null;
    projectTitle = null;
    note = null;

    return totalMs;
  }

  /// Cancels the timer without returning elapsed time.
  void cancel() {
    stop();
  }

  // ============================================================
  // Conversion
  // ============================================================

  /// Converts to a Drift TimerEntriesCompanion for insert/update.
  TimerEntriesCompanion toDriftCompanion() {
    return TimerEntriesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      taskTitle: Value(taskTitle),
      projectId: Value(projectId),
      projectTitle: Value(projectTitle),
      startedAt: Value(startedAtMs ?? 0),
      isRunning: Value(isRunning),
      pausedAt: Value(pausedAtMs),
      accumulatedMs: Value(accumulatedMs),
      note: Value(note),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  /// Converts to an immutable Timer UI model.
  TimerModel toModel() {
    return TimerModel(
      isRunning: isRunning,
      isPaused: isPaused,
      isIdle: isIdle,
      taskId: taskId,
      taskTitle: taskTitle,
      projectId: projectId,
      projectTitle: projectTitle,
      startedAt: startedAt,
      elapsed: elapsed,
      elapsedFormatted: elapsedFormatted,
      note: note,
    );
  }

  @override
  TimerDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return TimerDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable timer model for UI consumption.
class TimerModel {
  final bool isRunning;
  final bool isPaused;
  final bool isIdle;
  final String? taskId;
  final String taskTitle;
  final String? projectId;
  final String? projectTitle;
  final DateTime? startedAt;
  final Duration elapsed;
  final String elapsedFormatted;
  final String? note;

  const TimerModel({
    required this.isRunning,
    required this.isPaused,
    required this.isIdle,
    this.taskId,
    required this.taskTitle,
    this.projectId,
    this.projectTitle,
    this.startedAt,
    required this.elapsed,
    required this.elapsedFormatted,
    this.note,
  });

  @override
  String toString() =>
      'TimerModel(running: $isRunning, task: "$taskTitle", elapsed: $elapsedFormatted)';
}
