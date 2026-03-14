import 'package:flutter/material.dart';

/// Dialog for confirming a plan-draft item that has changes.
///
/// Shows an optional note field where Sinh can describe what needs to change
/// before confirming. Matching the mockup from §14d of the requirements.
///
/// Returns the note text (may be empty string) on confirm, or null if cancelled.
/// An empty string means confirmed with no note — call site passes `null` to the API.
///
/// Usage:
/// ```dart
/// final note = await PlanConfirmDialog.show(context);
/// if (note != null) {
///   await provider.acknowledge(id, note: note.isNotEmpty ? note : null);
/// }
/// ```
class PlanConfirmDialog extends StatefulWidget {
  const PlanConfirmDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => const PlanConfirmDialog(),
    );
  }

  @override
  State<PlanConfirmDialog> createState() => _PlanConfirmDialogState();
}

class _PlanConfirmDialogState extends State<PlanConfirmDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.edit_note),
          SizedBox(width: 8),
          Text('Confirm Plan with Changes'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What's changing? (optional)"),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText:
                  'e.g. "Dropping AG-491, focus on Daisy only today"',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
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
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
