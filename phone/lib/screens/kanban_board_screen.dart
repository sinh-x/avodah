import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ticket.dart';
import '../services/board_provider.dart';
import '../services/focus_provider.dart';
import '../services/local_dashboard_provider.dart';
import '../widgets/board_column.dart';
import '../widgets/bulletin_banner.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/focus_item_card.dart';
import '../widgets/ticket_card.dart';
import '../widgets/wip_summary.dart';
import '../services/crdt_sync_service.dart';
import '../settings/settings_screen.dart';
import 'create_bulletin_screen.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';
import 'repo_detail_screen.dart';

/// Main Kanban board screen.
///
/// Displays a horizontally scrollable board of [KanbanColumn] widgets,
/// driven by [BoardProvider]. Features:
/// - Project filter dropdown + team filter chips
/// - [BulletinBanner] when active bulletins exist (with resolve action)
/// - Toggle terminal columns (done/rejected/cancelled)
/// - Collapsible on-hold section below the main board
/// - Pull-to-refresh
/// - FAB navigates to [CreateTicketScreen]
/// - AppBar overflow menu includes "Create Bulletin" → [CreateBulletinScreen]
class KanbanBoardScreen extends StatefulWidget {
  final BoardProvider boardProvider;
  final LocalDashboardProvider dashboardProvider;
  final FocusProvider? focusProvider;

  const KanbanBoardScreen({
    super.key,
    required this.boardProvider,
    required this.dashboardProvider,
    this.focusProvider,
  });

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.boardProvider.board == null) {
      widget.boardProvider.refresh();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.boardProvider.setSearchQuery(value);
    });
  }

  void _openTicketDetail(BuildContext context, Ticket ticket) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => TicketDetailScreen(
            ticketId: ticket.id,
            boardProvider: widget.boardProvider,
          ),
        ))
        .then((_) => widget.boardProvider.refresh());
  }

  void _openCreateTicket(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) =>
              CreateTicketScreen(boardProvider: widget.boardProvider),
        ))
        .then((_) => widget.boardProvider.refresh());
  }

  void _openCreateBulletin(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) =>
              CreateBulletinScreen(boardProvider: widget.boardProvider),
        ))
        .then((_) => widget.boardProvider.refresh());
  }

  Future<void> _resolveBulletin(String id) async {
    await widget.boardProvider.client.resolveBulletin(id);
    await widget.boardProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final listenable = widget.focusProvider != null
        ? Listenable.merge([widget.boardProvider, widget.focusProvider!])
        : widget.boardProvider as Listenable;
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final provider = widget.boardProvider;
    final focusProvider = widget.focusProvider;
    final isFocusMode = focusProvider != null &&
        focusProvider.viewMode == FocusViewMode.focus;

    return Scaffold(
      appBar: AppBar(
        title: focusProvider != null
            ? SegmentedButton<FocusViewMode>(
                segments: const [
                  ButtonSegment(
                    value: FocusViewMode.board,
                    label: Text('Board'),
                    icon: Icon(Icons.view_kanban_outlined),
                  ),
                  ButtonSegment(
                    value: FocusViewMode.focus,
                    label: Text('Focus'),
                    icon: Icon(Icons.center_focus_strong_outlined),
                  ),
                ],
                selected: {isFocusMode ? FocusViewMode.focus : FocusViewMode.board},
                onSelectionChanged: (selection) {
                  focusProvider.setViewMode(selection.first);
                },
              )
            : const Text('Kanban Board'),
        actions: [
          ValueListenableBuilder<SyncConnectionState>(
            valueListenable: widget.dashboardProvider.connectionState,
            builder: (_, state, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ConnectionIndicator(state: state),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              provider.showTerminal
                  ? Icons.visibility
                  : Icons.visibility_off_outlined,
            ),
            tooltip: provider.showTerminal
                ? 'Hide done/rejected'
                : 'Show done/rejected',
            onPressed: provider.toggleTerminal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: provider.refresh,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'create_bulletin') {
                _openCreateBulletin(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'create_bulletin',
                child: ListTile(
                  leading: Icon(Icons.campaign_outlined),
                  title: Text('Create Bulletin'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateTicket(context),
        tooltip: 'New ticket',
        child: const Icon(Icons.add),
      ),
      body: isFocusMode
          ? _buildFocusView(context, focusProvider)
          : Column(
              children: [
                _buildFilterRow(context, provider),
                if (provider.activeBulletins.isNotEmpty)
                  BulletinBanner(
                    bulletins: provider.activeBulletins,
                    onResolve: _resolveBulletin,
                  ),
                if (provider.loading && provider.board == null)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (provider.error != null && provider.board == null)
                  _buildError(context, provider)
                else
                  Expanded(child: _buildBoardArea(context, provider)),
              ],
            ),
    );
  }

  Widget _buildFilterRow(BuildContext context, BoardProvider provider) {
    // Build project list from API response, sorted alphabetically.
    final projectItems = provider.projects.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final teams = provider.board != null
        ? (provider.board!.teamCounts.keys.toList()..sort())
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (projectItems.isEmpty)
                const Text('No projects')
              else
                DropdownButton<String>(
                  value: provider.selectedProject != null &&
                          projectItems
                              .any((p) => p.key == provider.selectedProject)
                      ? provider.selectedProject
                      : null,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: projectItems
                      .map((p) => DropdownMenuItem(
                          value: p.key,
                          child: Text('${p.key} (${p.activeTicketCount})')))
                      .toList(),
                  onChanged: (p) {
                    if (p != null) provider.setProject(p);
                  },
                ),
              if (projectItems.isNotEmpty) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    color: provider.selectedProject != null
                        ? null
                        : Colors.grey,
                  ),
                  tooltip: 'Project info',
                  onPressed: provider.selectedProject != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RepoDetailScreen(
                                repoKey: provider.selectedProject!,
                                apiClient: provider.client,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ],
              if (teams.isNotEmpty) ...[
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('All'),
                  selected: provider.selectedTeam == null,
                  onSelected: (_) => provider.setTeam(null),
                ),
                ...teams.map((team) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        label: Text(team),
                        selected: provider.selectedTeam == team,
                        onSelected: (_) => provider.setTeam(
                            provider.selectedTeam == team ? null : team),
                      ),
                    )),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search tickets…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: provider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        widget.boardProvider.setSearchQuery('');
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

  Widget _buildError(BuildContext context, BoardProvider provider) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text('Failed to load board', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error ?? '',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
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
      ),
    );
  }

  Widget _buildBoardArea(BuildContext context, BoardProvider provider) {
    final activeColumns = provider.activeColumns;
    final terminalColumns =
        provider.showTerminal ? provider.terminalColumns : <BoardColumn>[];
    final allColumns = [...activeColumns, ...terminalColumns];
    final onHold = provider.onHoldColumn;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: provider.refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: allColumns.map((col) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: KanbanColumn(
                              column: col,
                              onTicketTap: (ticket) =>
                                  _openTicketDetail(context, ticket),
                              onTicketDropped: (ticket, newStatus) =>
                                  provider.updateTicketStatus(
                                      ticket.id, newStatus),
                              onTicketStatusChange: (ticket, newStatus) =>
                                  provider.updateTicketStatus(
                                      ticket.id, newStatus),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (onHold != null && onHold.tickets.isNotEmpty)
          _OnHoldSection(
            column: onHold,
            onTicketTap: (ticket) => _openTicketDetail(context, ticket),
            onStatusChange: (ticket, newStatus) =>
                provider.updateTicketStatus(ticket.id, newStatus),
          ),
      ],
    );
  }

  Widget _buildFocusView(BuildContext context, FocusProvider focusProvider) {
    return ListenableBuilder(
      listenable: focusProvider,
      builder: (context, _) {
        if (focusProvider.loading && focusProvider.result == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (focusProvider.error != null && focusProvider.result == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text('Failed to load focus',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    focusProvider.error ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: focusProvider.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final items = focusProvider.filteredFocusItems;
        final wip = focusProvider.wipSummary;

        return Column(
          children: [
            _buildFocusFilterRow(context, focusProvider),
            Expanded(
              child: RefreshIndicator(
                onRefresh: focusProvider.refresh,
                child: ListView.builder(
                  itemCount: items.length + (wip != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (wip != null && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: WipSummaryWidget(wip: wip),
                      );
                    }
                    final item = items[index - (wip != null ? 1 : 0)];
                    return FocusItemCard(
                      item: item,
                      onTap: () => _openTicketFromFocus(context, item.id),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFocusFilterRow(
      BuildContext context, FocusProvider focusProvider) {
    final projects = focusProvider.availableProjects;
    final assignees = focusProvider.availableAssignees;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (projects.isEmpty)
            const Text('No projects')
          else
            DropdownButton<String>(
              value: focusProvider.selectedProject != null &&
                      projects.contains(focusProvider.selectedProject)
                  ? focusProvider.selectedProject
                  : null,
              isDense: true,
              underline: const SizedBox.shrink(),
              hint: const Text('All projects'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All projects')),
                ...projects.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    )),
              ],
              onChanged: (p) => focusProvider.setProject(p),
            ),
          if (assignees.isNotEmpty) ...[
            const SizedBox(width: 12),
            FilterChip(
              label: const Text('All'),
              selected: focusProvider.selectedAssignee == null,
              onSelected: (_) => focusProvider.setAssignee(null),
            ),
            ...assignees.map((a) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    label: Text(a),
                    selected: focusProvider.selectedAssignee == a,
                    onSelected: (_) => focusProvider.setAssignee(
                        focusProvider.selectedAssignee == a ? null : a),
                  ),
                )),
          ],
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('Enrich'),
            selected: focusProvider.enrichEnabled,
            avatar: focusProvider.enrichEnabled
                ? const Icon(Icons.auto_awesome, size: 16)
                : null,
            onSelected: (_) =>
                focusProvider.setEnrichEnabled(!focusProvider.enrichEnabled),
          ),
        ],
      ),
    );
  }

  Future<void> _openTicketFromFocus(BuildContext context, String ticketId) async {
    // Fetch ticket from API then navigate
    try {
      final ticket = await widget.boardProvider.client.getTicket(ticketId);
      if (context.mounted) {
        Navigator.of(context)
            .push(MaterialPageRoute<void>(
              builder: (_) => TicketDetailScreen(
                ticketId: ticket.id,
                boardProvider: widget.boardProvider,
              ),
            ))
            .then((_) => widget.focusProvider?.refresh());
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ticket: $e')),
        );
      }
    }
  }
}

/// Collapsible on-hold section below the main board.
class _OnHoldSection extends StatelessWidget {
  final BoardColumn column;
  final void Function(Ticket ticket) onTicketTap;
  final void Function(Ticket ticket, String newStatus) onStatusChange;

  const _OnHoldSection({
    required this.column,
    required this.onTicketTap,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      leading: const Icon(Icons.pause_circle_outline, color: Colors.orange),
      title: Row(
        children: [
          Text(
            'On Hold',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${column.count}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
      children: [
        SizedBox(
          height: 240,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: column.tickets.length,
            itemBuilder: (context, index) {
              final ticket = column.tickets[index];
              return TicketCard(
                ticket: ticket,
                onTap: () => onTicketTap(ticket),
                onStatusChange: (newStatus) => onStatusChange(ticket, newStatus),
              );
            },
          ),
        ),
      ],
    );
  }
}
