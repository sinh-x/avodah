import 'package:flutter/material.dart';

import '../config/document_type_config.dart';
import '../models/review_item.dart';

/// A color-coded badge chip showing the document type label.
///
/// Always shows the text label (e.g. "REPORT") alongside the color — never
/// color-only — to remain accessible (NF3).
///
/// Usage:
/// ```dart
/// DocumentTypeBadge(type: item.documentType)
/// ```
class DocumentTypeBadge extends StatelessWidget {
  final DocumentType type;

  /// Optional font size for the label text. Defaults to 11.
  final double fontSize;

  const DocumentTypeBadge({
    super.key,
    required this.type,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final config = kDocumentTypeConfigs[type];
    if (config == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: config.badgeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: config.badgeColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        config.badgeLabel,
        style: TextStyle(
          color: config.badgeColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
