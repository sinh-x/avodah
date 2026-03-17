import 'package:flutter/material.dart';

import '../models/snapshot.dart';
import '../services/local_dashboard_provider.dart';
import '../services/local_write_service.dart';
import '../services/sync_client.dart' show SyncConnectionState;
import '../settings/settings_screen.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/plan_category_table.dart';
import '../widgets/planned_task_list.dart';
import '../widgets/timer_status_bar.dart';
import '../widgets/worklog_summary.dart';

class DashboardScreen extends StatefulWidget {
  final LocalDashboardProvider dashboardProvider;
  final LocalWriteService writeService;

  const DashboardScreen({
    super.key,
    required this.dashboardProvider,
    required this.writeService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.dashboardProvider.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.dashboardProvider.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _stopTimer() async {
    final result = await widget.writeService.stopTimerAndLog();
    await widget.dashboardProvider.refresh();
    if (!mounted) return;
    final msg = result.worklogId != null
        ? 'Timer stopped. Worklog created.'
        : 'Timer stopped.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _toggleTaskDone(String taskId) async {
    final newDone = await widget.writeService.toggleTaskDone(taskId);
    await widget.dashboardProvider.refresh();
    if (!mounted || newDone == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newDone ? 'Task marked done.' : 'Task marked undone.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = widget.dashboardProvider.snapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avodah'),
        actions: [
          ValueListenableBuilder<SyncConnectionState>(
            valueListenable: widget.dashboardProvider.connectionState,
            builder: (_, state, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ConnectionIndicator(state: state),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: snapshot == null ? _buildEmpty(theme) : _buildDashboard(theme, snapshot),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_disabled,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('Waiting for data...',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 8),
          ValueListenableBuilder<SyncConnectionState>(
            valueListenable: widget.dashboardProvider.connectionState,
            builder: (_, state, _) {
              if (state == SyncConnectionState.disconnected) {
                return Text('Check server address in settings',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline));
              }
              if (state == SyncConnectionState.connecting) {
                return const CircularProgressIndicator();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme, DaySnapshot s) {
    final lastUpdated = DateTime.now().difference(s.timestamp);
    final staleText = lastUpdated.inSeconds < 60
        ? 'Just now'
        : '${lastUpdated.inMinutes}m ago';

    return RefreshIndicator(
      onRefresh: () => widget.dashboardProvider.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Last updated
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.update, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text('Updated: $staleText',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),

          // Timer
          TimerStatusBar(
            timer: s.timer,
            onStop: s.timer != null ? _stopTimer : null,
          ),
          const SizedBox(height: 8),

          // Plan vs Actual
          PlanCategoryTable(plan: s.plan),
          const SizedBox(height: 8),

          // Planned tasks
          PlannedTaskList(
            tasks: s.plannedTasks,
            onToggleDone: _toggleTaskDone,
          ),
          if (s.plannedTasks.isNotEmpty) const SizedBox(height: 8),

          // Worklog summary
          WorklogSummary(worklog: s.worklogSummary),
        ],
      ),
    );
  }
}
