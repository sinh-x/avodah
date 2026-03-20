import 'package:flutter/material.dart';

import '../models/snapshot.dart';

/// Bottom sheet with actions for a planned task.
///
/// Actions:
/// - Start Timer (hidden for done/cancelled tasks)
/// - Mark Done / Mark Undone
/// - Cancel (dismisses sheet)
///
/// If a timer is already running when the user taps "Start Timer",
/// a confirmation dialog asks before switching.
class TaskActionSheet extends StatelessWidget {
  final PlannedTaskSnapshot task;
  final TimerSnapshot? activeTimer;

  /// Called after the sheet is dismissed and the timer should start.
  final Future<void> Function(String taskId, String taskTitle)? onStartTimer;

  /// Called after the sheet is dismissed and done state should toggle.
  final Future<void> Function(String taskId)? onToggleDone;

  const TaskActionSheet({
    super.key,
    required this.task,
    this.activeTimer,
    this.onStartTimer,
    this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doneLabel = task.isDone ? 'Mark Undone' : 'Mark Done';
    final doneIcon =
        task.isDone ? Icons.undo : Icons.check_circle_outline;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              task.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          if (!task.isCancelled && !task.isDone)
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Start Timer'),
              onTap: () => _onStartTimerTap(context),
            ),
          if (!task.isCancelled)
            ListTile(
              leading: Icon(doneIcon),
              title: Text(doneLabel),
              onTap: () {
                Navigator.pop(context);
                onToggleDone?.call(task.taskId);
              },
            ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _onStartTimerTap(BuildContext context) async {
    if (activeTimer != null && activeTimer!.isRunning) {
      final elapsed = activeTimer!.liveElapsedFormatted;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Timer Running'),
          content: Text(
            'Stop "${activeTimer!.taskTitle}" ($elapsed) and start "${task.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Switch Timer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (context.mounted) Navigator.pop(context);
    onStartTimer?.call(task.taskId, task.title);
  }
}
