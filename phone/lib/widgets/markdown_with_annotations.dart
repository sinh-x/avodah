import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/display_settings_service.dart';
import '../utils/syntax_highlight.dart';

/// GFM alert type detected in blockquote text content.
enum _GfmAlertType {
  note,
  tip,
  important,
  warning,
  caution,
}

/// A markdown widget with tap detection for inline commenting and
/// annotation marker rendering.
///
/// Wraps [Markdown] to detect taps on individual lines/paragraphs and
/// renders GFM alert blockquotes ([!NOTE], [!TIP], etc.) as visually
/// distinct styled blocks with per-type icon and color.
class MarkdownWithAnnotations extends StatelessWidget {
  /// The markdown content to render.
  final String data;

  /// Called when the user taps a line or paragraph of rendered markdown.
  /// Passes the 0-based line index and the tapped text.
  final void Function(int lineIndex, String tappedText) onLineTapped;

  /// Optional style for annotation markers. Falls back to default amber
  /// blockquote styling.
  final MarkdownStyleSheet? styleSheet;

  /// Optional scroll controller for preserving scroll position.
  final ScrollController? controller;

  const MarkdownWithAnnotations({
    super.key,
    required this.data,
    required this.onLineTapped,
    this.styleSheet,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyleSheet = theme.textTheme.bodyMedium?.merge(
      const TextStyle(height: 1.5),
    );

    return Markdown(
      data: data,
      shrinkWrap: false,
      controller: controller,
      styleSheet: styleSheet ?? _buildAnnotationStyleSheet(context, defaultStyleSheet),
      builders: {
        'blockquote': _GfmAlertBlockquoteBuilder(
          onLineTapped: onLineTapped,
          sourceLines: data.split('\n'),
        ),
        'code': _CodeBlockBuilder(syntaxColors: theme.syntaxColors),
      },
      onTapLink: (text, href, title) {
        // Allow link taps to open URLs
      },
    );
  }

  MarkdownStyleSheet _buildAnnotationStyleSheet(
    BuildContext context,
    TextStyle? baseStyle,
  ) {
    final theme = Theme.of(context);
    const amberAccent = Color(0xFFFFC107);
    // Use more saturated amber background in high contrast mode
    final isHighContrast = theme.syntaxColors.isHighContrast;
    final amberLight = isHighContrast ? Colors.amber.shade100 : Colors.amber.shade50;

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
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: baseStyle?.fontSize ?? 14,
        color: theme.colorScheme.onSurface,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Pattern to detect GFM alert syntax: [!TYPE] body
final _gfmAlertPattern = RegExp(
  r'^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*(.*)',
  multiLine: true,
  dotAll: true,
);

/// Pattern to detect Sinh comments: [!NOTE] Sinh comment: body
final _sinhCommentPattern = RegExp(r'^Sinh comment:\s*(.*)', multiLine: true);

/// Custom builder for blockquote elements that detects GFM alert syntax
/// ([!NOTE], [!TIP], [!IMPORTANT], [!WARNING], [!CAUTION]) and renders them
/// with per-type icon and color styling.
class _GfmAlertBlockquoteBuilder extends MarkdownElementBuilder {
  final void Function(int lineIndex, String tappedText) onLineTapped;
  final List<String> sourceLines;

  _GfmAlertBlockquoteBuilder({
    required this.onLineTapped,
    required this.sourceLines,
  });

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final textContent = element.textContent;

    // Try to match GFM alert syntax
    final alertMatch = _gfmAlertPattern.firstMatch(textContent);
    if (alertMatch == null) {
      // Regular blockquote — return null to use default styling
      return null;
    }

    final alertTypeStr = alertMatch.group(1)!;
    final body = alertMatch.group(2) ?? '';

    // Check if this is a Sinh comment (special amber styling)
    if (alertTypeStr == 'NOTE') {
      final sinhMatch = _sinhCommentPattern.firstMatch(body);
      if (sinhMatch != null) {
        return _buildSinhComment(sinhMatch.group(1)!, preferredStyle);
      }
    }

    // Map string to enum
    final alertType = switch (alertTypeStr) {
      'NOTE' => _GfmAlertType.note,
      'TIP' => _GfmAlertType.tip,
      'IMPORTANT' => _GfmAlertType.important,
      'WARNING' => _GfmAlertType.warning,
      'CAUTION' => _GfmAlertType.caution,
      _ => null,
    };

    if (alertType == null) return null;

    return _buildGfmAlert(alertType, body, preferredStyle);
  }

  Widget _buildGfmAlert(
    _GfmAlertType type,
    String body,
    TextStyle? preferredStyle,
  ) {
    final (icon, iconColor, bgColor, borderColor, label) = switch (type) {
      _GfmAlertType.note => (
          Icons.info_outline,
          Colors.blue.shade700,
          Colors.blue.shade50,
          Colors.blue.shade400,
          'Note',
        ),
      _GfmAlertType.tip => (
          Icons.lightbulb_outline,
          Colors.green.shade700,
          Colors.green.shade50,
          Colors.green.shade400,
          'Tip',
        ),
      _GfmAlertType.important => (
          Icons.priority_high,
          Colors.purple.shade700,
          Colors.purple.shade50,
          Colors.purple.shade400,
          'Important',
        ),
      _GfmAlertType.warning => (
          Icons.warning_amber,
          Colors.orange.shade700,
          Colors.orange.shade50,
          Colors.orange.shade400,
          'Warning',
        ),
      _GfmAlertType.caution => (
          Icons.dangerous,
          Colors.red.shade700,
          Colors.red.shade50,
          Colors.red.shade400,
          'Caution',
        ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(
        left: 12,
        top: 8,
        bottom: 8,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              body,
              style: preferredStyle?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinhComment(String body, TextStyle? preferredStyle) {
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
              body,
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

/// Custom builder for code block elements that applies syntax highlighting
/// using SyntaxColors and responds to high contrast settings.
class _CodeBlockBuilder extends MarkdownElementBuilder {
  final SyntaxColors syntaxColors;

  _CodeBlockBuilder({required this.syntaxColors});

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    // Extract language from class attribute (e.g., 'language-dart' -> 'dart')
    final classAttr = element.attributes['class'];
    String? language;
    if (classAttr != null && classAttr.startsWith('language-')) {
      language = classAttr.substring('language-'.length);
    }

    final code = element.textContent;
    if (code.isEmpty) {
      return null;
    }

    // Use the RichText approach from diff_widgets.dart for syntax highlighting
    return RichText(
      text: TextSpan(
        style: preferredStyle?.copyWith(
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        children: parseSyntaxHighlighted(code, language, syntaxColors),
      ),
    );
  }
}