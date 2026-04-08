import 'package:flutter/material.dart';

import '../models/ticket.dart';

/// A collapsible section listing sub-tickets linked to a ticket.
///
/// Shows each sub-ticket with its ID, title, and status badge.
/// Tapping a row opens a bottom sheet with sub-ticket details.
class TicketSubTicketsSection extends StatelessWidget {
  /// The list of sub-tickets to display.
  final List<SubTicket> subTickets;

  const TicketSubTicketsSection({
    super.key,
    required this.subTickets,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SubTickets section',
      child: _SectionContent(
        subTickets: subTickets,
      ),
    );
  }
}

class _SectionContent extends StatefulWidget {
  final List<SubTicket> subTickets;

  const _SectionContent({
    required this.subTickets,
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
              ))
          .toList(),
    );
  }
}

/// A single sub-ticket row with ID, title, status badge, and tap-to-navigate.
class _SubTicketRow extends StatelessWidget {
  final SubTicket subTicket;

  const _SubTicketRow({
    required this.subTicket,
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
        onTap: () => _showSubTicketDetails(context),
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

  void _showSubTicketDetails(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, subTicket.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ID + status row
            Row(
              children: [
                Text(
                  subTicket.id,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subTicket.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              subTicket.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            // Summary
            if (subTicket.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subTicket.summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Metadata chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (subTicket.assignee.isNotEmpty)
                  _metaChip(theme, Icons.person_outline, subTicket.assignee),
                if (subTicket.priority.isNotEmpty)
                  _metaChip(theme, Icons.flag_outlined, subTicket.priority),
                if (subTicket.estimate.isNotEmpty)
                  _metaChip(theme, Icons.timer_outlined, subTicket.estimate),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
