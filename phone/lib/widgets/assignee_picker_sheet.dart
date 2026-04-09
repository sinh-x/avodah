import 'package:flutter/material.dart';

import '../models/agent_team.dart';
import '../services/agent_api_client.dart';

/// A bottom sheet for picking an assignee from the available agent teams.
///
/// Fetches the team list from [AgentApiClient.listAgentTeams]. Shows a
/// loading indicator while fetching and falls back to an empty list on error.
///
/// Includes a "None" sentinel item to allow clearing the assignee field.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => AssigneePickerSheet(
///     client: boardProvider.client,
///     currentAssignee: ticket.assignee,
///     onSelect: (assignee) { _saveField('assignee', assignee); },
///   ),
/// );
/// ```
class AssigneePickerSheet extends StatefulWidget {
  final AgentApiClient client;
  final String? currentAssignee;
  final void Function(String? assignee) onSelect;

  const AssigneePickerSheet({
    super.key,
    required this.client,
    this.currentAssignee,
    required this.onSelect,
  });

  @override
  State<AssigneePickerSheet> createState() => _AssigneePickerSheetState();
}

class _AssigneePickerSheetState extends State<AssigneePickerSheet> {
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
      debugPrint('AssigneePickerSheet: failed to fetch teams: $e');
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
              'Select Assignee',
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
            // None option to clear the assignee field (always visible)
            ListTile(
              leading: Icon(Icons.clear, color: theme.colorScheme.outline),
              title: Text(
                'None',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              trailing: widget.currentAssignee == null
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              selected: widget.currentAssignee == null,
              selectedColor: theme.colorScheme.primary,
              onTap: () {
                widget.onSelect(null);
                Navigator.of(context).pop();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _teams.length,
                itemBuilder: (context, index) {
                  final team = _teams[index];
                  final isSelected = team.name == widget.currentAssignee;
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
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
