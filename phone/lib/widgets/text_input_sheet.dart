import 'package:flutter/material.dart';

import 'no_select_text_field.dart';

/// A reusable bottom sheet for text input with confirm/cancel behavior.
///
/// Shows a text field with an optional initial value. On confirm,
/// calls [onConfirm] with the trimmed text. On cancel/dismiss, calls nothing.
///
/// Usage:
/// ```dart
/// showModalBottomSheet<void>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => TextInputSheet(
///     label: 'Team',
///     initialValue: ticket.team,
///     onConfirm: (value) { ... },
///   ),
/// );
/// ```
class TextInputSheet extends StatefulWidget {
  /// Label shown above the text field (e.g. 'Team', 'Assignee').
  final String label;

  /// Initial value to populate the text field.
  final String? initialValue;

  /// Called when the user confirms the input (presses the checkmark button).
  /// Receives the trimmed text value. Not called on cancel/dismiss.
  final void Function(String value) onConfirm;

  const TextInputSheet({
    super.key,
    required this.label,
    this.initialValue,
    required this.onConfirm,
  });

  @override
  State<TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<TextInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            NoSelectTextFieldRaw(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                labelText: widget.label,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _confirm,
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    final value = _controller.text.trim();
    Navigator.pop(context);
    widget.onConfirm(value);
  }
}
