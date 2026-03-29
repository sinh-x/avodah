import 'package:flutter/material.dart';

/// Ordered list of all priority levels for display.
const _kAllPriorities = ['critical', 'high', 'medium', 'low'];

/// Human-readable label for a priority level.
String priorityLabel(String priority) {
  switch (priority) {
    case 'critical':
      return 'Critical';
    case 'high':
      return 'High';
    case 'medium':
      return 'Medium';
    case 'low':
      return 'Low';
    default:
      return priority;
  }
}

/// Color indicator for a priority level.
Color priorityColor(String priority) {
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

/// A bottom sheet for picking a new ticket priority.
///
/// Shows all priorities with color indicators. The [currentPriority] is
/// highlighted. Calls [onSelect] with the chosen priority string.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => PriorityPickerSheet(
///     currentPriority: ticket.priority,
///     onSelect: (newPriority) { ... },
///   ),
/// );
/// ```
class PriorityPickerSheet extends StatelessWidget {
  final String currentPriority;
  final void Function(String priority) onSelect;

  const PriorityPickerSheet({
    super.key,
    required this.currentPriority,
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
              'Change Priority',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          ..._kAllPriorities.map((priority) {
            final isSelected = priority == currentPriority;
            final color = priorityColor(priority);
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
                priorityLabel(priority),
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
              onTap: () => onSelect(priority),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
