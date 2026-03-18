import 'package:flutter/material.dart';

import '../models/snapshot.dart';

class PlannedTaskList extends StatelessWidget {
  final List<PlannedTaskSnapshot> tasks;

  /// Called when user taps a task to toggle its done state.
  final Future<void> Function(String taskId)? onToggleDone;

  const PlannedTaskList({super.key, required this.tasks, this.onToggleDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Planned Tasks',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${tasks.where((t) => t.isDone).length}/${tasks.length}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
            const Divider(),
            ...tasks.map((t) => _TaskRow(task: t, onToggleDone: onToggleDone)),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final PlannedTaskSnapshot task;

  /// Called when user taps to toggle done state.
  final Future<void> Function(String taskId)? onToggleDone;

  const _TaskRow({required this.task, this.onToggleDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final IconData icon;
    final Color iconColor;
    if (task.isDone) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (task.isCancelled) {
      icon = Icons.cancel;
      iconColor = Colors.red.shade300;
    } else {
      icon = Icons.radio_button_unchecked;
      iconColor = theme.colorScheme.outline;
    }

    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      decoration: task.isDone || task.isCancelled
          ? TextDecoration.lineThrough
          : null,
      color: task.isDone || task.isCancelled
          ? theme.colorScheme.outline
          : null,
    );

    return InkWell(
      onTap: (onToggleDone != null && !task.isCancelled)
          ? () => onToggleDone!(task.taskId)
          : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(task.title,
                              style: titleStyle,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (task.issueId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(task.issueId!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme
                                        .onPrimaryContainer)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (task.estimateMs > 0) ...[
                          Text('Est: ${task.estimate}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.outline)),
                          const SizedBox(width: 12),
                        ],
                        Text('Logged: ${task.logged}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w600)),
                        if (task.estimateMs > 0) ...[
                          const Spacer(),
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: task.progress.clamp(0.0, 1.0),
                                minHeight: 3,
                                backgroundColor: theme
                                    .colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  task.progress > 1.0
                                      ? Colors.red.shade400
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
