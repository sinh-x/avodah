import 'package:flutter/material.dart';

import '../models/deployment.dart';
import '../services/agent_api_client.dart';
import '../services/deployment_provider.dart';
import '../utils/deploy_helpers.dart';
import 'activity_timeline_screen.dart';

/// Shows deployment status with filtering by team and status.
///
/// Supports pull-to-refresh, filter chips, and tap-to-navigate to the
/// activity timeline for each deployment.
class DeploymentScreen extends StatefulWidget {
  final DeploymentProvider deploymentProvider;
  final AgentApiClient apiClient;

  const DeploymentScreen({
    super.key,
    required this.deploymentProvider,
    required this.apiClient,
  });

  @override
  State<DeploymentScreen> createState() => _DeploymentScreenState();
}

class _DeploymentScreenState extends State<DeploymentScreen> {
  @override
  void initState() {
    super.initState();
    widget.deploymentProvider.addListener(_onProviderUpdate);
    // Fetch on first load if empty.
    if (widget.deploymentProvider.allDeployments.isEmpty) {
      widget.deploymentProvider.refresh();
    }
  }

  @override
  void dispose() {
    widget.deploymentProvider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.deploymentProvider;
    final theme = Theme.of(context);

    if (provider.error != null && provider.allDeployments.isEmpty) {
      return _buildError(theme, provider);
    }

    if (provider.loading && provider.allDeployments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Column(
        children: [
          if (provider.error != null) _buildErrorBanner(theme, provider.error!),
          _FilterBar(provider: provider),
          Expanded(
            child: provider.deployments.isEmpty
                ? _buildEmpty(theme, provider)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: provider.deployments.length,
                    itemBuilder: (context, index) {
                      return _DeploymentTile(
                        deployment: provider.deployments[index],
                        onTap: () => _navigateToTimeline(
                            context, provider.deployments[index]),
                      );
                    },
                  ),
          ),
        ],
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

  Widget _buildEmpty(ThemeData theme, DeploymentProvider provider) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.rocket_launch_outlined,
            size: 64, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No deployments found',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Pull to refresh',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme, DeploymentProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Unable to connect',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Check server address in settings',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.warning_amber,
              size: 16, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline \u2014 showing cached data',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chips row for team and status.
class _FilterBar extends StatelessWidget {
  final DeploymentProvider provider;

  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final teams = provider.availableTeams;
    final statuses = provider.availableStatuses;

    if (teams.isEmpty && statuses.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // Team filters
          for (final team in teams)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(team),
                selected: provider.filterTeam == team,
                onSelected: (selected) => provider.setFilterTeam(
                  selected ? team : null,
                ),
              ),
            ),
          // Divider if both groups present
          if (teams.isNotEmpty && statuses.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: VerticalDivider(width: 1),
            ),
          // Status filters
          for (final status in statuses)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status),
                selected: provider.filterStatus == status,
                avatar: Icon(
                  statusIcon(status),
                  size: 14,
                  color: statusColor(context,status),
                ),
                onSelected: (selected) => provider.setFilterStatus(
                  selected ? status : null,
                ),
              ),
            ),
        ],
      ),
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
    final color = statusColor(context,deployment.status);
    final isCrashed = deployment.isFailed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // Visual emphasis for failed/crashed: red border
      shape: isCrashed
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                  width: 1.5),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child:
                  Icon(statusIcon(deployment.status), color: color, size: 20),
            ),
            title: Text(
              deployment.deploymentId,
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace', fontWeight: FontWeight.w600),
            ),
            subtitle: _buildSubtitle(theme, color),
            trailing: const Icon(Icons.chevron_right),
          ),
          // Model badges if available
          if (deployment.models.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: deployment.models.entries
                      .map((e) => _CompactModelBadge(
                          agent: e.key, model: e.value, theme: theme))
                      .toList(),
                ),
              ),
            ),
          // Running progress indicator
          if (deployment.isRunning)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme, Color statusColor) {
    final parts = <InlineSpan>[
      if (deployment.ticketId != null)
        TextSpan(
          text: '${deployment.ticketId} \u00b7 ',
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      TextSpan(
        text: deployment.team,
        style: theme.textTheme.bodySmall,
      ),
      TextSpan(
        text: ' \u00b7 ',
        style: theme.textTheme.bodySmall,
      ),
      TextSpan(
        text: deployment.status,
        style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
      ),
    ];

    if (deployment.elapsedDuration.isNotEmpty) {
      parts.add(TextSpan(
        text: ' \u00b7 ${deployment.elapsedDuration}',
        style:
            theme.textTheme.bodySmall?.copyWith(color: deployment.isFailed ? statusColor : null),
      ));
    } else if (deployment.startedAt.isNotEmpty) {
      parts.add(TextSpan(
        text: ' \u00b7 ${_formatTimestamp(deployment.startedAt)}',
        style: theme.textTheme.bodySmall,
      ));
    }

    final firstLine = Text.rich(
      TextSpan(children: parts),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    // For running deployments, show objective; for completed, show summary.
    final objective = deployment.isRunning ? deployment.objective : null;
    final summary = deployment.summary;

    if ((objective == null || objective.isEmpty) &&
        (summary == null || summary.isEmpty)) {
      return firstLine;
    }

    final secondLine = deployment.isRunning ? objective : summary;
    if (secondLine == null || secondLine.isEmpty) return firstLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        firstLine,
        Text(
          secondLine,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CompactModelBadge extends StatelessWidget {
  final String agent;
  final String model;
  final ThemeData theme;

  const _CompactModelBadge(
      {required this.agent, required this.model, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$agent: $model',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontSize: 10,
        ),
      ),
    );
  }
}

// --- Local helpers ---

String _formatTimestamp(String iso) {
  // Show short date+time from ISO string, e.g. "2026-03-13T08:00:00+07:00" → "Mar 13 08:00"
  try {
    final dt = DateTime.parse(iso).toLocal();
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day} $h:$m';
  } catch (_) {
    return iso;
  }
}
