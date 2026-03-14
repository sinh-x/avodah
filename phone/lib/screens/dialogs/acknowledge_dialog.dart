import 'package:flutter/material.dart';

/// Dialog for acknowledging a work-report inbox item with an optional note.
///
/// Fast-path: single tap "Acknowledge" in the action bar (no dialog, no annotation).
/// Note path: long-press "Acknowledge" → this dialog → optional note written to frontmatter.
///
/// Returns the note text (may be empty string) on confirm, or null if cancelled.
/// An empty string means confirmed with no note — call site passes `null` to the API.
///
/// Usage:
/// ```dart
/// final note = await AcknowledgeDialog.show(context);
/// if (note != null) {
///   await provider.acknowledge(id, note: note.isNotEmpty ? note : null);
/// }
/// ```
class AcknowledgeDialog extends StatefulWidget {
  const AcknowledgeDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => const AcknowledgeDialog(),
    );
  }

  @override
  State<AcknowledgeDialog> createState() => _AcknowledgeDialogState();
}

class _AcknowledgeDialogState extends State<AcknowledgeDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Acknowledge'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Note (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Add a note about this report...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _noteController.text.trim()),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Acknowledge'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
