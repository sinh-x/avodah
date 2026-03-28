import 'package:flutter/material.dart';

import '../models/snapshot.dart';

class WorklogSummary extends StatefulWidget {
  final WorklogSummarySnapshot worklog;

  const WorklogSummary({super.key, required this.worklog});

  @override
  State<WorklogSummary> createState() => _WorklogSummaryState();
}

class _WorklogSummaryState extends State<WorklogSummary> {
  /// Expand/collapse state keyed by category name.
  /// Defaults to expanded (true).
  final Map<String, bool> _expandedState = {};

  bool _isExpanded(String category) => _expandedState[category] ?? true;

  void _toggleExpanded(String category) {
    setState(() {
      _expandedState[category] = !(_expandedState[category] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Time Logged',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(widget.worklog.total,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            if (widget.worklog.categories.isNotEmpty) ...[
              const Divider(),
              ...widget.worklog.categories.map((cat) => _CategoryGroup(
                    category: cat,
                    expanded: _isExpanded(cat.category),
                    onToggleExpanded: () => _toggleExpanded(cat.category),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final WorklogCategorySnapshot category;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const _CategoryGroup({
    required this.category,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: onToggleExpanded,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    category.category,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  category.total,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            child: Column(
              children: category.entries
                  .map((e) => _EntryRow(entry: e))
                  .toList(),
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final WorklogTaskSnapshot entry;

  const _EntryRow({required this.entry});

  /// Returns true if this is a task-bound worklog (has a taskId).
  bool get _isTaskBound => entry.taskId.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Icon: check_box_outlined for task-bound, schedule for orphan
    final IconData icon;
    if (_isTaskBound) {
      icon = Icons.check_box_outlined;
    } else {
      // Orphan worklog — use note_outlined or schedule
      icon = Icons.note_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.title,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            entry.total,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
