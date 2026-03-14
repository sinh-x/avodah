import 'package:flutter/material.dart';

/// Simple confirmation dialog for destructive folder actions (re-queue, archive,
/// save-for-later).
///
/// Returns true when the user confirms, false/null on cancel.
///
/// Usage:
/// ```dart
/// final confirmed = await ConfirmActionDialog.show(
///   context,
///   title: 'Re-queue item?',
///   message: 'This will move the item back to your inbox.',
///   confirmLabel: 'Re-queue',
/// );
/// if (confirmed == true) { /* proceed */ }
/// ```
class ConfirmActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmActionDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
