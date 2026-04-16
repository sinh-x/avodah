import 'package:flutter/material.dart';

import '../models/create_idea_payload.dart';
import '../services/agent_api_client.dart';

/// Minimal capture form shown when Android share intent is received.
///
/// Pre-filled with shared text/URL. Fields: title, URL, notes, category.
/// On submit: calls createIdea() and stores locally in pending_captures.
/// Navigation: pops with true on success.
class QuickCaptureScreen extends StatefulWidget {
  final String sharedText;
  final String? sharedUrl;
  final AgentApiClient apiClient;

  const QuickCaptureScreen({
    super.key,
    required this.sharedText,
    this.sharedUrl,
    required this.apiClient,
  });

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  static const _categories = ['learning', 'personal', 'work', 'video', 'article'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _notesController;

  String _category = 'learning';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill URL if shared text is a URL, otherwise use as title
    final isUrl = _looksLikeUrl(widget.sharedText);
    _titleController = TextEditingController(
      text: isUrl ? '' : widget.sharedText,
    );
    _urlController = TextEditingController(
      text: widget.sharedUrl ?? (isUrl ? widget.sharedText : ''),
    );
    _notesController = TextEditingController(
      text: isUrl ? widget.sharedText : '',
    );
  }

  bool _looksLikeUrl(String text) {
    final trimmed = text.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    final notes = _notesController.text.trim();

    setState(() => _submitting = true);

    try {
      final payload = CreateIdeaPayload(
        title: title.isEmpty ? (url.isEmpty ? 'Quick capture' : url) : title,
        category: _category,
        notes: notes.isEmpty ? null : notes,
        tags: url.isNotEmpty ? ['shared-link'] : [],
      );

      // Include URL in notes if separate URL field has content
      await widget.apiClient.createIdea(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capture saved')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Capture'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Auto-filled from shared content',
                border: OutlineInputBorder(),
              ),
              autofocus: _titleController.text.isEmpty,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // URL
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional notes...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Capture'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}