import 'package:flutter/material.dart';

import '../services/board_provider.dart';

/// Form for creating a new bulletin.
///
/// On save, calls [boardProvider.client.createBulletin] and pops back.
/// The parent should trigger [boardProvider.refresh] after the screen closes.
class CreateBulletinScreen extends StatefulWidget {
  final BoardProvider boardProvider;

  const CreateBulletinScreen({super.key, required this.boardProvider});

  @override
  State<CreateBulletinScreen> createState() => _CreateBulletinScreenState();
}

class _CreateBulletinScreenState extends State<CreateBulletinScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool _blockAll = true; // true = all teams, false = specific teams

  final _titleController = TextEditingController();
  final _specificTeamsController = TextEditingController();
  final _exceptController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _specificTeamsController.dispose();
    _exceptController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dynamic block = _blockAll
          ? 'all'
          : _specificTeamsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      final exceptList = _exceptController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final body = <String, dynamic>{
        'title': _titleController.text.trim(),
        'block': block,
        if (exceptList.isNotEmpty) 'except': exceptList,
        if (_messageController.text.trim().isNotEmpty)
          'message': _messageController.text.trim(),
      };

      await widget.boardProvider.client.createBulletin(body);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Create failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bulletin'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save'),
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
                labelText: 'Title *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Block scope
            Text(
              'Block scope',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: true, label: Text('All teams')),
                ButtonSegment<bool>(
                    value: false, label: Text('Specific teams')),
              ],
              selected: {_blockAll},
              onSelectionChanged: (Set<bool> selection) {
                setState(() => _blockAll = selection.first);
              },
            ),
            if (!_blockAll) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _specificTeamsController,
                decoration: const InputDecoration(
                  labelText: 'Teams (comma-separated)',
                  hintText: 'e.g. builder, orchestrator',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => (!_blockAll &&
                        (v == null || v.trim().isEmpty))
                    ? 'Enter at least one team name'
                    : null,
              ),
            ],
            const SizedBox(height: 16),

            // Except
            TextFormField(
              controller: _exceptController,
              decoration: const InputDecoration(
                labelText: 'Except (comma-separated, optional)',
                hintText: 'e.g. sprint-master, daily',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // Message
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Bulletin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
