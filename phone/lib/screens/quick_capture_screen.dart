import 'package:flutter/material.dart';

import '../services/capture_sync_service.dart';

/// Minimal capture form shown when Android share intent is received.
///
/// Pre-filled with shared text/URL. Fields: title, URL, notes, category.
/// On submit: saves to local Drift table (offline-first), then syncs to PA.
/// Navigation: pops with true on success.
class QuickCaptureScreen extends StatefulWidget {
  final String sharedText;
  final String? sharedUrl;
  final CaptureSyncService captureSyncService;

  const QuickCaptureScreen({
    super.key,
    required this.sharedText,
    this.sharedUrl,
    required this.captureSyncService,
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
      // Save to local Drift table (offline-first)
      await widget.captureSyncService.saveCapture(
        title: title.isEmpty ? (url.isEmpty ? 'Quick capture' : url) : title,
        url: url.isNotEmpty ? url : null,
        notes: notes.isNotEmpty ? notes : null,
        category: _category,
        sharedText: widget.sharedText,
      );

      // Trigger immediate sync to PA (best-effort — doesn't block UI)
      widget.captureSyncService.syncPendingCaptures().catchError((e) {
        debugPrint('[QuickCapture] Sync error: $e');
      });

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