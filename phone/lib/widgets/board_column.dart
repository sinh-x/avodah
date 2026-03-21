import 'package:flutter/material.dart';

import '../models/ticket.dart';
import 'status_picker_sheet.dart';
import 'ticket_card.dart';

/// A single Kanban column widget.
///
/// Shows a status header (name + ticket count badge) followed by a scrollable
/// list of [TicketCard] widgets. Accepts [LongPressDraggable] drops via
/// [DragTarget] — highlights with a border when a valid drag hovers.
///
/// Fixed width: 280px. Intended for use inside a horizontal [SingleChildScrollView].
class KanbanColumn extends StatefulWidget {
  /// The data model for this column (status + tickets).
  final BoardColumn column;

  /// Called when a ticket is dropped onto this column.
  final void Function(Ticket ticket, String newStatus) onTicketDropped;

  /// Called when a ticket card is tapped.
  final void Function(Ticket ticket)? onTicketTap;

  /// Called when status is changed via the [StatusPickerSheet].
  final void Function(Ticket ticket, String newStatus)? onTicketStatusChange;

  const KanbanColumn({
    super.key,
    required this.column,
    required this.onTicketDropped,
    this.onTicketTap,
    this.onTicketStatusChange,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _isDragHovering = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.column.status;
    final color = statusColor(status);

    return SizedBox(
      width: 280,
      child: DragTarget<Ticket>(
        onWillAcceptWithDetails: (details) {
          if (details.data.status == status) return false;
          setState(() => _isDragHovering = true);
          return true;
        },
        onLeave: (_) => setState(() => _isDragHovering = false),
        onAcceptWithDetails: (details) {
          setState(() => _isDragHovering = false);
          widget.onTicketDropped(details.data, status);
        },
        builder: (context, candidateData, rejectedData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDragHovering
                    ? color.withValues(alpha: 0.85)
                    : color.withValues(alpha: 0.18),
                width: _isDragHovering ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              children: [
                _buildHeader(context, color),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    itemCount: widget.column.tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = widget.column.tickets[index];
                      return TicketCard(
                        ticket: ticket,
                        onTap: widget.onTicketTap != null
                            ? () => widget.onTicketTap!(ticket)
                            : null,
                        onStatusChange: widget.onTicketStatusChange != null
                            ? (newStatus) =>
                                widget.onTicketStatusChange!(ticket, newStatus)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              statusLabel(widget.column.status),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.column.count}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
