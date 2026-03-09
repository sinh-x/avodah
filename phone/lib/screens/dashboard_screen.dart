import 'dart:async';

import 'package:flutter/material.dart';

import '../models/snapshot.dart';
import '../services/sync_client.dart';
import '../settings/settings_screen.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/plan_category_table.dart';
import '../widgets/planned_task_list.dart';
import '../widgets/timer_status_bar.dart';
import '../widgets/worklog_summary.dart';

class DashboardScreen extends StatefulWidget {
  final SyncClient syncClient;

  const DashboardScreen({super.key, required this.syncClient});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DaySnapshot? _snapshot;
  StreamSubscription<DaySnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.syncClient.lastSnapshot;
    _sub = widget.syncClient.snapshots.listen((snapshot) {
      setState(() => _snapshot = snapshot);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avodah'),
        actions: [
          ValueListenableBuilder<SyncConnectionState>(
            valueListenable: widget.syncClient.connectionState,
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
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
              if (result == true && mounted) {
                // Server URL changed — caller handles reconnect
              }
            },
          ),
        ],
      ),
      body: _snapshot == null ? _buildEmpty(theme) : _buildDashboard(theme),
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
            valueListenable: widget.syncClient.connectionState,
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

  Widget _buildDashboard(ThemeData theme) {
    final s = _snapshot!;
    final lastUpdated = DateTime.now().difference(s.timestamp);
    final staleText = lastUpdated.inSeconds < 60
        ? 'Just now'
        : '${lastUpdated.inMinutes}m ago';

    return RefreshIndicator(
      onRefresh: () async {
        // Manual refresh hint — server will push on next interval
        await Future.delayed(const Duration(milliseconds: 500));
      },
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
          TimerStatusBar(timer: s.timer),
          const SizedBox(height: 8),

          // Plan vs Actual
          PlanCategoryTable(plan: s.plan),
          const SizedBox(height: 8),

          // Planned tasks
          PlannedTaskList(tasks: s.plannedTasks),
          if (s.plannedTasks.isNotEmpty) const SizedBox(height: 8),

          // Worklog summary
          WorklogSummary(worklog: s.worklogSummary),
        ],
      ),
    );
  }
}
