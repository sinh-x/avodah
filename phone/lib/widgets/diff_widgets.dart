import 'package:flutter/material.dart';

import '../models/repo_diff.dart';
import '../utils/word_diff.dart';
import 'diff_stat_bar.dart';

// ---------------------------------------------------------------------------
// Helper functions (extracted from commit_diff_screen.dart)
// ---------------------------------------------------------------------------

/// Returns the color for a given change type.
Color changeTypeColor(BuildContext context, String changeType) {
  switch (changeType) {
    case 'added':
      return Colors.green;
    case 'deleted':
      return Colors.red;
    case 'renamed':
      return Colors.orange;
    case 'modified':
      return Colors.blue;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}

/// Returns the icon for a given change type.
IconData changeIcon(String changeType) {
  switch (changeType) {
    case 'added':
      return Icons.add_circle_outline;
    case 'deleted':
      return Icons.remove_circle_outline;
    case 'renamed':
      return Icons.drive_file_rename_outline;
    case 'modified':
      return Icons.edit;
    default:
      return Icons.insert_drive_file;
  }
}

// ---------------------------------------------------------------------------
// DiffView — main diff summary + file list (lines 147-204)
// ---------------------------------------------------------------------------

class DiffView extends StatelessWidget {
  final RepoDiff diff;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const DiffView({
    super.key,
    required this.diff,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final meta = diff.meta;
    final entries = diff.diffEntries;
    final theme = Theme.of(context);
    final maxChanges = maxChangesInDiff(entries);

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Diff summary header
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.commit,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${meta.filesChanged} file${meta.filesChanged == 1 ? '' : 's'} changed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '+${meta.insertions}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '-${meta.deletions}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Diff entries
        ...entries.map((entry) => DiffEntryTile(entry: entry, maxChanges: maxChanges)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DiffEntryTile — file-level ExpansionTile with change icon/badge (lines 206-295)
// ---------------------------------------------------------------------------

class DiffEntryTile extends StatelessWidget {
  final DiffEntry entry;
  final int? maxChanges;

  const DiffEntryTile({super.key, required this.entry, this.maxChanges});

  String get _displayPath {
    if (entry.changeType == 'renamed') {
      return '${entry.oldPath} → ${entry.newPath}';
    }
    return entry.newPath.isNotEmpty ? entry.newPath : entry.oldPath;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: Icon(
          changeIcon(entry.changeType),
          size: 18,
          color: changeTypeColor(context, entry.changeType),
        ),
        title: Text(
          _displayPath,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: changeTypeColor(context, entry.changeType).withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.changeType,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: changeTypeColor(context, entry.changeType),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!entry.binary)
              DiffStatBar(
                insertions: calcFileStats(entry).insertions,
                deletions: calcFileStats(entry).deletions,
                maxChanges: maxChanges,
              ),
          ],
        ),
        children: [
          if (entry.binary)
            const BinaryFileIndicator()
          else
            ...entry.hunks.map((hunk) => DiffHunkView(hunk: hunk)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BinaryFileIndicator — binary file message (lines 297-323)
// ---------------------------------------------------------------------------

class BinaryFileIndicator extends StatelessWidget {
  const BinaryFileIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.image,
            size: 18,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            'Binary file',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DiffHunkView — hunk header + diff lines (lines 325-369)
// ---------------------------------------------------------------------------

class DiffHunkView extends StatelessWidget {
  final DiffHunk hunk;

  const DiffHunkView({super.key, required this.hunk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate line number offsets
    int oldLine = hunk.oldStart;
    int newLine = hunk.newStart;

    // Precompute word diffs for paired del/add sequences
    final lineTypes = hunk.lines.map((l) => (type: l.type, content: l.content)).toList();
    final wordDiffs = computeHunkWordDiffs(lineTypes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hunk header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Text(
            '@@ -${hunk.oldStart},${hunk.oldLines} +${hunk.newStart},${hunk.newLines} @@',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Diff lines
        ...List.generate(hunk.lines.length, (idx) {
          final line = hunk.lines[idx];
          final oldLineNum = line.type == 'del' ? oldLine++ : oldLine;
          final newLineNum = line.type == 'add' ? newLine++ : newLine;
          final wordDiff = wordDiffs[idx];

          return DiffLineView(
            line: line,
            oldLineNum: oldLineNum,
            newLineNum: newLineNum,
            wordDiff: wordDiff,
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DiffLineView — single diff line with colors and line numbers (lines 371-479)
// ---------------------------------------------------------------------------

class DiffLineView extends StatelessWidget {
  final DiffLine line;
  final int oldLineNum;
  final int newLineNum;
  final WordDiffResult? wordDiff;

  const DiffLineView({
    super.key,
    required this.line,
    required this.oldLineNum,
    required this.newLineNum,
    this.wordDiff,
  });

  Color _backgroundColor() {
    switch (line.type) {
      case 'add':
        return Colors.green.withAlpha(30);
      case 'del':
        return Colors.red.withAlpha(30);
      default:
        return Colors.transparent;
    }
  }

  String _prefix() {
    switch (line.type) {
      case 'add':
        return '+';
      case 'del':
        return '-';
      default:
        return ' ';
    }
  }

  /// Returns the word-level background color for a segment.
  Color _wordSegmentColor(String segmentType) {
    switch (segmentType) {
      case 'added':
        // Stronger green for word-level highlighting
        return Colors.green.withAlpha(80);
      case 'deleted':
        // Stronger red for word-level highlighting
        return Colors.red.withAlpha(80);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Old line number
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              line.type == 'add' ? '' : '$oldLineNum',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // New line number
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              line.type == 'del' ? '' : '$newLineNum',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // Change prefix
          Container(
            width: 20,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              _prefix(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: line.type == 'add'
                    ? Colors.green
                    : line.type == 'del'
                        ? Colors.red
                        : theme.colorScheme.outline,
              ),
            ),
          ),

          // Content (with word-level highlighting if available)
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    // If we have word diff segments and the line is add/del, render with highlighting
    if (wordDiff != null &&
        !wordDiff!.skipped &&
        wordDiff!.segments.isNotEmpty &&
        (line.type == 'add' || line.type == 'del')) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Wrap(
          children: wordDiff!.segments.map((segment) {
            final bgColor = _wordSegmentColor(segment.type);
            final isHighlighted = segment.type != 'unchanged';

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: isHighlighted ? BorderRadius.circular(2) : null,
              ),
              padding: isHighlighted ? const EdgeInsets.symmetric(horizontal: 1) : null,
              child: Text(
                segment.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // Fallback: render plain content
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        line.content,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
