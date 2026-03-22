import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/agent_api_client.dart';

/// Full-screen document viewer.
///
/// Fetches the document at [path] via [AgentApiClient.getDocument] and renders
/// it based on file type: markdown (.md/.markdown) → [MarkdownBody],
/// directory → entry list. PDF and image viewing require a raw binary API
/// endpoint (PA-902) and show an informative placeholder until then.
class DocumentViewerScreen extends StatefulWidget {
  final String path;
  final AgentApiClient client;

  const DocumentViewerScreen({
    super.key,
    required this.path,
    required this.client,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  DocumentContent? _document;
  bool _loading = true;
  String? _error;

  String get _filename {
    final parts = widget.path.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => widget.path);
  }

  String get _extension {
    final dotIdx = _filename.lastIndexOf('.');
    if (dotIdx < 0) return '';
    return _filename.substring(dotIdx).toLowerCase();
  }

  bool get _isPdf => _extension == '.pdf';
  bool get _isImage {
    const imageExts = {'.png', '.jpg', '.jpeg', '.gif', '.webp'};
    return imageExts.contains(_extension);
  }

  bool get _isBinary => _isPdf || _isImage;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    // Binary files can't be served correctly through the JSON API — skip fetch.
    if (_isBinary) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await widget.client.getDocument(widget.path);
      if (mounted) {
        setState(() {
          _document = doc;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load document', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadDocument,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isPdf) return _buildBinaryPlaceholder(Icons.picture_as_pdf, 'PDF');
    if (_isImage) return _buildBinaryPlaceholder(Icons.image, 'Image');

    final doc = _document!;
    if (doc.type == 'directory') {
      return _buildDirectoryListing(doc);
    }
    return _buildMarkdown(doc.content ?? '');
  }

  Widget _buildMarkdown(String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(
        data: content,
        selectable: true,
      ),
    );
  }

  Widget _buildBinaryPlaceholder(IconData icon, String typeLabel) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text('$typeLabel preview not available',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_filename, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Text(
            'Requires raw binary API endpoint (PA-902)',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryListing(DocumentContent doc) {
    final entries = doc.entries ?? [];
    if (entries.isEmpty) {
      return Center(
        child: Text('Empty directory',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final entryPath = '${widget.path}/$entry';
        return ListTile(
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(entry),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentViewerScreen(
                path: entryPath,
                client: widget.client,
              ),
            ),
          ),
        );
      },
    );
  }
}
