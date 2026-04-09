import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Pattern to detect inline comment annotation sections.
///
/// Matches markdown headings with format: ## N: Title
/// where N is a line/section number.
final _annotationPattern = RegExp(r'^##\s+(\d+):\s+(.*)$');

/// A markdown widget with tap detection for inline commenting and
/// annotation marker rendering.
///
/// Wraps [Markdown] to detect taps on individual lines/paragraphs and
/// renders inline comment annotation markers (## N: Title sections) as
/// visually distinct styled blockquotes with amber/yellow left border.
///
/// Usage:
/// ```dart
/// MarkdownWithAnnotations(
///   data: markdownContent,
///   onLineTapped: (lineIndex, lineText, lineNumber) {
///     // Show inline comment sheet
///   },
/// )
/// ```
class MarkdownWithAnnotations extends StatefulWidget {
  /// The markdown content to render.
  final String data;

  /// Called when the user taps a line or paragraph of rendered markdown.
  /// Passes the 0-based line index, the tapped text, and the 1-based line number.
  final void Function(int lineIndex, String tappedText, int lineNumber) onLineTapped;

  /// Optional style for annotation markers. Falls back to default amber
  /// blockquote styling.
  final MarkdownStyleSheet? styleSheet;

  const MarkdownWithAnnotations({
    super.key,
    required this.data,
    required this.onLineTapped,
    this.styleSheet,
  });

  @override
  State<MarkdownWithAnnotations> createState() => _MarkdownWithAnnotationsState();
}

class _MarkdownWithAnnotationsState extends State<MarkdownWithAnnotations> {
  String _selectedText = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyleSheet = theme.textTheme.bodyMedium?.merge(
      const TextStyle(height: 1.5),
    );
    final lines = widget.data.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show selected text if any
        if (_selectedText.isNotEmpty)
          GestureDetector(
            onTap: () => _showCommentSheet(_selectedText),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.comment_outlined, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Comment on: "$_selectedText"',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.add, size: 16, color: Colors.amber.shade700),
                ],
              ),
            ),
          ),
        // Line numbers + Markdown
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line numbers column
            SizedBox(
              width: 32,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    children: List.generate(lines.length, (index) {
                      return TextSpan(text: '${index + 1}\n');
                    }),
                  ),
                ),
              ),
            ),
            // Markdown content - selectable
            Expanded(
              child: SelectionArea(
                onSelectionChanged: (selection) {
                  if (selection != null && selection.plainText.isNotEmpty) {
                    setState(() {
                      _selectedText = selection.plainText;
                    });
                  }
                },
                child: Markdown(
                  data: widget.data,
                  shrinkWrap: true,
                  styleSheet: widget.styleSheet ?? _buildAnnotationStyleSheet(context, defaultStyleSheet),
                  builders: {
                    'blockquote': _AnnotationBlockquoteBuilder(
                      onLineTapped: widget.onLineTapped,
                      sourceLines: lines,
                    ),
                  },
                  onTapLink: (text, href, title) {
                    // Allow link taps to open URLs
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCommentSheet(String selectedText) {
    // Find ALL occurrences of the selected text in the document
    final lines = widget.data.split('\n');
    List<int> matchingLineIndices = [];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(selectedText)) {
        matchingLineIndices.add(i);
      }
    }

    // Use first match
    final lineIndex = matchingLineIndices.isNotEmpty ? matchingLineIndices.first : 0;

    // Clear selection and call onLineTapped
    setState(() {
      _selectedText = '';
    });

    widget.onLineTapped(lineIndex, selectedText, lineIndex + 1);
  }

  MarkdownStyleSheet _buildAnnotationStyleSheet(
    BuildContext context,
    TextStyle? baseStyle,
  ) {
    final theme = Theme.of(context);
    const amberAccent = Color(0xFFFFC107);
    final amberLight = Colors.amber.shade50;

    return MarkdownStyleSheet(
      blockquote: baseStyle?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      blockquoteDecoration: BoxDecoration(
        color: amberLight,
        border: const Border(
          left: BorderSide(color: amberAccent, width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(
        left: 12,
        top: 8,
        bottom: 8,
        right: 12,
      ),
    );
  }
}

/// Custom builder for blockquote elements that detects annotation markers.
class _AnnotationBlockquoteBuilder extends MarkdownElementBuilder {
  final void Function(int lineIndex, String tappedText, int lineNumber) onLineTapped;
  final List<String> sourceLines;

  _AnnotationBlockquoteBuilder({
    required this.onLineTapped,
    required this.sourceLines,
  });

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    // Get the text content of the blockquote
    final textContent = element.textContent;

    // Check if this blockquote matches the annotation pattern ## N: Title
    final match = _annotationPattern.firstMatch(textContent);
    if (match == null) {
      // Regular blockquote — return null to use default styling
      return null;
    }

    // This is an annotation marker — apply distinct amber styling
    const amberAccent = Color(0xFFFFC107);
    final amberDark = Colors.amber.shade700;
    final amberLight = Colors.amber.shade50;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(
        left: 12,
        top: 8,
        bottom: 8,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: amberLight,
        border: const Border(
          left: BorderSide(color: amberAccent, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 18,
            color: amberDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              textContent,
              style: preferredStyle?.copyWith(
                color: amberDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}