import 'package:flutter/material.dart';

import '../models/agent_team.dart';
import '../services/agent_api_client.dart';

/// A dropdown widget for selecting a destination agent team for routing.
///
/// Fetches the team list from GET /api/agent-teams on build. Shows a loading
/// indicator while fetching and falls back to an empty dropdown on error (does
/// not block the parent dialog).
///
/// Supports an optional initial/default value for auto-fill. Includes a
/// "None (no routing)" sentinel item so the user can clear any pre-selection.
///
/// Usage:
/// ```dart
/// DestinationTeamSelector(
///   client: client,
///   initialTeam: item.to,       // or item.from for reject
///   onChanged: (team) => setState(() => _destinationTeam = team),
/// )
/// ```
class DestinationTeamSelector extends StatefulWidget {
  /// API client used to fetch the team list.
  final AgentApiClient client;

  /// Pre-selected team name (auto-fill from frontmatter). Null = no selection.
  final String? initialTeam;

  /// Called when the selection changes. Receives null when "No routing" is chosen.
  final void Function(String?) onChanged;

  const DestinationTeamSelector({
    super.key,
    required this.client,
    required this.onChanged,
    this.initialTeam,
  });

  @override
  State<DestinationTeamSelector> createState() =>
      _DestinationTeamSelectorState();
}

class _DestinationTeamSelectorState extends State<DestinationTeamSelector> {
  List<AgentTeam> _teams = [];
  bool _loading = true;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTeam;
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      final teams = await widget.client.listAgentTeams();
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _loading = false;
        // If the initial value is not in the fetched list, clear it.
        if (_selected != null &&
            !teams.any((t) => t.name == _selected)) {
          _selected = null;
          widget.onChanged(null);
        }
      });
    } catch (e) {
      debugPrint('DestinationTeamSelector: failed to fetch teams: $e');
      if (!mounted) return;
      setState(() {
        _teams = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading teams…',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    // Build dropdown items: "No routing" sentinel + sorted team names.
    final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(
          'No routing',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ),
      ..._teams.map(
        (t) => DropdownMenuItem<String?>(
          value: t.name,
          child: Row(
            children: [
              Text(t.name),
              if (!t.inboxExists) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.warning_amber_outlined,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
              ],
            ],
          ),
        ),
      ),
    ];

    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButton<String?>(
        value: _selected,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          'Select destination team',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        items: items,
        onChanged: (value) {
          setState(() => _selected = value);
          widget.onChanged(value);
        },
      ),
    );
  }
}
