import 'package:flutter/material.dart';

import '../models/timer_info.dart';
import '../services/agent_api_client.dart';

/// Shows active PA systemd timers from `pa timers`.
class TimersScreen extends StatefulWidget {
  final AgentApiClient apiClient;

  const TimersScreen({super.key, required this.apiClient});

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  List<TimerInfo> _timers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTimers();
  }

  Future<void> _loadTimers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final timers = await widget.apiClient.listTimers();
      if (mounted) {
        setState(() {
          _timers = timers;
          _loading = false;
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PA Timers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : _timers.isEmpty
                  ? _buildEmpty(theme)
                  : RefreshIndicator(
                      onRefresh: _loadTimers,
                      child: ListView.builder(
                        itemCount: _timers.length,
                        itemBuilder: (context, index) {
                          final timer = _timers[index];
                          return ListTile(
                            leading: Icon(
                              Icons.timer_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(timer.team),
                            subtitle: Text(
                              timer.unit,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline),
                            ),
                            trailing: timer.nextIn.isNotEmpty
                                ? Chip(
                                    label: Text(timer.nextIn),
                                    visualDensity: VisualDensity.compact,
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_off_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No scheduled timers',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load timers', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadTimers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
