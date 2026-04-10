import 'package:flutter/material.dart';

/// A bottom-sheet dialog for adding inline comments to markdown text.
///
/// Shows the tapped line with surrounding context, a text input area,
/// and a submit button. Uses amber accent color to distinguish Sinh's
/// annotations from regular UI elements.
///
/// Usage:
/// ```dart
/// showModalBottomSheet<void>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => InlineCommentSheet(
///     contextText: 'the markdown line user tapped',
///     surroundingText: 'the line above or below',
///     onSubmit: (comment) { ... },
///   ),
/// );
/// ```
class InlineCommentSheet extends StatefulWidget {
  /// The exact markdown line the user tapped.
  final String contextText;

  /// One line of surrounding context (line above or below).
  final String? surroundingText;

  /// Called when the user submits a comment. Not called on dismiss/cancel.
  final void Function(String comment) onSubmit;

  const InlineCommentSheet({
    super.key,
    required this.contextText,
    this.surroundingText,
    required this.onSubmit,
  });

  @override
  State<InlineCommentSheet> createState() => _InlineCommentSheetState();
}

class _InlineCommentSheetState extends State<InlineCommentSheet> {
  final _commentController = TextEditingController();

  bool get _canSubmit => _commentController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Amber accent for Sinh's annotations (distinct from regular UI)
    const amberAccent = Color(0xFFFFC107);
    final amberDark = Colors.amber.shade700;
    final amberLight = Colors.amber.shade50;
    final amberBorder = Colors.amber.shade200;

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
            // Header with context
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: amberLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: amberBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Context',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: amberDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.surroundingText != null) ...[
                    Text(
                      widget.surroundingText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    widget.contextText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Comment input
            TextField(
              controller: _commentController,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: amberDark, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSubmit ? _onSubmit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: amberAccent,
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: amberBorder,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    final comment = _commentController.text.trim();
    Navigator.pop(context);
    widget.onSubmit(comment);
  }
}
