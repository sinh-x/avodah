import 'package:flutter/material.dart';

import '../models/focus_item.dart';

/// Stale thresholds from PA-1092: pending-approval 2d, implementing 5d,
/// review-uat 3d.
int _staleThreshold(String status) {
  switch (status) {
    case 'pending-approval':
      return 2;
    case 'implementing':
      return 5;
    case 'review-uat':
      return 3;
    default:
      return 5; // default threshold
  }
}

/// A compact Material 3 card displaying a focus item for the GTD Focus view.
///
/// Shows ticket ID, title, project badge, priority indicator, stale badge,
/// and blocked badge. Tap callback for navigation.
class FocusItemCard extends StatelessWidget {
  final FocusItem item;
  final VoidCallback? onTap;

  const FocusItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: ticket ID + priority indicator + title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PriorityIndicator(priority: item.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.id,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Badges row
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _ProjectBadge(project: item.project),
                  if (item.staleDays > 0) _StaleBadge(item: item),
                  if (item.isBlocked) _BlockedBadge(blockerIds: item.blockerIds),
                ],
              ),
              // Assignee row
              if (item.assignee != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.assignee!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Priority color indicator — colored dot + label.
class _PriorityIndicator extends StatelessWidget {
  final String priority;

  const _PriorityIndicator({required this.priority});

  Color _color() {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Project badge — colored chip showing project name.
class _ProjectBadge extends StatelessWidget {
  final String project;

  const _ProjectBadge({required this.project});

  Color _projectColor(String project) {
    // Simple hash-based colors for project badges
    final hash = project.hashCode.abs();
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.purple,
      Colors.blueGrey,
      Colors.brown,
      Colors.green,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _projectColor(project);
    return _BadgeChip(
      label: project.toUpperCase(),
      color: color,
    );
  }
}

/// Stale badge — orange for mild (>0 but <= threshold), red for severe (>threshold).
class _StaleBadge extends StatelessWidget {
  final FocusItem item;

  const _StaleBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final threshold = _staleThreshold(item.status);
    final isSevere = item.staleDays > threshold;
    final color = isSevere ? Colors.red : Colors.orange;
    return _BadgeChip(
      label: 'STALE ${item.staleDays}d',
      color: color,
    );
  }
}

/// Blocked badge — shows blocker ticket IDs.
class _BlockedBadge extends StatelessWidget {
  final List<String> blockerIds;

  const _BlockedBadge({required this.blockerIds});

  @override
  Widget build(BuildContext context) {
    final label =
        blockerIds.isEmpty ? 'BLOCKED' : 'BLOCKED by ${blockerIds.join(", ")}';
    return _BadgeChip(
      label: label,
      color: Colors.red.shade700,
    );
  }
}

/// Shared colored badge chip widget.
class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}