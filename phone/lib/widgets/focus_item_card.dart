import 'package:flutter/material.dart';

import '../models/deployment.dart';
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
/// and blocked badge. Tap callback for navigation. When [deployment] is
/// provided, shows a deployment badge with team name, elapsed time, and
/// running indicator.
///
/// When [isBottomItem] is true, applies a dimmed visual style.
class FocusItemCard extends StatelessWidget {
  final FocusItem item;
  final VoidCallback? onTap;
  final Deployment? deployment;
  final bool isBottomItem;
  final VoidCallback? onDismissed;

  const FocusItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.deployment,
    this.isBottomItem = false,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardContent = Opacity(
      opacity: isBottomItem ? 0.5 : 1.0,
      child: Card(
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
                // Deployment badge row (when deployment is active)
                if (deployment != null) ...[
                  const SizedBox(height: 4),
                  _DeploymentBadge(deployment: deployment!),
                ],
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
      ),
    );

    if (onDismissed != null) {
      return Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Send to bottom',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        onDismissed: (_) => onDismissed?.call(),
        child: cardContent,
      );
    }

    return cardContent;
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

/// Deployment badge — shows team name, elapsed time, and animated running indicator.
class _DeploymentBadge extends StatelessWidget {
  final Deployment deployment;

  const _DeploymentBadge({required this.deployment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedRunningDot(),
          const SizedBox(width: 4),
          Text(
            deployment.team,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            deployment.elapsedDuration,
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated running indicator dot.
class _AnimatedRunningDot extends StatefulWidget {
  @override
  State<_AnimatedRunningDot> createState() => _AnimatedRunningDotState();
}

class _AnimatedRunningDotState extends State<_AnimatedRunningDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: _animation.value),
          ),
        );
      },
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