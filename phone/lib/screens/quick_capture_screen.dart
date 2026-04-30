import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ticket.dart';
import '../services/agent_api_client.dart';
import '../services/capture_sync_service.dart';
import '../services/title_extraction_service.dart';
import '../utils/category_detection.dart';
import '../utils/url_utils.dart';

/// Minimal capture form shown when Android share intent is received.
///
/// Pre-filled with shared text/URL. Fields: title, URL, notes, category.
/// On submit: saves to local Drift table (offline-first), then syncs to PA.
/// Navigation: pops with true on success.
class QuickCaptureScreen extends StatefulWidget {
  final String sharedText;
  final String? sharedUrl;
  final CaptureSyncService captureSyncService;
  final AgentApiClient apiClient;

  const QuickCaptureScreen({
    super.key,
    required this.sharedText,
    this.sharedUrl,
    required this.captureSyncService,
    required this.apiClient,
  });

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  static const _categories = [
    'learning',
    'personal',
    'work',
    'video',
    'article',
    'code',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _notesController;

  String _category = 'learning';
  String _project = 'learning';
  List<TicketProject> _projects = [];
  bool _loadingProjects = false;
  bool _submitting = false;
  bool _fetchingTitle = false;
  Timer? _debounceTimer;

  late final TitleExtractionService _titleService;

  @override
  void initState() {
    super.initState();
    _titleService = TitleExtractionService();
    _loadProjects();

    // Pre-fill URL if shared text is a URL, otherwise use as title.
    // extractUrl handles both scheme URLs and scheme-less (e.g., news.google.com/...)
    final extractedUrl = extractUrl(widget.sharedText);
    final hasUrl = extractedUrl != null;
    _titleController = TextEditingController(
      text: hasUrl ? '' : widget.sharedText,
    );
    _urlController = TextEditingController(
      text: widget.sharedUrl ?? extractedUrl ?? '',
    );
    _notesController = TextEditingController(text: widget.sharedText);

    // Trigger title extraction if URL is pre-filled
    if (hasUrl) {
      final prefillUrl = widget.sharedUrl ?? extractedUrl;
      _fetchTitleForUrl(prefillUrl);
      // Auto-detect category from domain
      final detected = detectCategoryFromUrl(prefillUrl);
      if (detected != 'learning') {
        _category = detected;
      }
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final projects = await widget.apiClient.getProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _loadingProjects = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // Keep default LM only on error
          _projects = [];
          _loadingProjects = false;
        });
      }
    }
  }

  Future<void> _fetchTitleForUrl(String url) async {
    if (url.isEmpty) return;

    setState(() => _fetchingTitle = true);

    final title = await _titleService.fetchTitle(url);

    if (mounted && title != null) {
      // Only pre-fill if title field is still empty (user hasn't edited it)
      if (_titleController.text.isEmpty) {
        _titleController.text = title;
      }
    }

    if (mounted) {
      setState(() => _fetchingTitle = false);
    }
  }

  void _onUrlChanged(String value) {
    // Debounce URL changes to avoid excessive fetches
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (isUrl(value)) {
        _fetchTitleForUrl(value);
        // Auto-detect category from domain (only override default 'learning')
        if (_category == 'learning') {
          final detected = detectCategoryFromUrl(value);
          if (detected != 'learning') {
            setState(() => _category = detected);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
        project: _project,
      );

      // Trigger immediate sync to PA (best-effort — doesn't block UI)
      widget.captureSyncService.syncPendingCaptures().catchError((e) {
        debugPrint('[QuickCapture] Sync error: $e');
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Capture saved')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
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
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Auto-filled from shared content',
                border: const OutlineInputBorder(),
                suffixIcon: _fetchingTitle
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              autofocus: _titleController.text.isEmpty,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Project
            if (_loadingProjects)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                key: ValueKey(_project),
                value: _project,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                ),
                items: _projects.isEmpty
                    ? [
                        const DropdownMenuItem(
                          value: 'learning',
                          child: Text('learning'),
                        ),
                      ]
                    : _projects
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.key,
                              child: Text(p.key),
                            ),
                          )
                          .toList(),
                onChanged: (v) => setState(() => _project = v ?? 'learning'),
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
              onChanged: _onUrlChanged,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              key: ValueKey(_category),
              initialValue: _category,
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
