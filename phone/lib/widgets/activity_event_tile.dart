import 'package:flutter/material.dart';

import '../models/activity_event.dart';

/// Renders a single activity event in a timeline style.
///
/// Supports [expanded] mode to show event data fields below the label.
class ActivityEventTile extends StatelessWidget {
  final ActivityEvent event;
  final bool expanded;

  const ActivityEventTile({
    super.key,
    required this.event,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _eventColor(context, event.event);
    final icon = _eventIcon(event.event);
    final time =
        event.timestamp != null ? _formatTime(event.timestamp!) : event.ts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _buildLabel(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: event.isMilestone
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                if (event.agent.isNotEmpty)
                  Text(
                    event.agent,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                if (expanded && event.data.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildDataSection(theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildLabel() {
    switch (event.event) {
      case 'tool_call':
        final tool = event.data['tool'] as String?;
        final status = event.data['status'] as String?;
        if (tool != null && status != null) return 'Tool: $tool ($status)';
        if (tool != null) return 'Tool: $tool';
        return 'Tool call';
      case 'agent_spawned':
        final name = event.data['name'] as String? ?? event.data['agent'] as String?;
        return name != null ? 'Agent spawned: $name' : 'Agent spawned';
      case 'agent_stopped':
        return 'Agent stopped';
      case 'task_completed':
        final taskId = event.data['task_id'] as String?;
        return taskId != null ? 'Task completed: $taskId' : 'Task completed';
      case 'task_failed':
        final taskId = event.data['task_id'] as String?;
        return taskId != null ? 'Task failed: $taskId' : 'Task failed';
      case 'child_deploy_started':
        final deployId = event.data['deploy_id'] as String?;
        return deployId != null
            ? 'Child deploy: $deployId'
            : 'Child deploy started';
      case 'deployment_started':
        return 'Deployment started';
      case 'deployment_completed':
        final status = event.data['status'] as String?;
        return status != null
            ? 'Deployment completed ($status)'
            : 'Deployment completed';
      default:
        return event.eventLabel;
    }
  }

  Widget _buildDataSection(ThemeData theme) {
    final entries = event.data.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries
            .map((e) => Text(
                  '${e.key}: ${e.value}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontFamily: 'monospace'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ))
            .toList(),
      ),
    );
  }
}

Color _eventColor(BuildContext context, String eventType) {
  switch (eventType) {
    case 'deployment_started':
    case 'agent_spawned':
      return Colors.blue;
    case 'deployment_completed':
    case 'task_completed':
    case 'agent_stopped':
      return Colors.green;
    case 'task_failed':
      return Colors.red;
    case 'tool_call':
      return Colors.purple;
    case 'child_deploy_started':
      return Colors.teal;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}

IconData _eventIcon(String eventType) {
  switch (eventType) {
    case 'deployment_started':
      return Icons.rocket_launch;
    case 'deployment_completed':
      return Icons.check_circle;
    case 'agent_spawned':
      return Icons.person_add;
    case 'agent_stopped':
      return Icons.person_off;
    case 'task_completed':
      return Icons.task_alt;
    case 'task_failed':
      return Icons.cancel;
    case 'tool_call':
      return Icons.build;
    case 'child_deploy_started':
      return Icons.fork_right;
    default:
      return Icons.circle_outlined;
  }
}

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  final s = local.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}
