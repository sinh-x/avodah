import 'dart:async';

import 'package:flutter/material.dart';

import '../models/activity_event.dart';
import '../models/deployment.dart';
import '../services/agent_api_client.dart';
import '../widgets/activity_event_tile.dart';

/// Full-screen activity timeline for a single deployment.
///
/// Shows a chronological event list with auto-refresh (every 4s) when the
/// deployment is running. Has a compact/expanded toggle for event detail level.
class ActivityTimelineScreen extends StatefulWidget {
  final Deployment deployment;
  final AgentApiClient client;

  const ActivityTimelineScreen({
    super.key,
    required this.deployment,
    required this.client,
  });

  @override
  State<ActivityTimelineScreen> createState() => _ActivityTimelineScreenState();
}

class _ActivityTimelineScreenState extends State<ActivityTimelineScreen> {
  List<ActivityEvent> _events = [];
  bool _loading = true;
  String? _error;
  bool _expanded = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    if (widget.deployment.isRunning) {
      _scheduleRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 4), () async {
      await _loadEvents(background: true);
      if (mounted && widget.deployment.isRunning) {
        _scheduleRefresh();
      }
    });
  }

  Future<void> _loadEvents({bool background = false}) async {
    if (!background) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final events = await widget.client
          .getDeploymentActivity(widget.deployment.deploymentId);
      if (mounted) {
        setState(() {
          _events = events;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deployment = widget.deployment;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          deployment.deploymentId,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: _expanded ? 'Compact view' : 'Expanded view',
            icon: Icon(_expanded ? Icons.unfold_less : Icons.unfold_more),
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadEvents(),
          ),
        ],
      ),
      body: Column(
        children: [
          _DeploymentHeader(deployment: deployment),
          if (_loading && _events.isEmpty)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _events.isEmpty)
            Expanded(child: _buildError())
          else if (_events.isEmpty)
            Expanded(child: _buildEmpty())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                itemCount: _events.length,
                itemBuilder: (context, index) => ActivityEventTile(
                  event: _events[index],
                  expanded: _expanded,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'Failed to load activity',
            style:
                theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'No events yet',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

/// Header card with deployment metadata: status, duration, model badges,
/// and error details section for failed/crashed deployments.
class _DeploymentHeader extends StatelessWidget {
  final Deployment deployment;

  const _DeploymentHeader({required this.deployment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(context, deployment.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + team + duration row
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(deployment.status), color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    deployment.status,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ],
              ),
              Text('·',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
              Text(
                deployment.team,
                style: theme.textTheme.bodyMedium,
              ),
              if (deployment.elapsedDuration.isNotEmpty) ...[
                Text('·',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      deployment.elapsedDuration,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ],
            ],
          ),
          // Running indicator
          if (deployment.isRunning) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: theme.colorScheme.outlineVariant,
              ),
            ),
          ],
          // Model badges per agent
          if (deployment.models.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: deployment.models.entries
                  .map((e) => _ModelBadge(agent: e.key, model: e.value))
                  .toList(),
            ),
          ],
          // Task progress: completed/failed counts from deployment.agents
          if (deployment.agents.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${deployment.agents.length} agent${deployment.agents.length == 1 ? '' : 's'}: '
              '${deployment.agents.join(', ')}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Working directory
          if (deployment.cwd != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder_outlined,
                    size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deployment.cwd!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          // Error details for failed/crashed
          if (deployment.isFailed &&
              (deployment.error != null || deployment.exitCode != null)) ...[
            const SizedBox(height: 10),
            _ErrorDetailsSection(deployment: deployment),
          ],
        ],
      ),
    );
  }
}

class _ModelBadge extends StatelessWidget {
  final String agent;
  final String model;

  const _ModelBadge({required this.agent, required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$agent: $model',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Visually emphasized error details box for failed/crashed deployments.
class _ErrorDetailsSection extends StatelessWidget {
  final Deployment deployment;

  const _ErrorDetailsSection({required this.deployment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline,
                  size: 16, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 6),
              Text(
                'Error Details',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (deployment.exitCode != null) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'exit ${deployment.exitCode}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onError,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (deployment.error != null) ...[
            const SizedBox(height: 6),
            Text(
              deployment.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontFamily: 'monospace',
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
