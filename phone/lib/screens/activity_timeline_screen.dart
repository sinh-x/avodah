import 'dart:async';

import 'package:flutter/material.dart';

import '../models/activity_event.dart';
import '../models/deployment.dart';
import '../screens/document_viewer_screen.dart';
import '../services/agent_api_client.dart';
import '../utils/deploy_helpers.dart';
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
  Deployment? _enrichedDeployment;

  @override
  void initState() {
    super.initState();
    _loadDeploymentDetail();
    _loadEvents();
    if (widget.deployment.isRunning) {
      _scheduleRefresh();
    }
  }

  Future<void> _loadDeploymentDetail() async {
    try {
      final detail =
          await widget.client.getDeploymentDetail(widget.deployment.deploymentId);
      if (mounted) {
        setState(() {
          _enrichedDeployment = detail;
        });
      }
    } catch (e) {
      // Silently ignore — header will show passed-in deployment with available fields
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
      // Continue polling while the deployment is running (check enriched deployment if available)
      if (mounted && (_enrichedDeployment?.isRunning ?? widget.deployment.isRunning)) {
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
    // Use enriched deployment if available, otherwise fall back to passed-in deployment
    final deployment = _enrichedDeployment ?? widget.deployment;

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
          _DeploymentHeader(deployment: deployment, client: widget.client),
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
/// PID, provider, summary, primer/log file links, session rating,
/// and error details section for failed/crashed deployments.
class _DeploymentHeader extends StatelessWidget {
  final Deployment deployment;
  final AgentApiClient client;

  const _DeploymentHeader({required this.deployment, required this.client});

  void _openDocument(BuildContext context, String path, String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(path: path, client: client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(context, deployment.status);

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
                  Icon(statusIcon(deployment.status), color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    deployment.status,
                    style: theme.textTheme.bodyMedium?.copyWith(color: color),
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
          // PID + Provider + ticketId + repo row
          if (deployment.pid != null ||
              deployment.provider != null ||
              deployment.ticketId != null ||
              deployment.repo != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (deployment.pid != null)
                  _InfoChip(
                    icon: Icons.tag,
                    label: 'PID: ${deployment.pid}',
                    theme: theme,
                  ),
                if (deployment.provider != null)
                  _InfoChip(
                    icon: Icons.cloud_outlined,
                    label: deployment.provider!,
                    theme: theme,
                  ),
                if (deployment.ticketId != null)
                  _InfoChip(
                    icon: Icons.confirmation_number_outlined,
                    label: deployment.ticketId!,
                    theme: theme,
                  ),
                if (deployment.repo != null)
                  _InfoChip(
                    icon: Icons.folder_outlined,
                    label: deployment.repo!,
                    theme: theme,
                  ),
              ],
            ),
          ],
          // Summary
          if (deployment.summary != null && deployment.summary!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              deployment.summary!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Objective (running deployments)
          if (deployment.objective != null && deployment.objective!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              deployment.objective!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Session rating
          if (deployment.rating != null) ...[
            const SizedBox(height: 8),
            _RatingSection(rating: deployment.rating!),
          ],
          // Error details for failed/crashed
          if (deployment.isFailed &&
              (deployment.error != null || deployment.exitCode != null)) ...[
            const SizedBox(height: 10),
            _ErrorDetailsSection(deployment: deployment),
          ],
          // Primer path (tappable)
          if (deployment.primerPath != null) ...[
            const SizedBox(height: 8),
            _DocumentLink(
              icon: Icons.article_outlined,
              label: 'Primer',
              path: deployment.primerPath!,
              theme: theme,
              onTap: () => _openDocument(context, deployment.primerPath!, 'Primer'),
            ),
          ],
          // Log file link (tappable → DocumentViewerScreen)
          if (deployment.logFile != null) ...[
            const SizedBox(height: 6),
            _DocumentLink(
              icon: Icons.description_outlined,
              label: 'Log',
              path: deployment.logFile!,
              theme: theme,
              onTap: () => _openDocument(context, deployment.logFile!, 'Log'),
            ),
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

/// Compact info chip for PID, provider, etc.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

/// Session rating display: overall score + optional dimension breakdown.
class _RatingSection extends StatelessWidget {
  final Map<String, dynamic> rating;

  const _RatingSection({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overall = rating['overall'];
    final productivity = rating['productivity'];
    final quality = rating['quality'];
    final efficiency = rating['efficiency'];
    final insight = rating['insight'];

    final hasBreakdown =
        productivity != null || quality != null || efficiency != null || insight != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 16, color: theme.colorScheme.onTertiaryContainer),
              const SizedBox(width: 4),
              Text(
                overall != null ? '$overall/5' : 'No rating',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (rating['source'] != null) ...[
                const SizedBox(width: 6),
                Text(
                  '(${rating['source']})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          if (hasBreakdown) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                if (productivity != null)
                  _RatingDim(label: 'prod', value: productivity.toString(), theme: theme),
                if (quality != null)
                  _RatingDim(label: 'qual', value: quality.toString(), theme: theme),
                if (efficiency != null)
                  _RatingDim(label: 'eff', value: efficiency.toString(), theme: theme),
                if (insight != null)
                  _RatingDim(label: 'ins', value: insight.toString(), theme: theme),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingDim extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _RatingDim({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label:$value',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
        fontFamily: 'monospace',
      ),
    );
  }
}

/// Tappable document link that opens DocumentViewerScreen.
class _DocumentLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DocumentLink({
    required this.icon,
    required this.label,
    required this.path,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              path,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right, size: 14, color: theme.colorScheme.outline),
        ],
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

