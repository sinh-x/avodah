import 'package:flutter/material.dart';

/// Ordered list of all estimate sizes for display.
const _kAllEstimates = ['XS', 'S', 'M', 'L', 'XL'];

/// Human-readable label for an estimate size.
String estimateLabel(String estimate) {
  return estimate; // XS, S, M, L, XL are already short labels
}

/// Color indicator for an estimate size.
Color estimateColor(String estimate) {
  switch (estimate) {
    case 'XS':
      return Colors.grey;
    case 'S':
      return Colors.blue;
    case 'M':
      return Colors.green;
    case 'L':
      return Colors.orange;
    case 'XL':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// A bottom sheet for picking a new ticket estimate.
///
/// Shows all estimate sizes with color indicators. The [currentEstimate] is
/// highlighted. Calls [onSelect] with the chosen estimate string.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => EstimatePickerSheet(
///     currentEstimate: ticket.estimate ?? 'S',
///     onSelect: (newEstimate) { ... },
///   ),
/// );
/// ```
class EstimatePickerSheet extends StatelessWidget {
  final String currentEstimate;
  final void Function(String estimate) onSelect;

  const EstimatePickerSheet({
    super.key,
    required this.currentEstimate,
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
              'Change Estimate',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _kAllEstimates.length,
              itemBuilder: (context, index) {
                final estimate = _kAllEstimates[index];
                final isSelected = estimate == currentEstimate;
                final color = estimateColor(estimate);
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
                    estimateLabel(estimate),
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
                  onTap: () => onSelect(estimate),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
