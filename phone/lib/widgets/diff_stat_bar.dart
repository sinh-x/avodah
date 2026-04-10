import 'package:flutter/material.dart';

import '../models/repo_diff.dart';

/// A reusable diff stat bar widget that shows per-file change statistics.
///
/// Displays a GitHub-style colored bar (green for insertions, red for deletions)
/// with `+N -M` count, proportional to the total changes relative to [maxChanges].
class DiffStatBar extends StatelessWidget {
  /// Number of inserted lines for this file.
  final int insertions;

  /// Number of deleted lines for this file.
  final int deletions;

  /// The maximum number of changes (insertions + deletions) across all files
  /// in the diff. Used to calculate proportional bar width.
  /// If null, uses this file's total as the denominator (showing 100% bar).
  final int? maxChanges;

  const DiffStatBar({
    super.key,
    required this.insertions,
    required this.deletions,
    this.maxChanges,
  });

  /// Total changes for this file.
  int get _total => insertions + deletions;

  /// The denominator for calculating proportional width.
  int get _denominator => maxChanges ?? _total;

  @override
  Widget build(BuildContext context) {
    // Skip rendering bar for binary files or zero changes
    if (_total == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // +N -M count
        Text(
          '+$insertions -$deletions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        // Colored stat bar
        _StatBar(
          insertions: insertions,
          deletions: deletions,
          total: _total,
          denominator: _denominator,
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final int insertions;
  final int deletions;
  final int total;
  final int denominator;

  const _StatBar({
    required this.insertions,
    required this.deletions,
    required this.total,
    required this.denominator,
  });

  static const double _maxBarWidth = 80.0;
  static const double _minSegmentWidth = 1.0;
  static const double _barHeight = 8.0;

  @override
  Widget build(BuildContext context) {
    if (denominator == 0) return const SizedBox.shrink();

    final ratio = total / denominator;
    final barWidth = (_maxBarWidth * ratio).clamp(_minSegmentWidth, _maxBarWidth);

    return Container(
      width: barWidth,
      height: _barHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.grey[300],
      ),
      child: Row(
        children: [
          // Green portion for insertions
          if (insertions > 0)
            Flexible(
              flex: insertions,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                    left: const Radius.circular(2),
                    right: deletions == 0 ? const Radius.circular(2) : Radius.zero,
                  ),
                  color: Colors.green,
                ),
              ),
            ),
          // Red portion for deletions
          if (deletions > 0)
            Flexible(
              flex: deletions,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                    left: insertions == 0 ? Radius.zero : Radius.zero,
                    right: const Radius.circular(2),
                  ),
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Calculates per-file insertion/deletion counts from hunk data.
({int insertions, int deletions}) calcFileStats(DiffEntry entry) {
  int insertions = 0;
  int deletions = 0;
  for (final hunk in entry.hunks) {
    for (final line in hunk.lines) {
      if (line.type == 'add') {
        insertions++;
      } else if (line.type == 'del') {
        deletions++;
      }
    }
  }
  return (insertions: insertions, deletions: deletions);
}

/// Finds the maximum total changes across all diff entries.
int maxChangesInDiff(List<DiffEntry> entries) {
  int maxTotal = 0;
  for (final entry in entries) {
    final stats = calcFileStats(entry);
    final total = stats.insertions + stats.deletions;
    if (total > maxTotal) maxTotal = total;
  }
  return maxTotal;
}
