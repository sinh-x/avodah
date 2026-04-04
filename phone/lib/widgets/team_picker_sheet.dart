import 'package:flutter/material.dart';

import '../models/agent_team.dart';
import '../services/agent_api_client.dart';

/// A bottom sheet for picking a team from the available agent teams.
///
/// Fetches the team list from [AgentApiClient.listAgentTeams]. Shows a
/// loading indicator while fetching and falls back to an empty list on error.
///
/// Includes a "None" sentinel item to allow clearing the team field.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => TeamPickerSheet(
///     client: boardProvider.client,
///     currentTeam: ticket.team,
///     onSelect: (team) { _saveField('team', team); },
///   ),
/// );
/// ```
class TeamPickerSheet extends StatefulWidget {
  final AgentApiClient client;
  final String? currentTeam;
  final void Function(String? team) onSelect;

  const TeamPickerSheet({
    super.key,
    required this.client,
    this.currentTeam,
    required this.onSelect,
  });

  @override
  State<TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<TeamPickerSheet> {
  List<AgentTeam> _teams = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      final teams = await widget.client.listAgentTeams();
      if (!mounted) return;
      setState(() {
        _teams = teams..sort((a, b) => a.name.compareTo(b.name));
        _loading = false;
      });
    } catch (e) {
      debugPrint('TeamPickerSheet: failed to fetch teams: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Select Team',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          if (_loading) ...[
            const SizedBox(height: 48),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 48),
          ] else if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load teams: $_error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ] else ...[
            // None option to clear the team field
            ListTile(
              leading: Icon(Icons.clear, color: theme.colorScheme.outline),
              title: Text(
                'None',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              trailing: widget.currentTeam == null
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              selected: widget.currentTeam == null,
              selectedColor: theme.colorScheme.primary,
              onTap: () {
                widget.onSelect(null);
                Navigator.of(context).pop();
              },
            ),
            const Divider(height: 1),
            ..._teams.map((team) {
              final isSelected = team.name == widget.currentTeam;
              return ListTile(
                leading: Icon(
                  Icons.group_outlined,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: Row(
                  children: [
                    Text(
                      team.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (!team.inboxExists) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.warning_amber_outlined,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ],
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                selected: isSelected,
                selectedColor: theme.colorScheme.primary,
                onTap: () {
                  widget.onSelect(team.name);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
