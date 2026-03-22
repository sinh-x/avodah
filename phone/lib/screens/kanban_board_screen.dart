import 'package:flutter/material.dart';

import '../models/ticket.dart';
import '../services/board_provider.dart';
import '../widgets/board_column.dart';
import '../widgets/bulletin_banner.dart';
import '../widgets/ticket_card.dart';
import 'create_bulletin_screen.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

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

  const KanbanBoardScreen({super.key, required this.boardProvider});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.boardProvider.board == null) {
      widget.boardProvider.refresh();
    }
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
    return ListenableBuilder(
      listenable: widget.boardProvider,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final provider = widget.boardProvider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Board'),
        actions: [
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
      body: Column(
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
    final projects = <String>['personal-assistant', 'avodah'];
    if (provider.board != null &&
        !projects.contains(provider.board!.project)) {
      projects.add(provider.board!.project);
    }

    final teams = provider.board != null
        ? (provider.board!.teamCounts.keys.toList()..sort())
        : <String>[];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          DropdownButton<String>(
            value: provider.selectedProject,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: projects
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (p) {
              if (p != null) provider.setProject(p);
            },
          ),
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
