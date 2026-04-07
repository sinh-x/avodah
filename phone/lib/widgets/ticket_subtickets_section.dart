import 'package:flutter/material.dart';

import '../models/ticket.dart';
import '../screens/ticket_detail_screen.dart';
import '../services/board_provider.dart';

/// A collapsible section listing sub-tickets linked to a ticket.
///
/// Shows each sub-ticket with its ID, title, and status badge.
/// Tapping a row navigates to [TicketDetailScreen] for that sub-ticket.
class TicketSubTicketsSection extends StatelessWidget {
  /// The list of sub-tickets to display.
  final List<SubTicket> subTickets;

  /// The board provider used to navigate to [TicketDetailScreen].
  final BoardProvider boardProvider;

  const TicketSubTicketsSection({
    super.key,
    required this.subTickets,
    required this.boardProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SubTickets section',
      child: _SectionContent(
        subTickets: subTickets,
        boardProvider: boardProvider,
      ),
    );
  }
}

class _SectionContent extends StatefulWidget {
  final List<SubTicket> subTickets;
  final BoardProvider boardProvider;

  const _SectionContent({
    required this.subTickets,
    required this.boardProvider,
  });

  @override
  State<_SectionContent> createState() => _SectionContentState();
}

class _SectionContentState extends State<_SectionContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = widget.subTickets.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header — tappable to expand/collapse
        Semantics(
          label: 'SubTickets section. '
              '${hasData ? "${widget.subTickets.length} sub-tickets" : "no sub-tickets"}. '
              'Tap to expand.',
          button: true,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SubTickets',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  if (hasData)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.subTickets.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Expanded content
        if (_expanded) ...[
          const SizedBox(height: 4),
          _buildBody(context),
        ],
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.subTickets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No sub-tickets.',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    return Column(
      children: widget.subTickets
          .map((st) => _SubTicketRow(
                subTicket: st,
                boardProvider: widget.boardProvider,
              ))
          .toList(),
    );
  }
}

/// A single sub-ticket row with ID, title, status badge, and tap-to-navigate.
class _SubTicketRow extends StatelessWidget {
  final SubTicket subTicket;
  final BoardProvider boardProvider;

  const _SubTicketRow({
    required this.subTicket,
    required this.boardProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, subTicket.status);

    return Semantics(
      label: 'SubTicket ${subTicket.id}, '
          '${subTicket.title}, '
          'status ${subTicket.status}',
      button: true,
      child: InkWell(
        onTap: () => _navigateToSubTicket(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              // SubTicket ID
              Text(
                subTicket.id,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              // Title
              Expanded(
                child: Text(
                  subTicket.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subTicket.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubTicket(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(
          ticketId: subTicket.id,
          boardProvider: boardProvider,
        ),
      ),
    );
  }
}

Color _statusColor(BuildContext context, String status) {
  switch (status) {
    case 'done':
    case 'closed':
    case 'resolved':
      return Colors.green;
    case 'in-progress':
    case 'in progress':
    case 'running':
      return Colors.orange;
    case 'blocked':
    case 'on-hold':
      return Colors.red;
    case 'pending':
    case 'todo':
    case 'open':
      return Colors.blue;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}
