import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

import '../services/agent_api_client.dart';

/// Full-screen document viewer.
///
/// Fetches the document at [path] via [AgentApiClient.getDocument] and renders
/// it based on file type: markdown (.md/.markdown) → [MarkdownBody], PDF →
/// [PDFView] (Android/iOS) or fallback message (other platforms), image →
/// [Image.memory], directory → entry list. Shows a loading indicator while
/// fetching and an error state with retry button on failure.
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
  String? _pdfTempPath;

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

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _cleanupTempFile();
    super.dispose();
  }

  void _cleanupTempFile() {
    final path = _pdfTempPath;
    if (path != null) {
      File(path).delete().ignore();
    }
  }

  Future<void> _loadDocument() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await widget.client.getDocument(widget.path);
      if (_isPdf && (Platform.isAndroid || Platform.isIOS)) {
        await _writeBinaryToTempFile(doc);
      } else {
        if (mounted) {
          setState(() {
            _document = doc;
            _loading = false;
          });
        }
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

  /// Writes binary content from [DocumentContent] to a temp file for PDF
  /// viewing. Uses latin1 encoding to preserve byte values from the JSON
  /// string (best-effort until PA adds a raw binary endpoint — see PA-902).
  Future<void> _writeBinaryToTempFile(DocumentContent doc) async {
    final content = doc.content;
    if (content == null || content.isEmpty) {
      throw Exception('No content returned for PDF');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$_filename');
    await file.writeAsBytes(latin1.encode(content));
    if (mounted) {
      setState(() {
        _pdfTempPath = file.path;
        _loading = false;
      });
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
    if (_isPdf) {
      return _buildPdfViewer();
    }
    final doc = _document!;
    if (doc.type == 'directory') {
      return _buildDirectoryListing(doc);
    }
    if (_isImage) {
      return _buildImageViewer(doc);
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

  Widget _buildPdfViewer() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _buildPdfDesktopFallback();
    }
    if (_pdfTempPath == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PDFView(
      filePath: _pdfTempPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: true,
    );
  }

  Widget _buildPdfDesktopFallback() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf,
              size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text('PDF viewing not supported on this platform',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_filename, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  /// Renders image from the API content string using latin1 byte decoding.
  /// Best-effort until PA adds a raw binary endpoint (PA-902).
  Widget _buildImageViewer(DocumentContent doc) {
    final content = doc.content;
    if (content == null || content.isEmpty) {
      return _buildImageError('No image content returned');
    }
    try {
      final bytes = latin1.encode(content);
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, error, _) =>
                _buildImageError(error.toString()),
          ),
        ),
      );
    } catch (e) {
      return _buildImageError(e.toString());
    }
  }

  Widget _buildImageError(String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load image', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(_filename,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
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
