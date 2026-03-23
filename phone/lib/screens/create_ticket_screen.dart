import 'package:flutter/material.dart';

import '../services/board_provider.dart';

/// Form for creating a new ticket.
///
/// On save, calls [boardProvider.client.createTicket] and pops back.
/// The parent should trigger [boardProvider.refresh] after the screen closes.
class CreateTicketScreen extends StatefulWidget {
  final BoardProvider boardProvider;

  const CreateTicketScreen({super.key, required this.boardProvider});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late String? _selectedProject;
  String _selectedType = 'task';
  String _selectedPriority = 'medium';
  String? _selectedEstimate;

  final _titleController = TextEditingController();
  final _teamController = TextEditingController();
  final _summaryController = TextEditingController();

  static const _types = [
    'feature',
    'bug',
    'task',
    'review-request',
    'work-report',
    'fyi',
    'idea',
    'question',
  ];
  static const _priorities = ['critical', 'high', 'medium', 'low'];
  static const _estimates = ['XS', 'S', 'M', 'L', 'XL'];

  @override
  void initState() {
    super.initState();
    _selectedProject = widget.boardProvider.selectedProject;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _teamController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'project': _selectedProject ?? '',
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'priority': _selectedPriority,
        'estimate': _selectedEstimate!,
      };
      final team = _teamController.text.trim();
      if (team.isNotEmpty) body['team'] = team;
      final summary = _summaryController.text.trim();
      if (summary.isNotEmpty) body['summary'] = summary;

      await widget.boardProvider.client.createTicket(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created')),
        );
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
        title: const Text('Create Ticket'),
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
            // Project — populated from API via boardProvider.projects
            Builder(builder: (context) {
              final projects = widget.boardProvider.projects;
              if (projects.isEmpty) {
                return const InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Project',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text('No projects'),
                );
              }
              // Ensure current selection is valid.
              final validKey = projects.any((p) => p.key == _selectedProject)
                  ? _selectedProject
                  : projects.first.key;
              return DropdownButtonFormField<String>(
                initialValue: validKey,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: projects
                    .map((p) => DropdownMenuItem(value: p.key, child: Text(p.key)))
                    .toList(),
                onChanged: (p) {
                  if (p != null) setState(() => _selectedProject = p);
                },
              );
            }),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (t) {
                if (t != null) setState(() => _selectedType = t);
              },
            ),
            const SizedBox(height: 16),

            // Team
            TextField(
              controller: _teamController,
              decoration: const InputDecoration(
                labelText: 'Team',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // Priority + Estimate row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _priorities
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (p) {
                      if (p != null) setState(() => _selectedPriority = p);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedEstimate,
                    decoration: const InputDecoration(
                      labelText: 'Estimate *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _estimates
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    validator: (v) =>
                        v == null ? 'Estimate is required' : null,
                    onChanged: (e) {
                      setState(() => _selectedEstimate = e);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
            TextFormField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: 'Summary',
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
                    : const Text('Create Ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
