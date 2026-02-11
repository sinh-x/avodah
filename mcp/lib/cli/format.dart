/// CLI output formatting utilities for Avodah.
library;

import '../services/task_service.dart';

// ── Constants ────────────────────────────────────────────────────────────────

/// Standard line width for separators.
const int lineWidth = 48;

// ── Section Formatting ───────────────────────────────────────────────────────

/// Section header: ═══════════ TIMER ═══════════
String sectionHeader(String title) {
  final inner = ' $title ';
  final pad = (lineWidth - inner.length) ~/ 2;
  final left = '=' * pad;
  final right = '=' * (lineWidth - pad - inner.length);
  return '$left$inner$right';
}

/// Sub-section separator: ────────────────────────
String separator() => '-' * lineWidth;

// ── Key-Value Row ────────────────────────────────────────────────────────────

/// Aligned label + value:  "  Elapsed:     1h 23m"
String kvRow(String label, String value, {int labelWidth = 13}) {
  return '  ${label.padRight(labelWidth)} $value';
}

// ── Hints ────────────────────────────────────────────────────────────────────

/// Hint line:  "  -> avo stop           to log your time"
String hint(String cmd, String desc, {int cmdWidth = 24}) {
  return '  -> ${cmd.padRight(cmdWidth)} $desc';
}

/// Plain hint without command alignment.
String hintPlain(String text) => '  -> $text';

// ── Duration/Time Formatting ─────────────────────────────────────────────────

String formatTime(DateTime dt) => dt.toString().substring(11, 16);

String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

String formatDate(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

/// Horizontal bar chart segment.
String buildBar(int value, int max, {int width = 20}) {
  final filled = max > 0 ? (value * width ~/ max) : 0;
  return '${'#' * filled}${'.' * (width - filled)}';
}

// ── Task Title Resolution ────────────────────────────────────────────────────

/// Resolves a task ID to a display title.
/// Falls back to the raw ID/title if the task isn't found.
Future<String> resolveTaskTitle(TaskService taskService, String taskId) async {
  try {
    final task = await taskService.show(taskId);
    final issueTag = task.issueId != null ? ' [${task.issueId}]' : '';
    return '${task.title}$issueTag';
  } catch (_) {
    return taskId;
  }
}
