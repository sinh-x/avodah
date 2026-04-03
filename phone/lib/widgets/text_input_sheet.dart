import 'package:flutter/material.dart';

/// A TextField that places cursor at tap position on single tap,
/// without selecting text. Preserves double-tap word selection.
///
/// Works around flutter/flutter#98720, #105185 where single taps in
/// TextFields can unexpectedly select words instead of placing cursor.
class _NoSelectTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  const _NoSelectTextField({
    required this.controller,
    this.decoration,
    this.maxLines,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<_NoSelectTextField> createState() => _NoSelectTextFieldState();
}

class _NoSelectTextFieldState extends State<_NoSelectTextField> {
  Offset? _tapPosition;

  void _handleTapDown(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _handleTap() {
    if (_tapPosition == null) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(_tapPosition!);

    // Calculate cursor offset from tap position
    final textPainter = TextPainter(
      text: TextSpan(text: widget.controller.text),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: renderBox.size.width);

    // Find the character offset nearest to tap position
    final textPosition = textPainter.getPositionForOffset(localPosition);
    widget.controller.selection = TextSelection.collapsed(
      offset: textPosition.offset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        decoration: widget.decoration,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

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
            _NoSelectTextField(
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
