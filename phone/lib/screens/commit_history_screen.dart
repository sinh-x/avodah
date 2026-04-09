import 'package:flutter/material.dart';

import '../models/repo_commits.dart';
import '../models/repo_diff.dart';
import '../services/agent_api_client.dart';
import '../utils/date_helpers.dart';
import '../widgets/diff_widgets.dart';

/// Screen showing paginated commit history for a specific branch.
///
/// Calls [AgentApiClient.getRepoCommits] on init with limit=20, offset=0.
/// Supports infinite scroll (loads next page when reaching bottom).
/// Pull-to-refresh resets to offset 0.
class CommitHistoryScreen extends StatefulWidget {
  final String repoKey;
  final String branch;
  final AgentApiClient apiClient;

  const CommitHistoryScreen({
    super.key,
    required this.repoKey,
    required this.branch,
    required this.apiClient,
  });

  @override
  State<CommitHistoryScreen> createState() => _CommitHistoryScreenState();
}

class _CommitHistoryScreenState extends State<CommitHistoryScreen> {
  List<RepoCommit> _commits = [];
  List<RepoCommit> _filteredCommits = [];
  bool _loading = true;
  String? _error;
  bool _loadingMore = false;
  int _offset = 0;
  static const int _limit = 20;
  int _total = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<String, RepoDiff?> _diffCache = {};
  final Set<String> _failedDiffs = {};

  /// Extracts ticket key from branch name (e.g., 'AVO-067' from 'feature/AVO-067-branch-commit-ui').
  /// Returns null if no ticket key can be extracted.
  String? get _ticketKey {
    final match = RegExp(r'([A-Z]+-\d+)').firstMatch(widget.branch);
    return match?.group(1);
  }

  /// Filters commits by ticket key if available.
  List<RepoCommit> _filterByTicketKey(List<RepoCommit> commits) {
    final key = _ticketKey;
    if (key == null) return commits;
    return commits.where((c) => c.message.contains(key)).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCommits();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _loadCommits() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
    });

    try {
      // Fetch more commits to ensure we have enough after local filtering
      final result = await widget.apiClient.getRepoCommits(widget.repoKey, widget.branch, limit: _limit * 3, offset: 0);

      if (mounted) {
        final filtered = _filterByTicketKey(result.commits);
        setState(() {
          _commits = result.commits;
          _filteredCommits = filtered;
          _total = filtered.length;
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

  Future<void> _loadMore() async {
    if (_loadingMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      // Fetch more commits and filter locally
      final result = await widget.apiClient.getRepoCommits(widget.repoKey, widget.branch, limit: _limit * 2, offset: _offset);

      if (mounted) {
        final newFiltered = _filterByTicketKey(result.commits);
        setState(() {
          _commits = [..._commits, ...result.commits];
          _filteredCommits = [..._filteredCommits, ...newFiltered];
          _offset += result.commits.length;
          _total = _filteredCommits.length;
          _loadingMore = false;
        });
      }
    } on AgentApiException {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadCommits();
  }

  Future<void> _loadDiff(String commitHash) async {
    if (_diffCache.containsKey(commitHash) && !_failedDiffs.contains(commitHash)) return;

    try {
      final diff = await widget.apiClient.getRepoDiff(widget.repoKey, commitHash);
      if (mounted) {
        setState(() {
          _failedDiffs.remove(commitHash);
          _diffCache[commitHash] = diff;
        });
      }
    } on AgentApiException {
      if (mounted) {
        setState(() {
          _diffCache.remove(commitHash);
          _failedDiffs.add(commitHash);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diffCache.remove(commitHash);
          _failedDiffs.add(commitHash);
        });
      }
    }
  }

  void _retryDiff(String commitHash) {
    setState(() {
      _failedDiffs.remove(commitHash);
      _diffCache.remove(commitHash);
    });
    _loadDiff(commitHash);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _filteredCommits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _filteredCommits.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.cloud_off, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Unable to load commits',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: _loadCommits,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: _filteredCommits.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredCommits.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _ExpandableCommitTile(
            commit: _filteredCommits[index],
            repoKey: widget.repoKey,
            apiClient: widget.apiClient,
            diffCache: _diffCache,
            failedDiffs: _failedDiffs,
            onExpand: () => _loadDiff(_filteredCommits[index].hash),
            onRetry: () => _retryDiff(_filteredCommits[index].hash),
          );
        },
      ),
    );
  }
}

class _ExpandableCommitTile extends StatefulWidget {
  final RepoCommit commit;
  final String repoKey;
  final AgentApiClient apiClient;
  final Map<String, RepoDiff?> diffCache;
  final Set<String> failedDiffs;
  final VoidCallback onExpand;
  final VoidCallback onRetry;

  const _ExpandableCommitTile({
    required this.commit,
    required this.repoKey,
    required this.apiClient,
    required this.diffCache,
    required this.failedDiffs,
    required this.onExpand,
    required this.onRetry,
  });

  @override
  State<_ExpandableCommitTile> createState() => _ExpandableCommitTileState();
}

class _ExpandableCommitTileState extends State<_ExpandableCommitTile> {
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
                      : DiffView(diff: cachedDiff),
          ],
        ),
      ),
    );
  }
}