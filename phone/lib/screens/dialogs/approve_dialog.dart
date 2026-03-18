import 'package:flutter/material.dart';

import '../../models/feedback_payload.dart';
import '../../services/agent_api_client.dart';
import '../../widgets/destination_team_selector.dart';

/// Dialog for approving an inbox item with optional note, feedback chips,
/// and destination team routing.
///
/// Returns [ApproveFeedback] on confirm (may have no content — fast-path).
/// Returns null if the user cancels.
///
/// Usage:
/// ```dart
/// final feedback = await ApproveDialog.show(
///   context,
///   availableChips: chips,
///   client: client,
///   initialDestinationTeam: item.to,
/// );
/// if (feedback != null) { /* proceed */ }
/// ```
class ApproveDialog extends StatefulWidget {
  final List<String> availableChips;
  final AgentApiClient client;

  /// Pre-filled destination team, typically from item's `To:` frontmatter field.
  final String? initialDestinationTeam;

  const ApproveDialog({
    super.key,
    required this.availableChips,
    required this.client,
    this.initialDestinationTeam,
  });

  static Future<ApproveFeedback?> show(
    BuildContext context, {
    required List<String> availableChips,
    required AgentApiClient client,
    String? initialDestinationTeam,
  }) {
    return showDialog<ApproveFeedback>(
      context: context,
      builder: (ctx) => ApproveDialog(
        availableChips: availableChips,
        client: client,
        initialDestinationTeam: initialDestinationTeam,
      ),
    );
  }

  @override
  State<ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<ApproveDialog> {
  final _noteController = TextEditingController();
  final Set<String> _selectedChips = {};
  String? _destinationTeam;

  @override
  void initState() {
    super.initState();
    _destinationTeam = widget.initialDestinationTeam;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleChip(String chip) {
    setState(() {
      if (_selectedChips.contains(chip)) {
        _selectedChips.remove(chip);
      } else {
        _selectedChips.add(chip);
      }
    });
  }

  void _onApprove() {
    Navigator.pop(
      context,
      ApproveFeedback(
        note: _noteController.text.isNotEmpty ? _noteController.text.trim() : null,
        chips: _selectedChips.toList(),
        destinationTeam: _destinationTeam,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route to team (optional)'),
            const SizedBox(height: 8),
            DestinationTeamSelector(
              client: widget.client,
              initialTeam: widget.initialDestinationTeam,
              onChanged: (team) => setState(() => _destinationTeam = team),
            ),
            const SizedBox(height: 16),
            const Text('Note (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Add a note for the agent...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (widget.availableChips.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Quick chips'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.availableChips.map((chip) {
                  final selected = _selectedChips.contains(chip);
                  return FilterChip(
                    label: Text(chip),
                    selected: selected,
                    onSelected: (_) => _toggleChip(chip),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          // Approve button is always enabled (fast-path: note + chips both optional)
          onPressed: _onApprove,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Approve'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
