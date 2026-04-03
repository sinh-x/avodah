import 'package:flutter/material.dart';

import '../config/ticket_type_config.dart';
import '../models/agent_team.dart';
import '../services/agent_api_client.dart';
import '../services/board_provider.dart';
import '../widgets/guided_summary_fields.dart';
import '../widgets/image_attachment_picker.dart';

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
  PhoneTicketType _selectedType = PhoneTicketType.task;
  String _selectedPriority = 'medium';
  String? _selectedEstimate;
  String _selectedStatus = 'requirement-review';

  final _titleController = TextEditingController();
  String? _selectedTeam;
  final _freeformSummaryController = TextEditingController();
  final GlobalKey<GuidedSummaryFieldsState> _guidedFieldsKey =
      GlobalKey<GuidedSummaryFieldsState>();
  final GlobalKey<ImageAttachmentPickerState> _imagePickerKey =
      GlobalKey<ImageAttachmentPickerState>();

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
    _freeformSummaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate guided fields
    final guidedState = _guidedFieldsKey.currentState;
    if (guidedState != null && !guidedState.validate()) return;

    setState(() => _saving = true);
    try {
      // Assemble summary from guided fields
      final guidedValues = guidedState?.getValues() ?? {};
      var assembledSummary = assembleSummary(_selectedType, guidedValues);

      // Append freeform notes if present
      final freeform = _freeformSummaryController.text.trim();
      if (freeform.isNotEmpty) {
        if (assembledSummary.isNotEmpty) {
          assembledSummary += '\n\n---\n$freeform';
        } else {
          assembledSummary = freeform;
        }
      }

      final body = <String, dynamic>{
        'project': _selectedProject ?? '',
        'title': _titleController.text.trim(),
        'type': _selectedType.name,
        'priority': _selectedPriority,
        'estimate': _selectedEstimate!,
        'doc_refs': [],
        'status': _selectedStatus,
      };
      if (_selectedTeam != null && _selectedTeam!.isNotEmpty) {
        body['team'] = _selectedTeam;
      }
      if (assembledSummary.isNotEmpty) {
        body['summary'] = assembledSummary;
      }

      // Create ticket first to get the ID
      final ticket = await widget.boardProvider.client.createTicket(body);
      final ticketId = ticket.id;

      // Upload images if any selected
      final imagePicker = _imagePickerKey.currentState;
      final selectedImages = imagePicker?.selectedImages ?? [];
      if (selectedImages.isNotEmpty) {
        imagePicker?.setUploading(true);
        try {
          final docRefs = await imagePicker!.widget.onUpload(selectedImages, ticketId);
          // Update ticket with attachment doc_refs
          if (docRefs.isNotEmpty) {
            await widget.boardProvider.client.updateTicket(ticketId, {
              'doc_refs': [...ticket.docRefs, ...docRefs],
            });
          }
        } finally {
          imagePicker?.setUploading(false);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        final msg = e is AgentApiException ? e.message : '$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Create failed: $msg')),
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
            _NoSelectTextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Type — tappable button that opens type picker bottom sheet
            _TypePickerButton(
              selectedType: _selectedType,
              onChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 16),

            // Status — backlog (idea) vs active (pending-implementation)
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'idea',
                  label: Text('Backlog'),
                  icon: Icon(Icons.inbox),
                ),
                ButtonSegment(
                  value: 'requirement-review',
                  label: Text('Req Review'),
                  icon: Icon(Icons.rate_review),
                ),
                ButtonSegment(
                  value: 'pending-implementation',
                  label: Text('Active'),
                  icon: Icon(Icons.play_arrow),
                ),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (s) =>
                  setState(() => _selectedStatus = s.first),
            ),
            const SizedBox(height: 16),

            // Team — dropdown populated from API
            FutureBuilder<List<AgentTeam>>(
              future: widget.boardProvider.client.listAgentTeams(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Team',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading teams…'),
                      ],
                    ),
                  );
                }
                final teams = snapshot.data ?? [];
                final items = <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...teams.map((t) => DropdownMenuItem<String?>(
                        value: t.name,
                        child: Text(t.name),
                      )),
                ];
                return DropdownButtonFormField<String?>(
                  initialValue: _selectedTeam,
                  decoration: const InputDecoration(
                    labelText: 'Team',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: items,
                  onChanged: (v) => setState(() => _selectedTeam = v),
                );
              },
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

            // Guided summary fields based on selected type
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guided Summary',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    GuidedSummaryFields(
                      key: _guidedFieldsKey,
                      selectedType: _selectedType,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Image attachments
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ImageAttachmentPicker(
                      key: _imagePickerKey,
                      onUpload: (images, ticketId) async {
                        final docRefs = <String>[];
                        final picker = _imagePickerKey.currentState!;
                        for (var i = 0; i < images.length; i++) {
                          picker.setUploadProgress((i + 0.5) / images.length);
                          final docRef = await widget.boardProvider.client
                              .uploadAttachment(ticketId, images[i]);
                          docRefs.add(docRef);
                        }
                        picker.setUploadProgress(1.0);
                        return docRefs;
                      },
                      onUploadingChanged: (uploading) {
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Freeform additional notes
            _NoSelectTextField(
              controller: _freeformSummaryController,
              decoration: const InputDecoration(
                labelText: 'Additional notes (optional)',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Any extra context or freeform notes...',
              ),
              maxLines: 2,
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

/// Tappable button that opens a bottom sheet with the type picker.
class _TypePickerButton extends StatelessWidget {
  final PhoneTicketType selectedType;
  final ValueChanged<PhoneTicketType> onChanged;

  const _TypePickerButton({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final config = kTicketTypeConfigs[selectedType]!;

    return InkWell(
      onTap: () => _showTypePicker(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Type',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: Row(
          children: [
            Icon(config.icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    config.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TypePickerSheet(
        selectedType: selectedType,
        onChanged: (type) {
          onChanged(type);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

/// Bottom sheet content for type picker.
class _TypePickerSheet extends StatelessWidget {
  final PhoneTicketType selectedType;
  final ValueChanged<PhoneTicketType> onChanged;

  const _TypePickerSheet({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select Type',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            ...PhoneTicketType.values.map((type) {
              final config = kTicketTypeConfigs[type]!;
              final isSelected = type == selectedType;

              return ListTile(
                leading: Icon(
                  config.icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(
                  config.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
                subtitle: Text(config.description),
                selected: isSelected,
                selectedTileColor:
                    Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                onTap: () => onChanged(type),
              );
            }),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Show all types'),
              subtitle: const Text('Includes agent types (review-request, work-report, fyi)'),
              dense: true,
              onTap: () {
                Navigator.of(context).pop();
                _showAllTypesPicker(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAllTypesPicker(BuildContext context) {
    // Fallback: show original flat dropdown of all 8 types
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'All Types',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              ...['feature', 'bug', 'task', 'review-request', 'work-report', 'fyi', 'idea', 'question']
                  .map((t) => ListTile(
                        title: Text(t),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          // Map back to PhoneTicketType if possible
                          final mapped = PhoneTicketType.values.where((p) => p.name == t).firstOrNull;
                          if (mapped != null) {
                            onChanged(mapped);
                          }
                        },
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

/// A TextField that places cursor at tap position on single tap,
/// without selecting text. Preserves double-tap word selection.
///
/// Works around flutter/flutter#98720, #105185 where single taps in
/// TextFields can unexpectedly select words instead of placing cursor.
class _NoSelectTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;

  const _NoSelectTextField({
    required this.controller,
    this.decoration,
    this.maxLines,
    this.onChanged,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.validator,
  });

  @override
  State<_NoSelectTextField> createState() => _NoSelectTextFieldState();
}

class _NoSelectTextFieldState extends State<_NoSelectTextField> {
  Offset? _tapPosition;

  void _handleTapDown(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _handleTap() {
    if (_tapPosition == null) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(_tapPosition!);

    final textPainter = TextPainter(
      text: TextSpan(text: widget.controller.text),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: renderBox.size.width);

    final textPosition = textPainter.getPositionForOffset(localPosition);
    widget.controller.selection = TextSelection.collapsed(
      offset: textPosition.offset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: TextFormField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        textCapitalization: widget.textCapitalization,
        validator: widget.validator,
      ),
    );
  }
}
