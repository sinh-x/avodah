import 'package:flutter/material.dart';

import '../models/repo_commits.dart';
import '../models/repo_diff.dart';
import '../models/repo_git_info.dart';
import '../services/agent_api_client.dart';
import '../utils/date_helpers.dart';
import '../widgets/diff_widgets.dart';

/// Screen showing details of a single feature branch with embedded commit history.
///
/// Displays branch name, full commit hash, commit date, and full commit message.
/// Below the static info cards, shows a scrollable paginated commit history list.
class BranchDetailScreen extends StatefulWidget {
  final String repoKey;
  final FeatureBranch branch;
  final AgentApiClient apiClient;

  const BranchDetailScreen({
    super.key,
    required this.repoKey,
    required this.branch,
    required this.apiClient,
  });

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  List<RepoCommit> _commits = [];
  bool _loadingCommits = true;
  String? _commitsError;
  bool _loadingMore = false;
  int _offset = 0;
  static const int _limit = 20;
  int _total = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<String, RepoDiff?> _diffCache = {};

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
      _loadingCommits = true;
      _commitsError = null;
      _offset = 0;
    });

    try {
      final result = await widget.apiClient.getRepoCommits(widget.repoKey, widget.branch.name, limit: _limit, offset: 0);

      if (mounted) {
        setState(() {
          _commits = result.commits;
          _total = result.meta.total;
          _loadingCommits = false;
        });
      }
    } on AgentApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadingCommits = false;
          _commitsError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCommits = false;
          _commitsError = e.toString();
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
      final result = await widget.apiClient.getRepoCommits(widget.repoKey, widget.branch.name, limit: _limit, offset: _offset);

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

  Future<void> _loadDiff(String commitHash) async {
    if (_diffCache.containsKey(commitHash)) return;

    try {
      final diff = await widget.apiClient.getRepoDiff(widget.repoKey, commitHash);
      if (mounted) {
        setState(() {
          _diffCache[commitHash] = diff;
        });
      }
    } on AgentApiException {
      if (mounted) {
        setState(() {
          _diffCache[commitHash] = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diffCache[commitHash] = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commit = widget.branch.latestCommit;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch.name),
      ),
      body: Column(
        children: [
          // Static header section with branch info cards
          SizedBox(
            height: 340,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Branch name card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_tree,
                                color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.branch.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Commit hash card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commit Hash',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          commit.hash,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Commit date card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commit Date',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: theme.colorScheme.outline),
                            const SizedBox(width: 8),
                            Text(
                              formatDateLong(commit.date),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Commit message card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commit Message',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          commit.message,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider with "Commit History" label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider(color: theme.colorScheme.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Commit History',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.colorScheme.outline)),
              ],
            ),
          ),

          // Commit list section
          Expanded(
            child: _buildCommitList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitList() {
    if (_loadingCommits && _commits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_commitsError != null && _commits.isEmpty) {
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

    if (_commits.isEmpty) {
      return const Center(child: Text('No commits'));
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
          return _ExpandableCommitTile(
            commit: _commits[index],
            repoKey: widget.repoKey,
            apiClient: widget.apiClient,
            diffCache: _diffCache,
            onExpand: () => _loadDiff(_commits[index].hash),
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
  final VoidCallback onExpand;

  const _ExpandableCommitTile({
    required this.commit,
    required this.repoKey,
    required this.apiClient,
    required this.diffCache,
    required this.onExpand,
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
              cachedDiff == null
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
