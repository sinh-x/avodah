import 'package:flutter/material.dart';

import '../models/ticket.dart';
import '../services/backlog_provider.dart';
import '../services/kanban_constants.dart';
import '../widgets/assignee_picker_sheet.dart';
import '../widgets/priority_picker_sheet.dart';
import '../widgets/status_picker_sheet.dart';
import '../widgets/tag_picker_sheet.dart';

/// Backlog view — shows all inactive tickets (tag-based + status-based).
///
/// Displays a virtual scrolling list of tickets with filter controls,
/// multi-select checkboxes, bulk action bar, pull-to-refresh, and
/// tap-to-activate interaction.
class BacklogScreen extends StatefulWidget {
  final BacklogProvider backlogProvider;

  const BacklogScreen({
    super.key,
    required this.backlogProvider,
  });

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch backlog on first load if not yet loaded
    if (widget.backlogProvider.allTickets.isEmpty &&
        !widget.backlogProvider.loading) {
      widget.backlogProvider.fetchBacklog();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Filter row (mirrors KanbanBoardScreen._buildFilterRow) ---

  Widget _buildFilterRow(List<TicketProject> projects) {
    final provider = widget.backlogProvider;
    final assignees = _uniqueAssignees(provider.allTickets);
    final priorities = ['critical', 'high', 'medium', 'low'];
    final allTags = _uniqueTags(provider.allTickets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Project dropdown
              if (projects.isEmpty)
                const Text('No projects')
              else
                DropdownButton<String>(
                  value: provider.filter.project != null &&
                          projects.any((p) => p.key == provider.filter.project)
                      ? provider.filter.project
                      : null,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  hint: const Text('All projects'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All projects')),
                    ...projects.map(
                      (p) => DropdownMenuItem(value: p.key, child: Text(p.key)),
                    ),
                  ],
                  onChanged: (p) => provider.setProject(p),
                ),

              // Assignee chips
              if (assignees.isNotEmpty) ...[
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('All'),
                  selected: provider.filter.assignees.isEmpty,
                  onSelected: (_) => provider.setAssignees([]),
                ),
                ...assignees.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(a),
                      selected: provider.filter.assignees.contains(a),
                      onSelected: (_) {
                        final current = List<String>.from(provider.filter.assignees);
                        if (current.contains(a)) {
                          current.remove(a);
                        } else {
                          current.add(a);
                        }
                        provider.setAssignees(current);
                      },
                    ),
                  ),
                ),
              ],

              // Priority chips
              if (priorities.isNotEmpty) ...[
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('All'),
                  selected: provider.filter.priorities.isEmpty,
                  onSelected: (_) => provider.setPriorities([]),
                ),
                ...priorities.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(p),
                      selected: provider.filter.priorities.contains(p),
                      onSelected: (_) {
                        final current = List<String>.from(provider.filter.priorities);
                        if (current.contains(p)) {
                          current.remove(p);
                        } else {
                          current.add(p);
                        }
                        provider.setPriorities(current);
                      },
                    ),
                  ),
                ),
              ],

              // Tag chips
              if (allTags.isNotEmpty) ...[
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('All'),
                  selected: provider.filter.tags.isEmpty,
                  onSelected: (_) => provider.setTags([]),
                ),
                ...allTags.take(6).map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(t),
                      selected: provider.filter.tags.contains(t),
                      onSelected: (_) {
                        final current = List<String>.from(provider.filter.tags);
                        if (current.contains(t)) {
                          current.remove(t);
                        } else {
                          current.add(t);
                        }
                        provider.setTags(current);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => provider.setSearchQuery(v),
            decoration: InputDecoration(
              hintText: 'Search backlog tickets…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: provider.filter.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  // --- Ticket list with virtual scrolling ---

  Widget _buildTicketList() {
    return ListView.builder(
      itemCount: widget.backlogProvider.tickets.length,
      itemBuilder: (context, index) {
        final ticket = widget.backlogProvider.tickets[index];
        final isSelected =
            widget.backlogProvider.selectedIds.contains(ticket.id);

        return _BacklogTicketTile(
          ticket: ticket,
          isSelected: isSelected,
          onToggleSelect: () => widget.backlogProvider.toggleTicket(ticket.id),
          onTap: () => _showActivateDialog(context, ticket),
        );
      },
    );
  }

  // --- Activate dialog (inline sheet) ---

  Future<void> _showActivateDialog(BuildContext context, Ticket ticket) async {
    String? selectedStatus;
    // Default to 'implementing' (active status) if in backlog, otherwise keep current
    selectedStatus = backlogStatuses.contains(ticket.status) ? 'implementing' : ticket.status;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Activate Ticket',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  ticket.id,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.outline,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  ticket.title,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ticket.tags.contains('backlog')) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'The "backlog" tag will be removed',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'New Status',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
              ),
              SizedBox(
                height: 240,
                child: StatusPickerSheet(
                  currentStatus: selectedStatus ?? ticket.status,
                  onSelect: (status) {
                    setSheetState(() => selectedStatus = status);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: selectedStatus != null
                            ? () => Navigator.pop(ctx, selectedStatus)
                            : null,
                        child: const Text('Activate'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await _activateTicket(context, ticket, result);
    }
  }

  Future<void> _activateTicket(
      BuildContext context, Ticket ticket, String newStatus) async {
    try {
      await widget.backlogProvider.activateTicket(ticket.id, newStatus);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ticket.id} activated as ${statusLabel(newStatus)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate ${ticket.id}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // --- Bulk action bar ---

  Widget _buildBulkActionBar() {
    final provider = widget.backlogProvider;
    if (!provider.hasSelection) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '${provider.selectionCount} selected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            // Status picker
            TextButton.icon(
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Status'),
              onPressed: () => _showBulkStatusPicker(context),
            ),
            // Priority picker
            TextButton.icon(
              icon: const Icon(Icons.priority_high_outlined, size: 18),
              label: const Text('Priority'),
              onPressed: () => _showBulkPriorityPicker(context),
            ),
            // Assignee picker
            TextButton.icon(
              icon: const Icon(Icons.group_outlined, size: 18),
              label: const Text('Assignee'),
              onPressed: () => _showBulkAssigneePicker(context),
            ),
            // Tags picker
            TextButton.icon(
              icon: const Icon(Icons.label_outlined, size: 18),
              label: const Text('Tags'),
              onPressed: () => _showBulkTagsPicker(context),
            ),
            // Apply button
            FilledButton(
              onPressed: () => _applyBulkUpdate(context),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBulkStatusPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: StatusPickerSheet(
          currentStatus: 'idea',
          onSelect: (status) => Navigator.pop(ctx, status),
        ),
      ),
    );
    if (result != null && context.mounted) {
      await _bulkUpdate(context, {'status': result});
    }
  }

  Future<void> _showBulkPriorityPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: PriorityPickerSheet(
          currentPriority: 'medium',
          onSelect: (priority) => Navigator.pop(ctx, priority),
        ),
      ),
    );
    if (result != null && context.mounted) {
      await _bulkUpdate(context, {'priority': result});
    }
  }

  Future<void> _showBulkAssigneePicker(BuildContext context) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: AssigneePickerSheet(
          client: widget.backlogProvider.client,
          currentAssignee: null,
          onSelect: (assignee) => Navigator.pop(ctx, assignee),
        ),
      ),
    );
    if (result != null && context.mounted) {
      await _bulkUpdate(context, {'assignee': result});
    }
  }

  Future<void> _showBulkTagsPicker(BuildContext context) async {
    final allTags = _uniqueTags(widget.backlogProvider.allTickets);
    final selectedTags = <String>[];

    // Pre-select tags that all selected tickets share
    final selectedTickets = widget.backlogProvider.allTickets
        .where((t) => widget.backlogProvider.selectedIds.contains(t.id))
        .toList();
    if (selectedTickets.isNotEmpty) {
      final firstTags = selectedTickets.first.tags;
      selectedTags.addAll(firstTags.where(
        (t) => selectedTickets.every((ticket) => ticket.tags.contains(t)),
      ));
    }

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (ctx) => TagPickerSheet(
        availableTags: allTags,
        selectedTags: selectedTags,
        onSelect: (tags) => Navigator.pop(ctx, tags),
      ),
    );
    if (result != null && context.mounted) {
      await _bulkUpdate(context, {'tags': result});
    }
  }

  Future<void> _bulkUpdate(BuildContext context, Map<String, dynamic> update) async {
    final provider = widget.backlogProvider;
    final selectedTickets =
        provider.allTickets.where((t) => provider.selectedIds.contains(t.id)).toList();

    int success = 0;
    int failed = 0;

    for (final ticket in selectedTickets) {
      try {
        await provider.client.updateTicket(ticket.id, update);
        success++;
      } catch (e) {
        failed++;
        debugPrint('bulkUpdate failed for ${ticket.id}: $e');
      }
    }

    provider.deselectAll();
    await provider.refresh();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? 'Updated $success ticket(s)'
                : 'Updated $success ticket(s), $failed failed',
          ),
          backgroundColor: failed > 0
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      );
    }
  }

  Future<void> _applyBulkUpdate(BuildContext context) async {
    // This is called when the user taps "Apply" without picking a specific field.
    // For now just show a snackbar — the individual pickers handle actual updates.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pick a field to update first'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // --- Helpers ---

  List<String> _uniqueAssignees(List<Ticket> tickets) {
    final s = <String>{};
    for (final t in tickets) {
      if (t.assignee != null && t.assignee!.isNotEmpty) s.add(t.assignee!);
    }
    final list = s.toList()..sort();
    return list;
  }

  List<String> _uniqueTags(List<Ticket> tickets) {
    final s = <String>{};
    for (final t in tickets) {
      for (final tag in t.tags) {
        if (tag != 'backlog') s.add(tag);
      }
    }
    final list = s.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backlog'),
        actions: [
          // Select all / deselect all toggle
          if (widget.backlogProvider.tickets.isNotEmpty)
            widget.backlogProvider.hasSelection
                ? IconButton(
                    icon: const Icon(Icons.deselect),
                    tooltip: 'Deselect all',
                    onPressed: widget.backlogProvider.deselectAll,
                  )
                : IconButton(
                    icon: const Icon(Icons.select_all),
                    tooltip: 'Select all',
                    onPressed: widget.backlogProvider.selectAll,
                  ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.backlogProvider,
        builder: (context, _) {
          final provider = widget.backlogProvider;

          if (provider.loading && provider.allTickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.allTickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off,
                      size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text('Failed to load backlog',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: provider.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Fetch projects for the filter row dropdown
          return Column(
            children: [
              // Filter bar
              FutureBuilder<List<TicketProject>>(
                future: provider.projects.isNotEmpty
                    ? Future.value(provider.projects)
                    : provider.client.getProjects(),
                builder: (context, snapshot) {
                  final projects = provider.projects.isNotEmpty
                      ? provider.projects
                      : (snapshot.data ?? []);
                  return _buildFilterRow(projects);
                },
              ),
              // Loading indicator overlay when refreshing
              if (provider.loading)
                const LinearProgressIndicator(),
              // Ticket list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: provider.tickets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No backlog tickets',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : _buildTicketList(),
                ),
              ),
              // Bulk action bar
              _buildBulkActionBar(),
            ],
          );
        },
      ),
    );
  }
}

/// A single backlog ticket row with leading checkbox and tap-to-activate.
class _BacklogTicketTile extends StatelessWidget {
  final Ticket ticket;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onTap;

  const _BacklogTicketTile({
    required this.ticket,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => onToggleSelect(),
        ),
        title: Text(
          ticket.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              ticket.id,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: ticket.status),
            if (ticket.assignee != null && ticket.assignee!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(Icons.person_outline,
                  size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: 2),
              Text(
                ticket.assignee!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Small colored chip showing ticket status.
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: statusColor(status),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
