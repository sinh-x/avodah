import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../services/agent_api_client.dart';

/// Full-screen document viewer.
///
/// Fetches the document at [path] via [AgentApiClient.getDocument] and renders
/// it based on file type: markdown (.md/.markdown) → [MarkdownBody], PDF →
/// [PDFView] (Android/iOS) or fallback message (other platforms), image →
/// placeholder, directory → entry list. Shows a loading indicator while
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
      if (_isPdf) {
        await _loadPdfToTempFile();
        return;
      }
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

  /// Downloads the PDF to a temp file for [PDFView].
  ///
  /// On non-Android/iOS platforms (e.g. Linux desktop testing), no download
  /// is performed — the viewer falls back to a platform-unsupported message.
  Future<void> _loadPdfToTempFile() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final url =
        '${widget.client.baseUrl}/api/documents?path=${Uri.encodeComponent(widget.path)}';
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$_filename');
    await file.writeAsBytes(response.bodyBytes);
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
      return _buildImagePlaceholder();
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

  Widget _buildImagePlaceholder() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image, size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text('Image preview not yet available',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_filename, style: theme.textTheme.bodySmall),
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
