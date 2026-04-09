import 'package:flutter/material.dart';

import '../models/repo_commits.dart';
import '../services/agent_api_client.dart';
import '../utils/date_helpers.dart';
import 'commit_diff_screen.dart';

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
  bool _loading = true;
  String? _error;
  bool _loadingMore = false;
  int _offset = 0;
  static const int _limit = 20;
  int _total = 0;
  final ScrollController _scrollController = ScrollController();

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
      final result = await widget.apiClient.getRepoCommits(widget.repoKey, widget.branch, limit: _limit, offset: 0);

      if (mounted) {
        setState(() {
          _commits = result.commits;
          _total = result.meta.total;
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
    if (_offset + _limit >= _total) return;

    setState(() {
      _loadingMore = true;
      _offset += _limit;
    });

    try {
      final result = await widget.apiClient.getRepoCommits(widget.repoKey, widget.branch, limit: _limit, offset: _offset);

      if (mounted) {
        setState(() {
          _commits = [..._commits, ...result.commits];
          _loadingMore = false;
        });
      }
    } on AgentApiException {
      if (mounted) {
        setState(() {
          _offset -= _limit;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offset -= _limit;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadCommits();
  }

  void _navigateToCommitDiff(RepoCommit commit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommitDiffScreen(
          apiClient: widget.apiClient,
          repoKey: widget.repoKey,
          commitSha: commit.hash,
          commitMessage: commit.message,
        ),
      ),
    );
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
    if (_loading && _commits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _commits.isEmpty) {
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
        itemCount: _commits.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _commits.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _CommitTile(
            commit: _commits[index],
            repoKey: widget.repoKey,
            onTap: () => _navigateToCommitDiff(_commits[index]),
          );
        },
      ),
    );
  }
}

class _CommitTile extends StatelessWidget {
  final RepoCommit commit;
  final String repoKey;
  final VoidCallback onTap;

  const _CommitTile({
    required this.commit,
    required this.repoKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = commit.diffSummary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: InkWell(
          onTap: onTap,
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
                      commit.hashShort,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatDateShort(commit.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Middle: commit message (first line)
                Text(
                  commit.message,
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
                        commit.authorName,
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
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}