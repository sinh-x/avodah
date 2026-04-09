import 'package:flutter/material.dart';

import '../models/deployment.dart';
import '../models/repo_git_info.dart';
import '../services/agent_api_client.dart';
import '../utils/date_helpers.dart';
import '../utils/deploy_helpers.dart';
import 'activity_timeline_screen.dart';
import 'branch_detail_screen.dart';
import 'branch_list_screen.dart';

/// Repository detail screen showing git info and deployment history.
///
/// Fires both git-info and deployments API calls in parallel on init.
/// Supports pull-to-refresh, error state with retry, and 404 handling.
class RepoDetailScreen extends StatefulWidget {
  final String repoKey;
  final AgentApiClient apiClient;

  const RepoDetailScreen({
    super.key,
    required this.repoKey,
    required this.apiClient,
  });

  @override
  State<RepoDetailScreen> createState() => _RepoDetailScreenState();
}

class _RepoDetailScreenState extends State<RepoDetailScreen> {
  RepoGitInfo? _gitInfo;
  List<Deployment> _deployments = [];
  bool _loading = true;
  String? _error;
  bool _is404 = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
      _is404 = false;
    });

    try {
      final results = await Future.wait([
        widget.apiClient.getRepoGitInfo(widget.repoKey),
        widget.apiClient.getRepoDeployments(widget.repoKey),
      ]);

      if (mounted) {
        setState(() {
          _gitInfo = results[0] as RepoGitInfo;
          _deployments = results[1] as List<Deployment>;
          _loading = false;
        });
      }
    } on AgentApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (e.statusCode == 404) {
            _is404 = true;
            _error = null;
          } else {
            _error = e.message;
          }
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

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _gitInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Repository')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_is404) {
      return Scaffold(
        appBar: AppBar(title: const Text('Repository')),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            children: [
              const SizedBox(height: 120),
              Icon(Icons.folder_off, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No repository found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Project "${widget.repoKey}" has no associated git repository.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _gitInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Repository')),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            children: [
              const SizedBox(height: 120),
              Icon(Icons.cloud_off, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Unable to connect',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gitInfo = _gitInfo!;
    final runningDeployments = _deployments.where((d) => d.isRunning).toList();
    final recentDeployments = _deployments.where((d) => !d.isRunning).take(20).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(gitInfo.repo.key),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Git Info Section
            _GitInfoSection(gitInfo: gitInfo),

            // Feature Branches Section
            _FeatureBranchesSection(
              repoKey: widget.repoKey,
              branches: gitInfo.featureBranches,
              onBranchTap: (branch) => _navigateToBranch(context, branch),
            ),

            // Deployments Section
            _DeploymentsSection(
              runningDeployments: runningDeployments,
              recentDeployments: recentDeployments,
              onDeploymentTap: (deployment) =>
                  _navigateToTimeline(context, deployment),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBranch(BuildContext context, FeatureBranch branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BranchDetailScreen(
          repoKey: widget.repoKey,
          branch: branch,
        ),
      ),
    );
  }

  void _navigateToTimeline(BuildContext context, Deployment deployment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityTimelineScreen(
          deployment: deployment,
          client: widget.apiClient,
        ),
      ),
    );
  }
}

/// Git info section with current branch, main/develop comparison, and working directory status.
class _GitInfoSection extends StatelessWidget {
  final RepoGitInfo gitInfo;

  const _GitInfoSection({required this.gitInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Git Info',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Current branch chip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(Icons.account_tree,
                    size: 16, color: theme.colorScheme.primary),
                label: Text(gitInfo.currentBranch),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Main vs Develop comparison card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BranchStatusRow(
                    label: gitInfo.mainBranch.name.isNotEmpty
                        ? gitInfo.mainBranch.name
                        : 'main',
                    exists: gitInfo.mainBranch.exists,
                    commit: gitInfo.mainBranch.latestCommit,
                    color: theme.colorScheme.primary,
                  ),
                  const Divider(height: 16),
                  _BranchStatusRow(
                    label: gitInfo.developBranch.name.isNotEmpty
                        ? gitInfo.developBranch.name
                        : 'develop',
                    exists: gitInfo.developBranch.exists,
                    commit: gitInfo.developBranch.latestCommit,
                    color: theme.colorScheme.secondary,
                  ),
                  const Divider(height: 16),
                  _AheadBehindIndicator(
                    mainVsDevelop: gitInfo.mainVsDevelop,
                    mainBranchName: gitInfo.mainBranch.name.isNotEmpty
                        ? gitInfo.mainBranch.name
                        : 'main',
                    developBranchName: gitInfo.developBranch.name.isNotEmpty
                        ? gitInfo.developBranch.name
                        : 'develop',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Working directory status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    gitInfo.workingDirectory.clean
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    color: gitInfo.workingDirectory.clean
                        ? Colors.green
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gitInfo.workingDirectory.clean
                        ? 'Working directory clean'
                        : '${gitInfo.workingDirectory.uncommittedCount} uncommitted change${gitInfo.workingDirectory.uncommittedCount == 1 ? '' : 's'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BranchStatusRow extends StatelessWidget {
  final String label;
  final bool exists;
  final BranchCommit? commit;
  final Color color;

  const _BranchStatusRow({
    required this.label,
    required this.exists,
    required this.commit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        if (!exists)
          Text(
            'not found',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else if (commit != null) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit!.hashShort ?? commit!.hash,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  commit!.message,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AheadBehindIndicator extends StatelessWidget {
  final MainVsDevelop mainVsDevelop;
  final String mainBranchName;
  final String developBranchName;

  const _AheadBehindIndicator({
    required this.mainVsDevelop,
    required this.mainBranchName,
    required this.developBranchName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!mainVsDevelop.diverged &&
        mainVsDevelop.mainAhead == 0 &&
        mainVsDevelop.developAhead == 0) {
      return Row(
        children: [
          Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Branches are in sync',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _AheadBehindBadge(
          label: mainBranchName,
          count: mainVsDevelop.mainAhead,
          color: theme.colorScheme.primary,
          tooltip: 'commits ahead of $developBranchName',
        ),
        const SizedBox(width: 8),
        _AheadBehindBadge(
          label: developBranchName,
          count: mainVsDevelop.developAhead,
          color: theme.colorScheme.secondary,
          tooltip: 'commits ahead of $mainBranchName',
        ),
      ],
    );
  }
}

class _AheadBehindBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String tooltip;

  const _AheadBehindBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count > 0 ? '+$count' : '0',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feature branches section with list of branch tiles.
class _FeatureBranchesSection extends StatelessWidget {
  final String repoKey;
  final List<FeatureBranch> branches;
  final void Function(FeatureBranch) onBranchTap;

  const _FeatureBranchesSection({
    required this.repoKey,
    required this.branches,
    required this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Text(
                'Feature Branches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${branches.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (branches.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  'No active feature branches',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            itemBuilder: (context, index) {
              final branch = branches[index];
              final commit = branch.latestCommit;
              return ListTile(
                onTap: () => onBranchTap(branch),
                leading: CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.account_tree,
                      size: 18, color: theme.colorScheme.onSecondaryContainer),
                ),
                title: Text(
                  branch.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${commit.hashShort ?? commit.hash} · ${formatDateShort(commit.date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.outline,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),

        // View All Branches button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BranchListScreen(repoKey: repoKey),
                ),
              );
            },
            icon: const Icon(Icons.account_tree, size: 18),
            label: const Text('View All Branches'),
          ),
        ),
      ],
    );
  }
}

/// Deployments section with running and recent subsections.
class _DeploymentsSection extends StatelessWidget {
  final List<Deployment> runningDeployments;
  final List<Deployment> recentDeployments;
  final void Function(Deployment) onDeploymentTap;

  const _DeploymentsSection({
    required this.runningDeployments,
    required this.recentDeployments,
    required this.onDeploymentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = runningDeployments.isEmpty && recentDeployments.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Deployments',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  'No deployments found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Running deployments
          if (runningDeployments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Running',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            ...runningDeployments.map((d) => _DeploymentTile(
                  deployment: d,
                  onTap: () => onDeploymentTap(d),
                )),
          ],

          // Recent deployments
          if (recentDeployments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Recent',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            ...recentDeployments.map((d) => _DeploymentTile(
                  deployment: d,
                  onTap: () => onDeploymentTap(d),
                )),
          ],
        ],
      ],
    );
  }
}

class _DeploymentTile extends StatelessWidget {
  final Deployment deployment;
  final VoidCallback onTap;

  const _DeploymentTile({required this.deployment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(context, deployment.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(statusIcon(deployment.status), color: color, size: 20),
        ),
        title: Text(
          deployment.deploymentId,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${deployment.team} · ${deployment.status} · ${formatRelativeTime(deployment.startedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deployment.isRunning)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
