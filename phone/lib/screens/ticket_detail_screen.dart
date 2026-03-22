import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/deploy_routing.dart';
import '../models/deployment.dart';
import '../models/ticket.dart';
import '../services/board_provider.dart';
import '../widgets/deploy_sheet.dart';
import '../widgets/status_picker_sheet.dart';
import 'activity_timeline_screen.dart';

/// Full ticket detail view with read and edit modes.
///
/// Fetches the ticket by ID on init using [boardProvider.client].
/// In read mode, displays all ticket fields.
/// Toggle to edit mode via the AppBar edit icon to change status, priority,
/// team, assignee, estimate, and tags. Save calls [boardProvider.client.updateTicket].
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final BoardProvider boardProvider;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.boardProvider,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Ticket? _ticket;
  bool _loading = true;
  String? _error;
  bool _editMode = false;
  bool _saving = false;

  // Deploy state
  DeployRouting? _deployRouting;
  bool _fetchingRouting = false;

  // Edit state
  String _editStatus = '';
  String _editPriority = 'medium';
  String _editEstimate = 'S';
  List<String> _editTags = [];
  final _teamController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _tagInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _teamController.dispose();
    _assigneeController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ticket =
          await widget.boardProvider.client.getTicket(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
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

  void _initEditFields(Ticket ticket) {
    _editStatus = ticket.status;
    _editPriority = ticket.priority;
    _editEstimate = ticket.estimate ?? 'S';
    _teamController.text = ticket.team ?? '';
    _assigneeController.text = ticket.assignee ?? '';
    _editTags = List.from(ticket.tags);
  }

  void _toggleEditMode() {
    if (_ticket == null) return;
    setState(() {
      _editMode = !_editMode;
      if (_editMode) _initEditFields(_ticket!);
    });
  }

  Future<void> _save() async {
    if (_ticket == null) return;
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{
        'status': _editStatus,
        'priority': _editPriority,
        'estimate': _editEstimate,
        'tags': _editTags,
      };
      final team = _teamController.text.trim();
      final assignee = _assigneeController.text.trim();
      if (team.isNotEmpty) updates['team'] = team;
      if (assignee.isNotEmpty) updates['assignee'] = assignee;

      await widget.boardProvider.client.updateTicket(_ticket!.id, updates);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _onDeploy() async {
    if (_ticket == null) return;
    final ticket = _ticket!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final client = widget.boardProvider.client;

    // Fetch routing if not cached.
    if (_deployRouting == null) {
      setState(() => _fetchingRouting = true);
      try {
        final routing = await client.getDeployRouting();
        if (mounted) setState(() => _deployRouting = routing);
      } catch (e) {
        if (mounted) {
          setState(() => _fetchingRouting = false);
          messenger.showSnackBar(SnackBar(
            content: Text('Failed to load deploy routing: $e'),
            backgroundColor: errorColor,
          ));
        }
        return;
      }
      if (mounted) setState(() => _fetchingRouting = false);
    }

    if (!mounted) return;
    final routing = _deployRouting!;
    final paTeams = routing.toPaTeams();

    // Auto-suggest team from ticket.assignee.
    String? initialTeam;
    if (ticket.assignee != null &&
        paTeams.any((t) => t.name == ticket.assignee)) {
      initialTeam = ticket.assignee;
    }

    // Pre-fill objective as "{id}: {title}" and repo from project.
    final initialObjective = '${ticket.id}: ${ticket.title}';
    final initialRepo = ticket.project.isNotEmpty ? ticket.project : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DeploySheet(
        paTeams: paTeams,
        paRepos: routing.repos,
        initialTeam: initialTeam,
        initialObjective: initialObjective,
        initialRepo: initialRepo,
        onDeploy: (team, mode, objective, {repo}) async {
          Navigator.pop(context);
          try {
            final result = await client.triggerDeployment(
              team,
              mode,
              objective: objective.isNotEmpty ? objective : null,
              repo: repo,
              ticket: ticket.id,
            );
            if (mounted) {
              final deployment = Deployment(
                deploymentId: result.deploymentId,
                team: result.team,
                status: 'running',
                startedAt: DateTime.now().toIso8601String(),
              );
              messenger.showSnackBar(SnackBar(
                content: Text(
                  result.deploymentId.isNotEmpty
                      ? 'Deployed ${result.deploymentId}'
                      : 'Deployment started',
                ),
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ActivityTimelineScreen(
                          deployment: deployment,
                          client: client,
                        ),
                      ),
                    );
                  },
                ),
              ));
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(SnackBar(
                content: Text('Deploy failed: $e'),
                backgroundColor: errorColor,
              ));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket?.id ?? 'Ticket'),
        actions: [
          if (_ticket != null) ...[
            _fetchingRouting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.rocket_launch_outlined),
                    tooltip: 'Deploy agent',
                    onPressed: _editMode ? null : _onDeploy,
                  ),
            IconButton(
              icon: Icon(_editMode ? Icons.close : Icons.edit_outlined),
              tooltip: _editMode ? 'Cancel edit' : 'Edit',
              onPressed: _toggleEditMode,
            ),
            if (_editMode)
              _saving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Save',
                      onPressed: _save,
                    ),
          ],
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loadTicket, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_ticket == null) return const SizedBox.shrink();
    return _editMode ? _buildEditView(context) : _buildReadView(context);
  }

  Widget _buildReadView(BuildContext context) {
    final ticket = _ticket!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusChip(status: ticket.status),
              _PriorityChip(priority: ticket.priority),
              if (ticket.type != null) _InfoChip(label: ticket.type!),
              if (ticket.estimate != null)
                _InfoChip(label: ticket.estimate!),
            ],
          ),
          if (ticket.team != null || ticket.assignee != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (ticket.team != null) ...[
                  Icon(Icons.group_outlined,
                      size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(ticket.team!, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                ],
                if (ticket.assignee != null) ...[
                  Icon(Icons.person_outline,
                      size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(ticket.assignee!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ],
          if (ticket.summary != null && ticket.summary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Summary'),
            const SizedBox(height: 4),
            Text(ticket.summary!, style: theme.textTheme.bodyMedium),
          ],
          if (ticket.description != null &&
              ticket.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Description'),
            const SizedBox(height: 4),
            MarkdownBody(data: ticket.description!),
          ],
          if (ticket.docRef != null && ticket.docRef!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Doc Ref'),
            const SizedBox(height: 4),
            Text(
              ticket.docRef!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
          if (ticket.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Tags'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: ticket.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
          if (ticket.comments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Comments'),
            const SizedBox(height: 6),
            ...ticket.comments.map((c) => _CommentCard(comment: c)),
          ],
          const SizedBox(height: 16),
          Text(
            'Created ${_formatDate(ticket.createdAt)}'
            ' · Updated ${_formatDate(ticket.updatedAt)}'
            '${ticket.resolvedAt != null ? ' · Resolved ${_formatDate(ticket.resolvedAt!)}' : ''}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEditView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Status'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => StatusPickerSheet(
                currentStatus: _editStatus,
                onSelect: (s) {
                  Navigator.of(context).pop();
                  setState(() => _editStatus = s);
                },
              ),
            ),
            child: _StatusChip(status: _editStatus),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Priority'),
          const SizedBox(height: 6),
          DropdownButton<String>(
            value: _editPriority,
            isDense: true,
            items: ['critical', 'high', 'medium', 'low']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (p) {
              if (p != null) setState(() => _editPriority = p);
            },
          ),
          const SizedBox(height: 16),
          _SectionLabel('Estimate'),
          const SizedBox(height: 6),
          DropdownButton<String>(
            value: _editEstimate,
            isDense: true,
            items: ['XS', 'S', 'M', 'L', 'XL']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (e) {
              if (e != null) setState(() => _editEstimate = e);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _teamController,
            decoration: const InputDecoration(
              labelText: 'Team',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _assigneeController,
            decoration: const InputDecoration(
              labelText: 'Assignee',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Tags'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ..._editTags.map(
                (tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _editTags.remove(tag)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(
                width: 140,
                height: 36,
                child: TextField(
                  controller: _tagInputController,
                  decoration: const InputDecoration(
                    hintText: 'Add tag…',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onSubmitted: (tag) {
                    final trimmed = tag.trim();
                    if (trimmed.isNotEmpty && !_editTags.contains(trimmed)) {
                      setState(() => _editTags.add(trimmed));
                    }
                    _tagInputController.clear();
                  },
                ),
              ),
            ],
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
                  : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall
          ?.copyWith(color: theme.colorScheme.outline, letterSpacing: 0.5),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip({required this.priority});

  Color _color() {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final TicketComment comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    comment.author,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${comment.timestamp.year}-'
                  '${comment.timestamp.month.toString().padLeft(2, '0')}-'
                  '${comment.timestamp.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(comment.content, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
