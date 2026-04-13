import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ticket.dart';
import '../screens/document_viewer_screen.dart';
import '../screens/image_gallery_screen.dart';
import '../services/agent_api_client.dart';
import 'image_doc_ref_tile.dart';

/// Grouped doc_ref display widget for ticket detail.
///
/// Classifies [docRefs] into Images, Documents (markdown/PDF), and Links,
/// then renders each group under a section header.
class DocRefSection extends StatelessWidget {
  final List<DocRef> docRefs;
  final AgentApiClient client;
  final VoidCallback? onImagesChanged;

  const DocRefSection({
    super.key,
    required this.docRefs,
    required this.client,
    this.onImagesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final images = docRefs.where((r) => r.displayType == DocRefDisplayType.image).toList();
    final markdown = docRefs.where((r) => r.displayType == DocRefDisplayType.markdown || r.displayType == DocRefDisplayType.unknown).toList();
    final urls = docRefs.where((r) => r.displayType == DocRefDisplayType.url).toList();
    final pdfs = docRefs.where((r) => r.displayType == DocRefDisplayType.pdf).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          _SectionHeader(label: 'Images', count: images.length),
          const SizedBox(height: 8),
          _ImageGrid(
            images: images,
            client: client,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageGalleryScreen(
                    images: images,
                    initialIndex: index,
                    client: client,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        if (markdown.isNotEmpty) ...[
          _SectionHeader(label: 'Documents', count: markdown.length),
          const SizedBox(height: 4),
          ...markdown.map((ref) => _DocRefRow(
                docRef: ref,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentViewerScreen(
                      path: ref.path,
                      client: client,
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (urls.isNotEmpty) ...[
          _SectionHeader(label: 'Links', count: urls.length),
          const SizedBox(height: 4),
          ...urls.map((ref) => _UrlRow(docRef: ref)),
          const SizedBox(height: 16),
        ],
        if (pdfs.isNotEmpty) ...[
          _SectionHeader(label: 'PDFs', count: pdfs.length),
          const SizedBox(height: 4),
          ...pdfs.map((ref) => _PdfRow(docRef: ref)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<DocRef> images;
  final AgentApiClient client;
  final void Function(int index) onTap;

  const _ImageGrid({
    required this.images,
    required this.client,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < images.length; i++)
          ImageDocRefTile(
            docRef: images[i],
            client: client,
            onTap: () => onTap(i),
          ),
      ],
    );
  }
}

class _DocRefRow extends StatelessWidget {
  final DocRef docRef;
  final VoidCallback onTap;

  const _DocRefRow({required this.docRef, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _DocRefTypeBadge(type: docRef.type),
            const SizedBox(width: 8),
            if (docRef.primary) ...[
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                docRef.path,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlRow extends StatelessWidget {
  final DocRef docRef;

  const _UrlRow({required this.docRef});

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(docRef.path);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _launch(context),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _DocRefTypeBadge(type: docRef.type),
            const SizedBox(width: 8),
            if (docRef.primary) ...[
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.language, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                docRef.path,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfRow extends StatelessWidget {
  final DocRef docRef;

  const _PdfRow({required this.docRef});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _DocRefTypeBadge(type: docRef.type),
          const SizedBox(width: 8),
          if (docRef.primary) ...[
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.picture_as_pdf, size: 14, color: Colors.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              docRef.path,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'PDF viewer coming soon',
              style: TextStyle(fontSize: 10, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colored badge chip showing the doc ref type abbreviation.
class _DocRefTypeBadge extends StatelessWidget {
  final String type;

  const _DocRefTypeBadge({required this.type});

  String get _label {
    switch (type) {
      case 'requirements':
        return 'REQ';
      case 'implementation':
        return 'IMPL';
      case 'spike':
        return 'SPIKE';
      case 'review-report':
        return 'REVIEW';
      default:
        return 'ATTACH';
    }
  }

  Color get _color {
    switch (type) {
      case 'requirements':
        return Colors.indigo;
      case 'implementation':
        return Colors.green;
      case 'spike':
        return Colors.teal;
      case 'review-report':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
