import 'package:flutter/material.dart';

import '../models/repo_diff.dart';
import '../services/agent_api_client.dart';

/// Screen showing the full file-level diff for a single commit.
///
/// Calls [AgentApiClient.getRepoDiff] on init with repoKey and commitSha.
/// Shows loading spinner while fetching, error state with retry on failure,
/// and a color-coded diff view on success.
class CommitDiffScreen extends StatefulWidget {
  final String repoKey;
  final String commitSha;
  final String? commitMessage;

  const CommitDiffScreen({
    super.key,
    required this.repoKey,
    required this.commitSha,
    this.commitMessage,
  });

  @override
  State<CommitDiffScreen> createState() => _CommitDiffScreenState();
}

class _CommitDiffScreenState extends State<CommitDiffScreen> {
  RepoDiff? _diff;
  bool _loading = true;
  String? _error;

  String get _shortSha => widget.commitSha.length > 7
      ? widget.commitSha.substring(0, 7)
      : widget.commitSha;

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  Future<void> _loadDiff() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final diff = await AgentApiClient.fromWsUrl(
        'ws://localhost:9847',
      ).getRepoDiff(widget.repoKey, widget.commitSha);

      if (mounted) {
        setState(() {
          _diff = diff;
          _loading = false;
        });
      }
    } on AgentApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.commitMessage ?? _shortSha),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(
        error: _error!,
        onRetry: _loadDiff,
      );
    }

    return _DiffView(diff: _diff!);
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load diff',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffView extends StatelessWidget {
  final RepoDiff diff;

  const _DiffView({required this.diff});

  @override
  Widget build(BuildContext context) {
    final meta = diff.meta;
    final entries = diff.diffEntries;
    final theme = Theme.of(context);

    return ListView(
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
        ...entries.map((entry) => _DiffEntryTile(entry: entry)),
      ],
    );
  }
}

class _DiffEntryTile extends StatelessWidget {
  final DiffEntry entry;

  const _DiffEntryTile({required this.entry});

  String get _displayPath {
    if (entry.changeType == 'renamed') {
      return '${entry.oldPath} → ${entry.newPath}';
    }
    return entry.newPath.isNotEmpty ? entry.newPath : entry.oldPath;
  }

  Color _changeTypeColor(BuildContext context) {
    switch (entry.changeType) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: Icon(
          _changeIcon(),
          size: 18,
          color: _changeTypeColor(context),
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
                color: _changeTypeColor(context).withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.changeType,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _changeTypeColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          if (entry.binary)
            _BinaryFileIndicator()
          else
            ...entry.hunks.map((hunk) => _DiffHunkView(hunk: hunk)),
        ],
      ),
    );
  }

  IconData _changeIcon() {
    switch (entry.changeType) {
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
}

class _BinaryFileIndicator extends StatelessWidget {
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

class _DiffHunkView extends StatelessWidget {
  final DiffHunk hunk;

  const _DiffHunkView({required this.hunk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate line number offsets
    int oldLine = hunk.oldStart;
    int newLine = hunk.newStart;

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
        ...hunk.lines.map((line) {
          final oldLineNum = line.type == 'del' ? oldLine++ : oldLine;
          final newLineNum = line.type == 'add' ? newLine++ : newLine;

          return _DiffLineView(
            line: line,
            oldLineNum: oldLineNum,
            newLineNum: newLineNum,
          );
        }),
      ],
    );
  }
}

class _DiffLineView extends StatelessWidget {
  final DiffLine line;
  final int oldLineNum;
  final int newLineNum;

  const _DiffLineView({
    required this.line,
    required this.oldLineNum,
    required this.newLineNum,
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

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                line.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
