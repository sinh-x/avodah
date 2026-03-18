import 'package:flutter/material.dart';

import '../../models/feedback_payload.dart';
import '../../services/agent_api_client.dart';
import '../../widgets/destination_team_selector.dart';

/// Dialog for rejecting an inbox item with structured feedback fields
/// and optional destination team routing.
///
/// Returns [RejectFeedback] on full reject (both required fields filled).
/// Returns [RejectFeedback.pendingOnly()] when user taps "Reject now, add later".
/// Returns null if the user cancels.
///
/// Usage:
/// ```dart
/// final feedback = await RejectDialog.show(
///   context,
///   availableChips: chips,
///   client: client,
///   initialDestinationTeam: item.from — extract team part before ' / ',
/// );
/// if (feedback != null) { /* proceed */ }
/// ```
class RejectDialog extends StatefulWidget {
  final List<String> availableChips;
  final AgentApiClient client;

  /// Pre-filled destination team, typically extracted from item's `From:` field.
  /// The caller should strip the agent suffix (e.g. "requirements / team-manager"
  /// → "requirements") before passing this value.
  final String? initialDestinationTeam;

  const RejectDialog({
    super.key,
    required this.availableChips,
    required this.client,
    this.initialDestinationTeam,
  });

  static Future<RejectFeedback?> show(
    BuildContext context, {
    required List<String> availableChips,
    required AgentApiClient client,
    String? initialDestinationTeam,
  }) {
    return showDialog<RejectFeedback>(
      context: context,
      builder: (ctx) => RejectDialog(
        availableChips: availableChips,
        client: client,
        initialDestinationTeam: initialDestinationTeam,
      ),
    );
  }

  @override
  State<RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<RejectDialog> {
  final _wrongController = TextEditingController();
  final _fixController = TextEditingController();
  FeedbackPriority _priority = FeedbackPriority.medium;
  final Set<String> _selectedChips = {};
  String? _destinationTeam;

  @override
  void initState() {
    super.initState();
    _destinationTeam = widget.initialDestinationTeam;
  }

  @override
  void dispose() {
    _wrongController.dispose();
    _fixController.dispose();
    super.dispose();
  }

  bool get _canReject =>
      _wrongController.text.trim().isNotEmpty &&
      _fixController.text.trim().isNotEmpty;

  void _toggleChip(String chip) {
    setState(() {
      if (_selectedChips.contains(chip)) {
        _selectedChips.remove(chip);
      } else {
        _selectedChips.add(chip);
      }
    });
  }

  void _onReject() {
    Navigator.pop(
      context,
      RejectFeedback(
        whatIsWrong: _wrongController.text.trim(),
        whatToFix: _fixController.text.trim(),
        priority: _priority,
        chips: _selectedChips.toList(),
        destinationTeam: _destinationTeam,
      ),
    );
  }

  void _onRejectPending() {
    Navigator.pop(context, const RejectFeedback.pendingOnly());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Reject'),
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
            const Text("What's wrong? *"),
            const SizedBox(height: 8),
            TextField(
              controller: _wrongController,
              decoration: const InputDecoration(
                hintText: 'e.g. "Missing UX specs"',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const Text('What to fix? *'),
            const SizedBox(height: 8),
            TextField(
              controller: _fixController,
              decoration: const InputDecoration(
                hintText: 'e.g. "Add phone mockups..."',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const Text('Priority'),
            const SizedBox(height: 8),
            SegmentedButton<FeedbackPriority>(
              segments: FeedbackPriority.values
                  .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (sel) =>
                  setState(() => _priority = sel.first),
            ),
            if (widget.availableChips.isNotEmpty) ...[
              const SizedBox(height: 12),
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
        // Tertiary action: reject now without filling feedback fields
        TextButton(
          onPressed: _onRejectPending,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          child: const Text('Reject now, add later'),
        ),
        FilledButton.icon(
          // Full reject requires both fields filled
          onPressed: _canReject ? _onReject : null,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Reject'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
        ),
      ],
    );
  }
}
