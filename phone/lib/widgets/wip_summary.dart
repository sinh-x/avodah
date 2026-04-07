import 'package:flutter/material.dart';

import '../models/focus_item.dart';

/// Collapsible WIP summary widget for the GTD Focus view.
///
/// Shows total count in header, with expandable sections for per-project
/// and per-status breakdowns.
class WipSummaryWidget extends StatelessWidget {
  final WipSummary wip;

  const WipSummaryWidget({super.key, required this.wip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          Icons.analytics_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          'WIP Summary',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${wip.total} items',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        children: [
          if (wip.byProject.isNotEmpty) ...[
            _SectionHeader(title: 'By Project'),
            _CountTable(
              entries: wip.byProject.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)),
            ),
          ],
          if (wip.byStatus.isNotEmpty) ...[
            _SectionHeader(title: 'By Status'),
            _CountTable(
              entries: wip.byStatus.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CountTable extends StatelessWidget {
  final List<MapEntry<String, int>> entries;

  const _CountTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: entries.map((entry) {
          return _CountChip(label: entry.key, count: entry.value);
        }).toList(),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;

  const _CountChip({required this.label, required this.count});

  Color _chipColor(BuildContext context, int count, int total) {
    // Higher count = more attention needed — use a red-orange gradient based on proportion
    if (total == 0) return Theme.of(context).colorScheme.outline;
    final ratio = count / total;
    if (ratio > 0.3) return Colors.red;
    if (ratio > 0.15) return Colors.orange;
    if (ratio > 0.05) return Colors.amber;
    return Theme.of(context).colorScheme.outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = context.findAncestorWidgetOfExactType<WipSummaryWidget>()?.wip.total ?? count;
    final color = _chipColor(context, count, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}