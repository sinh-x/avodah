import 'package:flutter/material.dart';

import '../models/create_idea_payload.dart';
import '../services/agent_api_client.dart';

/// Form screen for creating a new idea in the `ideas/` folder (F17–F23).
///
/// All 8 fields match the `pa idea` CLI exactly:
/// title*, category, effort, what, why, who, notes, tags.
/// On submit, calls [AgentApiClient.createIdea] and pops with `true`.
class CreateIdeaScreen extends StatefulWidget {
  final AgentApiClient client;

  const CreateIdeaScreen({super.key, required this.client});

  @override
  State<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends State<CreateIdeaScreen> {
  static const _categories = [
    'personal',
    'work',
    'volunteer',
    'learning',
    'infra',
  ];
  static const _efforts = ['S', 'M', 'L', 'XL'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _whatController = TextEditingController();
  final _whyController = TextEditingController();
  final _whoController = TextEditingController(text: 'Sinh');
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  String _category = 'personal';
  String _effort = 'M';
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _whatController.dispose();
    _whyController.dispose();
    _whoController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text.trim().isEmpty
        ? <String>[]
        : _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

    final payload = CreateIdeaPayload(
      title: _titleController.text.trim(),
      category: _category,
      effort: _effort,
      what: _whatController.text.trim().isEmpty
          ? null
          : _whatController.text.trim(),
      why: _whyController.text.trim().isEmpty
          ? null
          : _whyController.text.trim(),
      who: _whoController.text.trim().isEmpty
          ? null
          : _whoController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      tags: tags,
    );

    setState(() => _submitting = true);
    try {
      await widget.client.createIdea(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Idea created')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create idea: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Idea')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title (required)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            // Category dropdown
            DropdownButtonFormField<String>(
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
            // Effort dropdown
            DropdownButtonFormField<String>(
              initialValue: _effort,
              decoration: const InputDecoration(
                labelText: 'Effort',
                border: OutlineInputBorder(),
              ),
              items: _efforts
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _effort = v!),
            ),
            const SizedBox(height: 16),
            // What (one-liner)
            TextField(
              controller: _whatController,
              decoration: const InputDecoration(
                labelText: 'What',
                hintText: 'One-liner description',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // Why
            TextField(
              controller: _whyController,
              decoration: const InputDecoration(
                labelText: 'Why',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // Who
            TextField(
              controller: _whoController,
              decoration: const InputDecoration(
                labelText: 'Who',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // Notes (multiline)
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // Tags (comma-separated)
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'tag1, tag2, ...',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
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
                    : const Text('Create Idea'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
