import 'package:flutter/material.dart';

import '../models/ticket.dart';
import 'status_picker_sheet.dart';

/// A compact Material 3 card displaying ticket summary info for the Kanban board.
///
/// Wrapped in [LongPressDraggable] to support drag-and-drop status changes.
/// Shows title (max 2 lines), priority badge, type badge, team name, and
/// estimate badge. Trailing icon button opens [StatusPickerSheet].
///
/// The card is stateless — drag state is managed by [LongPressDraggable].
class TicketCard extends StatelessWidget {
  final Ticket ticket;

  /// Called when the card is tapped (navigate to detail screen).
  final VoidCallback? onTap;

  /// Called when the user picks a new status from the [StatusPickerSheet].
  final void Function(String newStatus)? onStatusChange;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Ticket>(
      data: ticket,
      feedback: _TicketCardFeedback(ticket: ticket),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _TicketCardBody(
          ticket: ticket,
          onTap: onTap,
          onStatusChange: onStatusChange,
        ),
      ),
      child: _TicketCardBody(
        ticket: ticket,
        onTap: onTap,
        onStatusChange: onStatusChange,
      ),
    );
  }
}

/// The inner card body — used for both normal and childWhenDragging states.
class _TicketCardBody extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final void Function(String newStatus)? onStatusChange;

  const _TicketCardBody({
    required this.ticket,
    this.onTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.id,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (onStatusChange != null)
                    _StatusIconButton(
                      ticket: ticket,
                      onStatusChange: onStatusChange!,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _PriorityBadge(priority: ticket.priority),
                  if (ticket.type != null) _TypeBadge(type: ticket.type!),
                  if (ticket.estimate != null)
                    _EstimateBadge(estimate: ticket.estimate!),
                ],
              ),
              if (ticket.team != null) ...[
                const SizedBox(height: 4),
                Text(
                  ticket.team!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Elevated, semi-transparent card shown while dragging.
class _TicketCardFeedback extends StatelessWidget {
  final Ticket ticket;

  const _TicketCardFeedback({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: 0.88,
        child: SizedBox(
          width: 264,
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.id,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _PriorityBadge(priority: ticket.priority),
                      if (ticket.type != null) _TypeBadge(type: ticket.type!),
                      if (ticket.estimate != null)
                        _EstimateBadge(estimate: ticket.estimate!),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trailing icon button that opens the [StatusPickerSheet].
class _StatusIconButton extends StatelessWidget {
  final Ticket ticket;
  final void Function(String) onStatusChange;

  const _StatusIconButton({
    required this.ticket,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_horiz, size: 18),
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      tooltip: 'Change status',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => StatusPickerSheet(
          currentStatus: ticket.status,
          onSelect: (newStatus) {
            Navigator.of(context).pop();
            onStatusChange(newStatus);
          },
        ),
      ),
    );
  }
}

/// Priority badge — colored chip with text label.
class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  Color _color(BuildContext context) {
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
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return _BadgeChip(
      label: priority.toUpperCase(),
      color: color,
    );
  }
}

/// Type badge — colored chip for ticket type.
class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  Color _color(BuildContext context) {
    switch (type) {
      case 'feature':
        return Colors.indigo;
      case 'bug':
        return Colors.red;
      case 'task':
        return Colors.teal;
      case 'review-request':
        return Colors.purple;
      case 'work-report':
        return Colors.brown;
      case 'fyi':
        return Colors.blueGrey;
      case 'idea':
        return Colors.amber;
      case 'question':
        return Colors.cyan;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String get _label {
    switch (type) {
      case 'feature':
        return 'FEAT';
      case 'bug':
        return 'BUG';
      case 'task':
        return 'TASK';
      case 'review-request':
        return 'REVIEW';
      case 'work-report':
        return 'REPORT';
      case 'fyi':
        return 'FYI';
      case 'idea':
        return 'IDEA';
      case 'question':
        return 'Q?';
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BadgeChip(label: _label, color: _color(context));
  }
}

/// Estimate badge — neutral chip showing XS/S/M/L/XL.
class _EstimateBadge extends StatelessWidget {
  final String estimate;

  const _EstimateBadge({required this.estimate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estimate,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Shared colored badge chip widget.
class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
