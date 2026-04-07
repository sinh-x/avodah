import 'package:flutter/material.dart';

import '../models/deployment.dart';
import '../screens/activity_timeline_screen.dart';
import '../services/agent_api_client.dart';

/// A collapsible section listing deployments linked to a ticket.
///
/// Shows loading/error states and navigates to [ActivityTimelineScreen] on tap.
class TicketDeploymentsSection extends StatelessWidget {
  /// The list of deployments to display.
  final List<Deployment> deployments;

  /// Whether the deployments are currently being loaded.
  final bool isLoading;

  /// An error message if the deployments could not be fetched, or null.
  final String? error;

  /// The API client used to navigate to [ActivityTimelineScreen].
  final AgentApiClient client;

  const TicketDeploymentsSection({
    super.key,
    required this.deployments,
    this.isLoading = false,
    this.error,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Deployments section',
      child: _SectionContent(
        deployments: deployments,
        isLoading: isLoading,
        error: error,
        client: client,
      ),
    );
  }
}

class _SectionContent extends StatefulWidget {
  final List<Deployment> deployments;
  final bool isLoading;
  final String? error;
  final AgentApiClient client;

  const _SectionContent({
    required this.deployments,
    required this.isLoading,
    required this.error,
    required this.client,
  });

  @override
  State<_SectionContent> createState() => _SectionContentState();
}

class _SectionContentState extends State<_SectionContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = widget.deployments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header — tappable to expand/collapse
        Semantics(
          label: 'Deployments section. '
              '${hasData ? "${widget.deployments.length} deployments" : "no deployments"}. '
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
                    'Deployments',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.deployments.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
          child: Text('Loading deployments...'),
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
                'Failed to load deployments',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.deployments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No deployments.',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    return Column(
      children: widget.deployments
          .map((d) => _DeploymentRow(deployment: d, client: widget.client))
          .toList(),
    );
  }
}

/// A single deployment row with status colors and tap-to-navigate.
class _DeploymentRow extends StatelessWidget {
  final Deployment deployment;
  final AgentApiClient client;

  const _DeploymentRow({required this.deployment, required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, deployment.status);

    return Semantics(
      label: 'Deployment ${deployment.deploymentId}, '
          'team ${deployment.team}, '
          'status ${deployment.status}, '
          'elapsed ${deployment.elapsedDuration}',
      button: true,
      child: InkWell(
        onTap: () => _navigateToTimeline(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              // Deployment ID
              Text(
                deployment.deploymentId,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              // Team
              Text(
                deployment.team,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Spacer(),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  deployment.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Elapsed time
              Text(
                deployment.elapsedDuration,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTimeline(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityTimelineScreen(
          deployment: deployment,
          client: client,
        ),
      ),
    );
  }
}

Color _statusColor(BuildContext context, String status) {
  switch (status) {
    case 'success':
      return Colors.green;
    case 'running':
      return Colors.orange;
    case 'failed':
    case 'crashed':
      return Colors.red;
    case 'partial':
      return Colors.amber;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}
