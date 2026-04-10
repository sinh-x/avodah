import 'package:flutter/material.dart';

import '../models/repo_commits.dart';
import '../models/repo_diff.dart';
import '../utils/date_helpers.dart';
import 'diff_widgets.dart';

/// An expandable commit tile widget that shows commit info and lazy-loads diffs.
///
/// Used by [BranchDetailScreen] and [CommitHistoryScreen] to display commit
/// entries with expandable diff views.
class ExpandableCommitTile extends StatefulWidget {
  final RepoCommit commit;
  final String repoKey;
  final Map<String, RepoDiff?> diffCache;
  final Set<String> failedDiffs;
  final VoidCallback onExpand;
  final VoidCallback onRetry;

  /// When true, the diff view uses shrinkWrap and NeverScrollableScrollPhysics.
  /// Defaults to false.
  final bool shrinkWrapDiff;

  const ExpandableCommitTile({
    super.key,
    required this.commit,
    required this.repoKey,
    required this.diffCache,
    required this.failedDiffs,
    required this.onExpand,
    required this.onRetry,
    this.shrinkWrapDiff = false,
  });

  @override
  State<ExpandableCommitTile> createState() => _ExpandableCommitTileState();
}

class _ExpandableCommitTileState extends State<ExpandableCommitTile> {
  bool _isExpanded = false;

  void _handleTap() {
    final wasExpanded = _isExpanded;
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (!wasExpanded) {
      widget.onExpand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = widget.commit.diffSummary;
    final cachedDiff = widget.diffCache[widget.commit.hash];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collapsed header (always visible, tappable)
            InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: hash_short + date
                    Row(
                      children: [
                        Text(
                          widget.commit.hashShort,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatDateShort(widget.commit.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Middle: commit message (first line)
                    Text(
                      widget.commit.message,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Bottom row: author name + diff summary
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.commit.authorName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '+${diff.insertions} -${diff.deletions} in ${diff.filesChanged} file${diff.filesChanged == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expanded: diff view (lazy-loaded)
            if (_isExpanded)
              widget.failedDiffs.contains(widget.commit.hash)
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: theme.colorScheme.error, size: 32),
                            const SizedBox(height: 8),
                            Text('Failed to load diff',
                                style: TextStyle(color: theme.colorScheme.error)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: widget.onRetry,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : cachedDiff == null
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DiffView(
                          diff: cachedDiff,
                          shrinkWrap: widget.shrinkWrapDiff,
                          physics: widget.shrinkWrapDiff
                              ? const NeverScrollableScrollPhysics()
                              : null,
                        ),
          ],
        ),
      ),
    );
  }
}
