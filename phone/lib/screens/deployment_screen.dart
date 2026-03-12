import 'package:flutter/material.dart';

import '../models/deployment.dart';
import '../services/deployment_provider.dart';

/// Shows deployment status with filtering by team and status.
///
/// Supports pull-to-refresh, filter chips, and a detail bottom sheet.
class DeploymentScreen extends StatefulWidget {
  final DeploymentProvider deploymentProvider;

  const DeploymentScreen({super.key, required this.deploymentProvider});

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
                        onTap: () =>
                            _showDetail(context, provider.deployments[index]),
                      );
                    },
                  ),
          ),
        ],
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

  void _showDetail(BuildContext context, Deployment deployment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DeploymentDetail(deployment: deployment),
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
                  _statusIcon(status),
                  size: 14,
                  color: _statusColor(context, status),
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
    final color = _statusColor(context, deployment.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_statusIcon(deployment.status), color: color, size: 20),
        ),
        title: Text(
          deployment.deploymentId,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600),
        ),
        subtitle: _buildSubtitle(theme, color),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme, Color statusColor) {
    final parts = <InlineSpan>[
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

    if (deployment.startedAt.isNotEmpty) {
      parts.add(TextSpan(
        text: ' \u00b7 ${_formatTimestamp(deployment.startedAt)}',
        style: theme.textTheme.bodySmall,
      ));
    }

    return Text.rich(
      TextSpan(children: parts),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Bottom sheet with full deployment details.
class _DeploymentDetail extends StatelessWidget {
  final Deployment deployment;

  const _DeploymentDetail({required this.deployment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(context, deployment.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(_statusIcon(deployment.status),
                            color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deployment.deploymentId,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              deployment.status,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: color),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Info rows
                  _InfoRow(label: 'Team', value: deployment.team),
                  _InfoRow(
                    label: 'Status',
                    value: deployment.status,
                    valueColor: color,
                  ),
                  if (deployment.startedAt.isNotEmpty)
                    _InfoRow(label: 'Started', value: deployment.startedAt),
                  if (deployment.completedAt != null)
                    _InfoRow(
                        label: 'Completed', value: deployment.completedAt!),
                  if (deployment.agents.isNotEmpty)
                    _InfoRow(
                      label: 'Agents',
                      value: deployment.agents.join(', '),
                    ),
                  if (deployment.summary != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Summary',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deployment.summary!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Shared helpers ---

Color _statusColor(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'running':
      return Colors.blue;
    case 'success':
    case 'completed':
      return Colors.green;
    case 'partial':
      return Colors.orange;
    case 'failed':
    case 'crashed':
      return Colors.red;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'running':
      return Icons.play_circle_outline;
    case 'success':
    case 'completed':
      return Icons.check_circle_outline;
    case 'partial':
      return Icons.warning_amber_outlined;
    case 'failed':
    case 'crashed':
      return Icons.error_outline;
    default:
      return Icons.help_outline;
  }
}

String _formatTimestamp(String iso) {
  // Show short date+time from ISO string, e.g. "2026-03-13T08:00:00+07:00" → "Mar 13 08:00"
  try {
    final dt = DateTime.parse(iso).toLocal();
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day} $h:$m';
  } catch (_) {
    return iso;
  }
}
