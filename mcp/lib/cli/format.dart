/// CLI output formatting utilities for Avodah.
library;

import '../services/plan_service.dart';
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
  final totalMinutes = d.inMinutes;
  if (totalMinutes == 0) return '0m';

  final weeks = totalMinutes ~/ (5 * 8 * 60); // 5 days * 8 hours
  final days = (totalMinutes % (5 * 8 * 60)) ~/ (8 * 60); // 8-hour days
  final hours = (totalMinutes % (8 * 60)) ~/ 60;
  final minutes = totalMinutes % 60;

  final parts = <String>[];
  if (weeks > 0) parts.add('${weeks}w');
  if (days > 0) parts.add('${days}d');
  if (hours > 0) parts.add('${hours}h');
  if (minutes > 0) parts.add('${minutes}m');
  return parts.join(' ');
}

/// Formats worked time with optional estimate: "2h 30m / 8h"
String formatTimeWithEstimate(Duration worked, Duration? estimate) {
  final w = formatDuration(worked);
  if (estimate == null || estimate.inMinutes == 0) return w;
  return '$w / ${formatDuration(estimate)}';
}

String formatDate(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

/// Formats a DateTime as a relative string like "2 days ago" or "just now".
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return formatDate(date);
}

/// Formats a DateTime as "Mon, Feb 10 14:30" for display.
String formatDateTime(DateTime date) {
  return '${formatDate(date)} ${formatTime(date)}';
}

/// Parses human-friendly duration strings like "1h30m", "2h 15m", "30m".
/// Returns null if the string can't be parsed.
Duration? parseDuration(String input) {
  final normalized = input.replaceAll(' ', '');
  final regex = RegExp(r'^(?:(\d+)h)?(?:(\d+)m)?$');
  final match = regex.firstMatch(normalized);
  if (match == null) return null;

  final hours = int.tryParse(match.group(1) ?? '') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '') ?? 0;

  if (hours == 0 && minutes == 0) return null;
  return Duration(hours: hours, minutes: minutes);
}

/// Validates a YYYY-MM-DD date string.
bool isValidDate(String input) {
  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!regex.hasMatch(input)) return false;
  try {
    final parts = input.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final dt = DateTime(year, month, day);
    return dt.year == year && dt.month == month && dt.day == day;
  } catch (_) {
    return false;
  }
}

/// Returns today's date as YYYY-MM-DD.
String todayString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Horizontal bar chart segment.
String buildBar(int value, int max, {int width = 20}) {
  final filled = max > 0 ? (value * width ~/ max) : 0;
  return '${'#' * filled}${'.' * (width - filled)}';
}

// ── Jira Profile Display ─────────────────────────────────────────────────────

/// Formats a Jira profile for consistent display across commands.
String formatJiraProfile({
  required String profileName,
  required String baseUrl,
  required List<String> projectKeys,
  String? username,
}) {
  final buf = StringBuffer();
  buf.writeln(kvRow('Profile:', profileName));
  if (username != null) buf.writeln(kvRow('Username:', username));
  buf.writeln(kvRow('URL:', baseUrl));
  buf.write(kvRow('Projects:', projectKeys.join(', ')));
  return buf.toString();
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

// ── Plan Table ──────────────────────────────────────────────────────────────

/// Prints the plan-vs-actual table for a day.
/// Merges [defaultCategories] with summary data, sorted alphabetically.
void printPlanTable(DayPlanSummary summary, {List<String> defaultCategories = const []}) {
  final totalPlanned = formatDuration(summary.totalPlanned);
  final totalActual = formatDuration(summary.totalActual);

  final summaryMap = <String, PlanVsActual>{
    for (final cat in summary.categories) cat.category: cat,
  };

  final allCategories = <String>{...defaultCategories};
  for (final cat in summary.categories) {
    allCategories.add(cat.category);
  }
  final sorted = allCategories.toList()..sort();

  print('  $totalPlanned planned / $totalActual actual');
  print('');
  print('  ${'Category'.padRight(20)} ${'Planned'.padRight(11)}${'Actual'.padRight(11)}Delta');
  print('  ${'─' * 20} ${'─' * 10} ${'─' * 10} ${'─' * 10}');
  for (final name in sorted) {
    final cat = summaryMap[name];
    final planned = (cat != null && cat.planned.inMilliseconds > 0)
        ? formatDuration(cat.planned)
        : '-';
    final actual = cat != null ? formatDuration(cat.actual) : '0m';
    final deltaMs = cat?.delta.inMilliseconds ?? 0;
    final deltaStr = deltaMs == 0
        ? '-'
        : deltaMs > 0
            ? '+${formatDuration(Duration(milliseconds: deltaMs))}'
            : '-${formatDuration(Duration(milliseconds: -deltaMs))}';
    print('  ${name.padRight(20)} ${planned.padRight(11)}${actual.padRight(11)}$deltaStr');
  }
  if (summary.nonCategorized != null) {
    final nc = summary.nonCategorized!;
    print('  ${'─' * 20} ${'─' * 10} ${'─' * 10} ${'─' * 10}');
    print('  ${'Non-Categorized'.padRight(20)} ${'-'.padRight(11)}${formatDuration(nc.actual).padRight(11)}(uncategorized)');
  }
}
