import 'package:flutter/material.dart';

import '../services/agent_api_client.dart';
import '../widgets/inline_comment_sheet.dart';
import '../widgets/markdown_with_annotations.dart';

/// Full-screen document viewer.
///
/// Fetches the document at [path] via [AgentApiClient.getDocument] and renders
/// it based on file type: markdown (.md/.markdown) → [MarkdownWithAnnotations],
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
  String _selectedText = '';
  final _scrollController = ScrollController();

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

  void _showCommentSheet(String selectedText) {
    if (selectedText.isEmpty) return;

    final lines = _document?.content?.split('\n') ?? [];

    List<int> matchingLineIndices = [];

    // Try exact match first
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(selectedText)) {
        matchingLineIndices.add(i);
      }
    }

    // If no exact match, try partial word match
    if (matchingLineIndices.isEmpty) {
      final words = selectedText.split(' ').where((w) => w.length > 3).toList();
      for (int i = 0; i < lines.length; i++) {
        for (final word in words) {
          if (lines[i].toLowerCase().contains(word.toLowerCase())) {
            matchingLineIndices.add(i);
            break;
          }
        }
      }
    }

    // If still no match, use first non-empty line
    if (matchingLineIndices.isEmpty) {
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) {
          matchingLineIndices.add(i);
          break;
        }
      }
    }

    // If still empty, can't determine line - abort
    if (matchingLineIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find line for comment')),
      );
      setState(() {
        _selectedText = '';
      });
      return;
    }

    // Use LAST match (user likely selected text near where they want to comment)
    final lineIndex = matchingLineIndices.last;
    setState(() {
      _selectedText = '';
    });
    _onLineTapped(lineIndex, selectedText);
  }

  void _onLineTapped(int lineIndex, String selectedText) {
    final lines = _document?.content?.split('\n') ?? [];
    final surroundingText =
        lineIndex > 0 ? lines[lineIndex - 1] : (lineIndex < lines.length - 1 ? lines[lineIndex + 1] : null);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InlineCommentSheet(
        contextText: selectedText,
        surroundingText: surroundingText,
        onSubmit: (comment) => _submitInlineComment(selectedText, comment),
      ),
    );
  }

  Future<void> _submitInlineComment(String selectedText, String comment) async {
    final scrollOffset = _scrollController.offset;
    try {
      await widget.client.appendInlineSection(widget.path, selectedText, comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added')),
        );
        _loadDocument();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(scrollOffset);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  void _onAddSection() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _AddSectionDialog(),
    );

    if (result == null || !mounted) return;

    try {
      await widget.client.appendSection(
        widget.path,
        result['title']!,
        result['content']!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section added')),
        );
        _loadDocument(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add section: $e')),
        );
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
        actions: [
          if (_selectedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.comment),
              tooltip: 'Add Comment',
              onPressed: () => _showCommentSheet(_selectedText),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: _selectedText.isNotEmpty ? 'Add Comment' : 'Add Section',
            onPressed: _selectedText.isNotEmpty
                ? () => _showCommentSheet(_selectedText)
                : _onAddSection,
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected text indicator
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
                ],
              ),
            ),
          ),
        // Markdown content with long press to select
        Expanded(
          child: SelectionArea(
            onSelectionChanged: (selection) {
              if (selection != null && selection.plainText.isNotEmpty) {
                setState(() {
                  _selectedText = selection.plainText;
                });
              }
            },
            child: MarkdownWithAnnotations(
              data: content,
              controller: _scrollController,
              onLineTapped: _onLineTapped,
            ),
          ),
        ),
      ],
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _AddSectionDialog extends StatefulWidget {
  const _AddSectionDialog();

  @override
  State<_AddSectionDialog> createState() => _AddSectionDialogState();
}

class _AddSectionDialogState extends State<_AddSectionDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool get _canAdd =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Section'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Section title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. "Follow-up Notes"',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const Text('Section content'),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Enter markdown content...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canAdd
              ? () => Navigator.pop(context, {
                    'title': _titleController.text.trim(),
                    'content': _contentController.text.trim(),
                  })
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
