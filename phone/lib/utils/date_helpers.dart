// Date formatting utilities for the phone app.

/// Formats a date in short format: "Mon D" (e.g., "Apr 4").
String formatDateShort(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  } catch (_) {
    return '';
  }
}

/// Formats a date in long format: "Mon D, YYYY HH:MM" (e.g., "Apr 4, 2026 14:30").
String formatDateLong(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $h:$m';
  } catch (_) {
    return iso;
  }
}

/// Formats a date as relative time (e.g., "2h ago", "3d ago").
String formatRelativeTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.isNegative) {
      // Future date - show absolute
      return formatDateShort(iso);
    }

    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return '${mins}m ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '${hours}h ago';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return '${days}d ago';
    }
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w ago';
    }

    return formatDateShort(iso);
  } catch (_) {
    return '';
  }
}