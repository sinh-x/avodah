import 'package:flutter/material.dart';

/// Ordered list of all ticket statuses for display.
const _kAllStatuses = [
  'idea',
  'requirement-review',
  'pending-approval',
  'pending-implementation',
  'implementing',
  'review-uat',
  'done',
  'rejected',
  'cancelled',
  'on-hold',
];

/// Human-readable label for a ticket status.
String statusLabel(String status) {
  switch (status) {
    case 'idea':
      return 'Idea';
    case 'requirement-review':
      return 'Req Review';
    case 'pending-approval':
      return 'Pending Approval';
    case 'pending-implementation':
      return 'Pending Impl';
    case 'implementing':
      return 'Implementing';
    case 'review-uat':
      return 'Review/UAT';
    case 'done':
      return 'Done';
    case 'rejected':
      return 'Rejected';
    case 'cancelled':
      return 'Cancelled';
    case 'on-hold':
      return 'On Hold';
    default:
      return status;
  }
}

/// Color indicator for a ticket status.
Color statusColor(String status) {
  switch (status) {
    case 'idea':
      return Colors.purple;
    case 'requirement-review':
    case 'pending-approval':
      return Colors.amber;
    case 'pending-implementation':
    case 'implementing':
      return Colors.blue;
    case 'review-uat':
      return Colors.green;
    case 'done':
      return Colors.grey;
    case 'rejected':
    case 'cancelled':
      return Colors.red;
    case 'on-hold':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

/// A bottom sheet for picking a new ticket status.
///
/// Shows all statuses with color indicators. The [currentStatus] is
/// highlighted. Calls [onSelect] with the chosen status string.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => StatusPickerSheet(
///     currentStatus: ticket.status,
///     onSelect: (newStatus) { ... },
///   ),
/// );
/// ```
class StatusPickerSheet extends StatelessWidget {
  final String currentStatus;
  final void Function(String status) onSelect;

  const StatusPickerSheet({
    super.key,
    required this.currentStatus,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Change Status',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          ..._kAllStatuses.map((status) {
            final isSelected = status == currentStatus;
            final color = statusColor(status);
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                statusLabel(status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              onTap: () => onSelect(status),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
