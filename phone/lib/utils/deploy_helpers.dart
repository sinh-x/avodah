import 'package:flutter/material.dart';

/// Returns the color for a deployment status.
Color statusColor(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'running':
      return Colors.blue;
    case 'success':
    case 'completed':
      return Colors.green;
    case 'partial':
      return Colors.orange;
    case 'failed':
    case 'crashed':
      return Colors.red;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}

/// Returns the icon for a deployment status.
IconData statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'running':
      return Icons.play_circle_outline;
    case 'success':
    case 'completed':
      return Icons.check_circle_outline;
    case 'partial':
      return Icons.warning_amber_outlined;
    case 'failed':
    case 'crashed':
      return Icons.error_outline;
    default:
      return Icons.help_outline;
  }
}
