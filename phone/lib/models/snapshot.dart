// Data models for the sync snapshot received from the desktop server.
// Plain Dart classes — no CRDT, no Drift.

class DaySnapshot {
  final int version;
  final DateTime timestamp;
  final String day;
  final TimerSnapshot? timer;
  final PlanSnapshot plan;
  final List<PlannedTaskSnapshot> plannedTasks;
  final WorklogSummarySnapshot worklogSummary;

  const DaySnapshot({
    required this.version,
    required this.timestamp,
    required this.day,
    required this.timer,
    required this.plan,
    required this.plannedTasks,
    required this.worklogSummary,
  });

  factory DaySnapshot.fromJson(Map<String, dynamic> json) {
    return DaySnapshot(
      version: json['version'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      day: json['day'] as String,
      timer: json['timer'] != null
          ? TimerSnapshot.fromJson(json['timer'] as Map<String, dynamic>)
          : null,
      plan: PlanSnapshot.fromJson(json['plan'] as Map<String, dynamic>),
      plannedTasks: (json['plannedTasks'] as List)
          .map((e) =>
              PlannedTaskSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      worklogSummary: WorklogSummarySnapshot.fromJson(
          json['worklogSummary'] as Map<String, dynamic>),
    );
  }
}

class TimerSnapshot {
  final bool isRunning;
  final bool isPaused;
  final String taskTitle;
  final String? taskId;
  final int elapsedMs;
  final String elapsed;
  final DateTime? startedAt;
  final String? note;

  /// The snapshot timestamp — needed for live elapsed computation.
  DateTime? _snapshotTimestamp;

  TimerSnapshot({
    required this.isRunning,
    required this.isPaused,
    required this.taskTitle,
    this.taskId,
    required this.elapsedMs,
    required this.elapsed,
    this.startedAt,
    this.note,
  });

  /// Sets the snapshot timestamp for live elapsed computation.
  set snapshotTimestamp(DateTime value) => _snapshotTimestamp = value;

  /// Computes live elapsed by adding time since snapshot was taken.
  Duration get liveElapsed {
    final base = Duration(milliseconds: elapsedMs);
    if (!isRunning || isPaused || _snapshotTimestamp == null) return base;
    final sinceSnapshot = DateTime.now().difference(_snapshotTimestamp!);
    return base + sinceSnapshot;
  }

  String get liveElapsedFormatted => _formatDuration(liveElapsed);

  factory TimerSnapshot.fromJson(Map<String, dynamic> json) {
    return TimerSnapshot(
      isRunning: json['isRunning'] as bool,
      isPaused: json['isPaused'] as bool,
      taskTitle: json['taskTitle'] as String,
      taskId: json['taskId'] as String?,
      elapsedMs: json['elapsedMs'] as int,
      elapsed: json['elapsed'] as String,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      note: json['note'] as String?,
    );
  }
}

class PlanSnapshot {
  final int totalPlannedMs;
  final String totalPlanned;
  final int totalActualMs;
  final String totalActual;
  final List<PlanCategorySnapshot> categories;
  final NonCategorizedSnapshot? nonCategorized;

  const PlanSnapshot({
    required this.totalPlannedMs,
    required this.totalPlanned,
    required this.totalActualMs,
    required this.totalActual,
    required this.categories,
    this.nonCategorized,
  });

  factory PlanSnapshot.fromJson(Map<String, dynamic> json) {
    return PlanSnapshot(
      totalPlannedMs: json['totalPlannedMs'] as int,
      totalPlanned: json['totalPlanned'] as String,
      totalActualMs: json['totalActualMs'] as int,
      totalActual: json['totalActual'] as String,
      categories: (json['categories'] as List)
          .map((e) =>
              PlanCategorySnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      nonCategorized: json['nonCategorized'] != null
          ? NonCategorizedSnapshot.fromJson(
              json['nonCategorized'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlanCategorySnapshot {
  final String category;
  final int plannedMs;
  final String planned;
  final int actualMs;
  final String actual;
  final int deltaMs;
  final String delta;

  const PlanCategorySnapshot({
    required this.category,
    required this.plannedMs,
    required this.planned,
    required this.actualMs,
    required this.actual,
    required this.deltaMs,
    required this.delta,
  });

  factory PlanCategorySnapshot.fromJson(Map<String, dynamic> json) {
    return PlanCategorySnapshot(
      category: json['category'] as String,
      plannedMs: json['plannedMs'] as int,
      planned: json['planned'] as String,
      actualMs: json['actualMs'] as int,
      actual: json['actual'] as String,
      deltaMs: json['deltaMs'] as int,
      delta: json['delta'] as String,
    );
  }
}

class NonCategorizedSnapshot {
  final int actualMs;
  final String actual;

  const NonCategorizedSnapshot({
    required this.actualMs,
    required this.actual,
  });

  factory NonCategorizedSnapshot.fromJson(Map<String, dynamic> json) {
    return NonCategorizedSnapshot(
      actualMs: json['actualMs'] as int,
      actual: json['actual'] as String,
    );
  }
}

class PlannedTaskSnapshot {
  final String taskId;
  final String title;
  final String? issueId;
  final String? category;
  final int estimateMs;
  final String estimate;
  final int loggedMs;
  final String logged;
  final bool isDone;
  final bool isCancelled;

  const PlannedTaskSnapshot({
    required this.taskId,
    required this.title,
    this.issueId,
    this.category,
    required this.estimateMs,
    required this.estimate,
    required this.loggedMs,
    required this.logged,
    required this.isDone,
    required this.isCancelled,
  });

  double get progress =>
      estimateMs > 0 ? (loggedMs / estimateMs).clamp(0.0, 2.0) : 0.0;

  factory PlannedTaskSnapshot.fromJson(Map<String, dynamic> json) {
    return PlannedTaskSnapshot(
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      issueId: json['issueId'] as String?,
      category: json['category'] as String?,
      estimateMs: json['estimateMs'] as int,
      estimate: json['estimate'] as String,
      loggedMs: json['loggedMs'] as int,
      logged: json['logged'] as String,
      isDone: json['isDone'] as bool,
      isCancelled: json['isCancelled'] as bool,
    );
  }
}

class WorklogSummarySnapshot {
  final String date;
  final int totalMs;
  final String total;
  final List<WorklogTaskSnapshot> tasks;

  const WorklogSummarySnapshot({
    required this.date,
    required this.totalMs,
    required this.total,
    required this.tasks,
  });

  factory WorklogSummarySnapshot.fromJson(Map<String, dynamic> json) {
    return WorklogSummarySnapshot(
      date: json['date'] as String,
      totalMs: json['totalMs'] as int,
      total: json['total'] as String,
      tasks: (json['tasks'] as List)
          .map(
              (e) => WorklogTaskSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorklogTaskSnapshot {
  final String taskId;
  final String title;
  final int totalMs;
  final String total;

  const WorklogTaskSnapshot({
    required this.taskId,
    required this.title,
    required this.totalMs,
    required this.total,
  });

  factory WorklogTaskSnapshot.fromJson(Map<String, dynamic> json) {
    return WorklogTaskSnapshot(
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      totalMs: json['totalMs'] as int,
      total: json['total'] as String,
    );
  }
}

String _formatDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes == 0) return '0m';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}
