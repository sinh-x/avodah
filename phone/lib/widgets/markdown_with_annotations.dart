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
///   onLineTapped: (lineIndex, lineText) {
///     // Show inline comment sheet
///   },
/// )
/// ```
class MarkdownWithAnnotations extends StatelessWidget {
  /// The markdown content to render.
  final String data;

  /// Called when the user taps a line or paragraph of rendered markdown.
  /// Passes the 0-based line index and the text content of that line.
  final void Function(int lineIndex, String lineText) onLineTapped;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyleSheet = theme.textTheme.bodyMedium?.merge(
      const TextStyle(height: 1.5),
    );

    return GestureDetector(
      onTapUp: (details) => _handleTap(context, details.localPosition),
      behavior: HitTestBehavior.opaque,
      child: Markdown(
        data: data,
        shrinkWrap: true,
        styleSheet: styleSheet ?? _buildAnnotationStyleSheet(context, defaultStyleSheet),
        builders: {
          'blockquote': _AnnotationBlockquoteBuilder(
            onLineTapped: onLineTapped,
            sourceLines: data.split('\n'),
          ),
        },
        onTapLink: (text, href, title) {
          // Allow link taps to open URLs
        },
      ),
    );
  }

  void _handleTap(BuildContext context, Offset localPosition) {
    // Estimate line based on tap position
    final lineHeight = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16 * 1.5;
    final lineIndex = (localPosition.dy / lineHeight).floor();
    final lines = data.split('\n');
    if (lineIndex >= 0 && lineIndex < lines.length) {
      onLineTapped(lineIndex, lines[lineIndex]);
    }
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
  final void Function(int lineIndex, String lineText) onLineTapped;
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

