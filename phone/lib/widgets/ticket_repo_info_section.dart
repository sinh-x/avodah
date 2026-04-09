import 'package:flutter/material.dart';

import '../models/repo_git_info.dart';
import '../models/ticket.dart';
import '../screens/branch_detail_screen.dart';
import '../screens/branch_list_screen.dart';
import '../screens/commit_diff_screen.dart';
import '../services/agent_api_client.dart';

/// A collapsible section showing repository git information.
///
/// Displays current branch, main/develop status, working directory state,
/// and feature branches. Branches related to the ticket ID are highlighted.
class TicketRepoInfoSection extends StatelessWidget {
  /// The repository git information to display.
  final RepoGitInfo? repoGitInfo;

  /// Whether the git info is currently being loaded.
  final bool isLoading;

  /// An error message if the git info could not be fetched, or null.
  final String? error;

  /// The ticket ID used to highlight related branches.
  final String ticketId;

  /// The API client for making git requests.
  final AgentApiClient apiClient;

  /// Linked branches from the PA ticket system.
  final List<LinkedBranch> linkedBranches;

  /// Linked commits from the PA ticket system.
  final List<LinkedCommit> linkedCommits;

  const TicketRepoInfoSection({
    super.key,
    this.repoGitInfo,
    this.isLoading = false,
    this.error,
    required this.ticketId,
    required this.apiClient,
    this.linkedBranches = const [],
    this.linkedCommits = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Repository info section',
      child: _SectionContent(
        repoGitInfo: repoGitInfo,
        isLoading: isLoading,
        error: error,
        ticketId: ticketId,
        apiClient: apiClient,
        linkedBranches: linkedBranches,
        linkedCommits: linkedCommits,
      ),
    );
  }
}

class _SectionContent extends StatefulWidget {
  final RepoGitInfo? repoGitInfo;
  final bool isLoading;
  final String? error;
  final String ticketId;
  final AgentApiClient apiClient;
  final List<LinkedBranch> linkedBranches;
  final List<LinkedCommit> linkedCommits;

  const _SectionContent({
    this.repoGitInfo,
    required this.isLoading,
    this.error,
    required this.ticketId,
    required this.apiClient,
    required this.linkedBranches,
    required this.linkedCommits,
  });

  @override
  State<_SectionContent> createState() => _SectionContentState();
}

class _SectionContentState extends State<_SectionContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = widget.repoGitInfo != null && widget.error == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header — tappable to expand/collapse
        Semantics(
          label: 'Repository info section. '
              '${hasData ? "on branch ${widget.repoGitInfo!.currentBranch}" : "no data"}. '
              'Tap to expand.',
          button: true,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Repo Info',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  if (widget.isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (hasData)
                    _BranchStatusBadge(
                      currentBranch: widget.repoGitInfo!.currentBranch,
                      workingDirectory: widget.repoGitInfo!.workingDirectory,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Expanded content
        if (_expanded) ...[
          const SizedBox(height: 4),
          _buildBody(context),
        ],
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: Text('Loading repository info...'),
        ),
      );
    }

    if (widget.error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                size: 16, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Failed to load repository info',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.repoGitInfo == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No repository info available.',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    return _RepoInfoBody(
      repoGitInfo: widget.repoGitInfo!,
      ticketId: widget.ticketId,
      apiClient: widget.apiClient,
      linkedBranches: widget.linkedBranches,
      linkedCommits: widget.linkedCommits,
    );
  }
}

/// Shows current branch and clean/dirty indicator as a compact badge.
class _BranchStatusBadge extends StatelessWidget {
  final String currentBranch;
  final WorkingDirectoryStatus workingDirectory;

  const _BranchStatusBadge({
    required this.currentBranch,
    required this.workingDirectory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClean = workingDirectory.clean;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            currentBranch,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          isClean ? Icons.check_circle_outline : Icons.circle,
          size: 12,
          color: isClean ? Colors.green : Colors.orange,
          semanticLabel: isClean ? 'Working directory clean' : 'Working directory dirty',
        ),
      ],
    );
  }
}

/// The expanded body showing detailed repo info.
class _RepoInfoBody extends StatelessWidget {
  final RepoGitInfo repoGitInfo;
  final String ticketId;
  final AgentApiClient apiClient;
  final List<LinkedBranch> linkedBranches;
  final List<LinkedCommit> linkedCommits;

  const _RepoInfoBody({
    required this.repoGitInfo,
    required this.ticketId,
    required this.apiClient,
    required this.linkedBranches,
    required this.linkedCommits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find ticket branch from featureBranches
    final ticketBranch = repoGitInfo.featureBranches
        .where((b) => _isRelatedBranch(b.name))
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ticket Branch - displayed prominently if found
        if (ticketBranch != null) ...[
          _TicketBranchRow(
            branch: ticketBranch,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BranchDetailScreen(
                    repoKey: repoGitInfo.repo.key,
                    branch: ticketBranch,
                    apiClient: apiClient,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ] else ...[
          // Ticket branch not found - show merged/fallback message
          _MergedBranchRow(ticketId: ticketId),
          const SizedBox(height: 8),
        ],

        // Current branch and working directory status
        _InfoRow(
          icon: Icons.call_split,
          label: 'Current',
          value: repoGitInfo.currentBranch,
          isHighlighted: _isRelatedBranch(repoGitInfo.currentBranch),
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: repoGitInfo.workingDirectory.clean
              ? Icons.check_circle_outline
              : Icons.warning_amber_outlined,
          label: 'Workdir',
          value: repoGitInfo.workingDirectory.clean
              ? 'Clean'
              : 'Dirty (${repoGitInfo.workingDirectory.uncommittedCount} changes)',
          valueColor:
              repoGitInfo.workingDirectory.clean ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 8),

        // Main/Develop status
        if (repoGitInfo.mainBranch.exists || repoGitInfo.developBranch.exists) ...[
          _BranchStatusRow(
            branchName: 'main',
            branchInfo: repoGitInfo.mainBranch,
            aheadCount: repoGitInfo.mainVsDevelop.mainAhead,
            isRelated: _isRelatedBranch('main'),
            ticketId: ticketId,
          ),
          const SizedBox(height: 4),
          _BranchStatusRow(
            branchName: 'develop',
            branchInfo: repoGitInfo.developBranch,
            aheadCount: repoGitInfo.mainVsDevelop.developAhead,
            isRelated: _isRelatedBranch('develop'),
            ticketId: ticketId,
          ),
          const SizedBox(height: 8),
        ],

        // Feature branches header
        if (repoGitInfo.featureBranches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'Feature Branches',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._buildFeatureBranches(context),
        ],

        // Linked Branches & Commits from PA ticket system
        _LinkedBranchesCommitsSection(
          repoKey: repoGitInfo.repo.key,
          linkedBranches: linkedBranches,
          linkedCommits: linkedCommits,
          apiClient: apiClient,
        ),

        // All Branches navigation
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BranchListScreen(repoKey: repoGitInfo.repo.key, apiClient: apiClient),
                ),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'View All Branches',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        ),

        // Errors, if any
        if (repoGitInfo.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ErrorsRow(errors: repoGitInfo.errors),
        ],
      ],
    );
  }

  List<Widget> _buildFeatureBranches(BuildContext context) {
    // Filter to only ticket-related branches
    final branches = repoGitInfo.featureBranches
        .where((b) => _isRelatedBranch(b.name))
        .toList();

    // Sort alphabetically
    branches.sort((a, b) => a.name.compareTo(b.name));

    return branches.map((branch) {
      return _FeatureBranchRow(
        branch: branch,
        isRelated: _isRelatedBranch(branch.name),
        ticketId: ticketId,
      );
    }).toList();
  }

  bool _isRelatedBranch(String branchName) {
    return branchName.contains(ticketId);
  }
}

/// A single info row with icon, label, and value.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isHighlighted;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isHighlighted
                    ? theme.colorScheme.primary
                    : valueColor ?? theme.colorScheme.onSurface,
                fontWeight: isHighlighted ? FontWeight.w600 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows main or develop branch with ahead/behind info.
class _BranchStatusRow extends StatelessWidget {
  final String branchName;
  final BranchInfo branchInfo;
  final int aheadCount;
  final bool isRelated;
  final String ticketId;

  const _BranchStatusRow({
    required this.branchName,
    required this.branchInfo,
    required this.aheadCount,
    required this.isRelated,
    required this.ticketId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!branchInfo.exists) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined,
                size: 14, color: theme.colorScheme.outline),
            const SizedBox(width: 6),
            Text(
              '$branchName: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              'not found',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(
            branchName == 'main'
                ? Icons.call_split
                : Icons.developer_mode,
            size: 14,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Text(
            '$branchName: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isRelated
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              branchName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isRelated
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isRelated ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (aheadCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '+$aheadCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single feature branch row with related branch highlighting.
class _FeatureBranchRow extends StatelessWidget {
  final FeatureBranch branch;
  final bool isRelated;
  final String ticketId;

  const _FeatureBranchRow({
    required this.branch,
    required this.isRelated,
    required this.ticketId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Feature branch ${branch.name}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.call_split,
              size: 14,
              color: isRelated
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isRelated
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: isRelated
                      ? Border.all(
                          color: theme.colorScheme.primary,
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  branch.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isRelated
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isRelated ? FontWeight.w600 : null,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isRelated) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: 12,
                color: theme.colorScheme.primary,
                semanticLabel: 'Related to $ticketId',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows any errors that occurred during git info retrieval.
class _ErrorsRow extends StatelessWidget {
  final Map<String, String> errors;

  const _ErrorsRow({required this.errors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber,
              size: 14, color: theme.colorScheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              errors.values.join('; '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the ticket branch prominently as the primary branch indicator.
/// Tapping navigates to BranchDetailScreen.
class _TicketBranchRow extends StatelessWidget {
  final FeatureBranch branch;
  final VoidCallback onTap;

  const _TicketBranchRow({
    required this.branch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Ticket branch ${branch.name}. Tap to view details.',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ticket Branch',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      branch.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a message when the ticket branch has been merged/deleted.
class _MergedBranchRow extends StatelessWidget {
  final String ticketId;

  const _MergedBranchRow({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.merge,
            size: 18,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Branch Merged',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$ticketId branch not available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Commits with $ticketId key are in develop branch',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows linked branches and commits from the PA ticket system.
/// Filters by repo and only shows when the filtered list is non-empty.
class _LinkedBranchesCommitsSection extends StatelessWidget {
  final String repoKey;
  final List<LinkedBranch> linkedBranches;
  final List<LinkedCommit> linkedCommits;
  final AgentApiClient apiClient;

  const _LinkedBranchesCommitsSection({
    required this.repoKey,
    required this.linkedBranches,
    required this.linkedCommits,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    final filteredBranches = linkedBranches
        .where((lb) => lb.repo == repoKey)
        .toList();
    final filteredCommits = linkedCommits
        .where((lc) => lc.repo == repoKey)
        .toList();

    if (filteredBranches.isEmpty && filteredCommits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Linked Branches & Commits',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...filteredBranches.map((lb) => _LinkedBranchRow(
              linkedBranch: lb,
              apiClient: apiClient,
            )),
        ...filteredCommits.map((lc) => _LinkedCommitRow(
              linkedCommit: lc,
              apiClient: apiClient,
            )),
      ],
    );
  }
}

/// A single linked branch row. Tapping navigates to BranchDetailScreen.
class _LinkedBranchRow extends StatelessWidget {
  final LinkedBranch linkedBranch;
  final AgentApiClient apiClient;

  const _LinkedBranchRow({
    required this.linkedBranch,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Linked branch ${linkedBranch.branch}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BranchDetailScreen(
                  repoKey: linkedBranch.repo,
                  branch: FeatureBranch(
                    name: linkedBranch.branch,
                    latestCommit: BranchCommit(
                      hash: linkedBranch.sha,
                      hashShort: null,
                      message: '',
                      date: '',
                    ),
                  ),
                  apiClient: apiClient,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.call_split,
                  size: 14,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        linkedBranch.branch,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (linkedBranch.linkedBy != null)
                        Text(
                          'linked by ${linkedBranch.linkedBy}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single linked commit row. Tapping navigates to CommitDiffScreen.
class _LinkedCommitRow extends StatelessWidget {
  final LinkedCommit linkedCommit;
  final AgentApiClient apiClient;

  const _LinkedCommitRow({
    required this.linkedCommit,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortSha = linkedCommit.sha.length > 7
        ? linkedCommit.sha.substring(0, 7)
        : linkedCommit.sha;

    return Semantics(
      label: 'Linked commit $shortSha',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommitDiffScreen(
                  apiClient: apiClient,
                  repoKey: linkedCommit.repo,
                  commitSha: linkedCommit.sha,
                  commitMessage: linkedCommit.message,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.commit,
                  size: 14,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              shortSha,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              linkedCommit.message,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'by ${linkedCommit.author}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

