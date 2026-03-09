/// Service that assembles a read-only snapshot of today's plan data for sync.
library;

import 'package:avodah_core/avodah_core.dart';

import 'plan_service.dart';
import 'task_service.dart';
import 'timer_service.dart';
import 'worklog_service.dart';

/// Assembles a read-only snapshot of today's plan data for sync clients.
class SyncSnapshotService {
  final TimerService timerService;
  final TaskService taskService;
  final WorklogService worklogService;
  final PlanService planService;

  SyncSnapshotService({
    required this.timerService,
    required this.taskService,
    required this.worklogService,
    required this.planService,
  });

  /// Builds a complete snapshot of today's data as a JSON-serializable map.
  Future<Map<String, dynamic>> buildSnapshot() async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Gather all data in parallel where possible
    final results = await Future.wait([
      timerService.status(), // 0
      planService.summary(day: today), // 1
      planService.listTasksForDay(day: today), // 2
      worklogService.todaySummary(), // 3
    ]);

    final timer = results[0] as TimerDocument?;
    final planSummary = results[1] as DayPlanSummary;
    final plannedTasks = results[2] as List<DayPlanTaskDocument>;
    final worklogSummary = results[3] as DaySummary;

    // Build worklog lookup: taskId → logged duration
    final loggedByTask = <String, Duration>{};
    for (final ts in worklogSummary.tasks) {
      loggedByTask[ts.taskId] = ts.total;
    }

    // Resolve planned tasks
    final resolvedTasks = <Map<String, dynamic>>[];
    for (final pt in plannedTasks) {
      String title = '(unknown)';
      String? issueId;
      String? category;
      bool isDone = false;
      try {
        final task = await taskService.show(pt.taskId);
        title = task.title;
        issueId = task.issueId;
        category = task.category;
        isDone = task.isDone;
      } catch (_) {}

      final logged = loggedByTask[pt.taskId] ?? Duration.zero;
      resolvedTasks.add({
        'taskId': pt.taskId,
        'title': title,
        if (issueId != null) 'issueId': issueId,
        'category': category,
        'estimateMs': pt.estimateMs,
        'estimate': _formatDuration(Duration(milliseconds: pt.estimateMs)),
        'loggedMs': logged.inMilliseconds,
        'logged': _formatDuration(logged),
        'isDone': isDone,
        'isCancelled': pt.isCancelled,
      });
    }

    // Build snapshot
    return {
      'version': 1,
      'timestamp': now.toUtc().toIso8601String(),
      'day': today,
      'timer': _buildTimerBlock(timer),
      'plan': _buildPlanBlock(planSummary),
      'plannedTasks': resolvedTasks,
      'worklogSummary': await _buildWorklogBlock(worklogSummary),
    };
  }

  Map<String, dynamic>? _buildTimerBlock(TimerDocument? timer) {
    if (timer == null) return null;
    return {
      'isRunning': timer.isRunning,
      'isPaused': timer.isPaused,
      'taskTitle': timer.taskTitle,
      'taskId': timer.taskId,
      'elapsedMs': timer.elapsed.inMilliseconds,
      'elapsed': _formatDuration(timer.elapsed),
      'startedAt': timer.startedAt?.toUtc().toIso8601String(),
      'note': timer.note,
    };
  }

  Map<String, dynamic> _buildPlanBlock(DayPlanSummary summary) {
    return {
      'totalPlannedMs': summary.totalPlanned.inMilliseconds,
      'totalPlanned': _formatDuration(summary.totalPlanned),
      'totalActualMs': summary.totalActual.inMilliseconds,
      'totalActual': _formatDuration(summary.totalActual),
      'categories': summary.categories
          .map((c) => {
                'category': c.category,
                'plannedMs': c.planned.inMilliseconds,
                'planned': _formatDuration(c.planned),
                'actualMs': c.actual.inMilliseconds,
                'actual': _formatDuration(c.actual),
                'deltaMs': c.delta.inMilliseconds,
                'delta': _formatDeltaDuration(c.delta),
              })
          .toList(),
      if (summary.nonCategorized != null)
        'nonCategorized': {
          'actualMs': summary.nonCategorized!.actual.inMilliseconds,
          'actual': _formatDuration(summary.nonCategorized!.actual),
        },
    };
  }

  Future<Map<String, dynamic>> _buildWorklogBlock(DaySummary summary) async {
    final tasks = <Map<String, dynamic>>[];
    for (final t in summary.tasks) {
      // Resolve task title (DaySummary stores taskId as taskTitle)
      String title = t.taskTitle;
      try {
        final task = await taskService.show(t.taskId);
        title = task.title;
      } catch (_) {}
      tasks.add({
        'taskId': t.taskId,
        'title': title,
        'totalMs': t.total.inMilliseconds,
        'total': t.formattedDuration,
      });
    }
    return {
      'date': summary.date,
      'totalMs': summary.total.inMilliseconds,
      'total': summary.formattedDuration,
      'tasks': tasks,
    };
  }

  static String _formatDuration(Duration d) {
    final totalMinutes = d.inMinutes;
    if (totalMinutes == 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  static String _formatDeltaDuration(Duration d) {
    final ms = d.inMilliseconds;
    if (ms == 0) return '0m';
    final abs = Duration(milliseconds: ms.abs());
    final formatted = _formatDuration(abs);
    return ms > 0 ? '+$formatted' : '-$formatted';
  }
}
