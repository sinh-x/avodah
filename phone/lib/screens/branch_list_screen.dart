import 'package:flutter/material.dart';

import '../models/repo_branches.dart';
import '../models/repo_git_info.dart';
import '../services/agent_api_client.dart';
import '../utils/date_helpers.dart';
import 'branch_detail_screen.dart';

/// Screen showing all local branches for a repository.
///
/// Calls [AgentApiClient.getRepoBranches] on init to fetch the branch list.
/// Supports pull-to-refresh. Tapping a branch navigates to [BranchDetailScreen].
class BranchListScreen extends StatefulWidget {
  final String repoKey;
  final AgentApiClient apiClient;

  const BranchListScreen({super.key, required this.repoKey, required this.apiClient});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  RepoBranches? _branches;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final branches = await widget.apiClient.getRepoBranches(widget.repoKey);

      if (mounted) {
        setState(() {
          _branches = branches;
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

  Future<void> _onRefresh() async {
    await _loadBranches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repoKey),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _branches == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _branches == null) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.cloud_off, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Unable to load branches',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: _loadBranches,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    final branches = _branches!.branches;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: branches.length,
        itemBuilder: (context, index) {
          final branch = branches[index];
          return _BranchTile(
            branch: branch,
            onTap: () => _navigateToBranchDetail(branch),
          );
        },
      ),
    );
  }

  void _navigateToBranchDetail(Branch branch) {
    // Convert Branch to FeatureBranch for BranchDetailScreen
    final featureBranch = FeatureBranch(
      name: branch.name,
      latestCommit: BranchCommit(
        hash: branch.latestCommit.hashShort, // Use hashShort as fallback for hash
        hashShort: branch.latestCommit.hashShort,
        message: branch.latestCommit.message,
        date: branch.latestCommit.date,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BranchDetailScreen(
          repoKey: widget.repoKey,
          branch: featureBranch,
          apiClient: widget.apiClient,
        ),
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final Branch branch;
  final VoidCallback onTap;

  const _BranchTile({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commit = branch.latestCommit;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: branch.isCurrent
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.account_tree,
          size: 18,
          color: branch.isCurrent
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              branch.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: branch.isCurrent ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (branch.isCurrent) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'current',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${commit.hashShort} · ${commit.message} · ${formatDateShort(commit.date)} · ${commit.author}',
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.outline,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}