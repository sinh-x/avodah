/// Parses markdown frontmatter metadata blocks and writes feedback annotations.
///
/// The agent workflow system uses two metadata formats:
///
/// 1. **Inline metadata** — `> **Key:** Value` lines in the document body
///    (used for file origin metadata: date, from, deployment, type, status)
///
/// 2. **YAML frontmatter** — `---` delimited block at the top of the file
///    (used for machine-readable `human_feedback:` annotations written by server)
///
/// Feedback annotations are written per the annotation decision table in §8
/// of the requirements. See [writeFeedbackAnnotation] for details.
library;

import 'package:path/path.dart' as p;

// --- Public data classes ---

/// Parsed metadata from a markdown file.
class MarkdownMetadata {
  final String title;
  final String? date;
  final String? from;
  final String? to;
  final String? deployment;
  final String? type;
  final String? status;
  final String? priority;

  /// Human feedback parsed from YAML frontmatter, if present.
  final HumanFeedback? humanFeedback;

  MarkdownMetadata({
    required this.title,
    this.date,
    this.from,
    this.to,
    this.deployment,
    this.type,
    this.status,
    this.priority,
    this.humanFeedback,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (date != null) 'date': date,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (deployment != null) 'deployment': deployment,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (humanFeedback != null)
          'human_feedback': humanFeedback!.toJson(),
      };
}

/// Human feedback parsed from a file's YAML frontmatter `human_feedback:` block.
class HumanFeedback {
  /// The action taken: approved | rejected | deferred | saved-for-later |
  /// pending-reject-feedback
  final String action;
  final String? by;
  final String? at;
  final String? note;
  final List<String> chips;

  // Reject-specific
  final String? whatIsWrong;
  final String? whatToFix;
  final String? priority;

  // Defer-specific
  final String? deferReason;
  final String? requeueAfter;

  HumanFeedback({
    required this.action,
    this.by,
    this.at,
    this.note,
    this.chips = const [],
    this.whatIsWrong,
    this.whatToFix,
    this.priority,
    this.deferReason,
    this.requeueAfter,
  });

  bool get isPendingRejectFeedback => action == 'pending-reject-feedback';
  bool get isSavedForLater => action == 'saved-for-later';

  Map<String, dynamic> toJson() => {
        'action': action,
        if (by != null) 'by': by,
        if (at != null) 'at': at,
        if (note != null) 'note': note,
        if (chips.isNotEmpty) 'chips': chips,
        if (whatIsWrong != null) 'what_is_wrong': whatIsWrong,
        if (whatToFix != null) 'what_to_fix': whatToFix,
        if (priority != null) 'priority': priority,
        if (deferReason != null) 'defer_reason': deferReason,
        if (requeueAfter != null) 'requeue_after': requeueAfter,
      };
}

/// Parameters for writing a feedback annotation to file content.
///
/// Construct one of the specific subclasses corresponding to the action type.
sealed class FeedbackAnnotation {
  const FeedbackAnnotation();
}

class ApproveFeedbackAnnotation extends FeedbackAnnotation {
  final String? note;
  final List<String> chips;
  const ApproveFeedbackAnnotation({this.note, this.chips = const []});
}

class RejectFeedbackAnnotation extends FeedbackAnnotation {
  final String whatIsWrong;
  final String whatToFix;
  final String priority; // high | medium | low
  final List<String> chips;
  const RejectFeedbackAnnotation({
    required this.whatIsWrong,
    required this.whatToFix,
    this.priority = 'medium',
    this.chips = const [],
  });
}

class PendingRejectAnnotation extends FeedbackAnnotation {
  const PendingRejectAnnotation();
}

class DeferFeedbackAnnotation extends FeedbackAnnotation {
  final String? reason;
  final String? requeueAfter;
  final List<String> chips;
  const DeferFeedbackAnnotation({
    this.reason,
    this.requeueAfter,
    this.chips = const [],
  });
}

class SaveForLaterAnnotation extends FeedbackAnnotation {
  const SaveForLaterAnnotation();
}

/// Acknowledge a work-report or FYI item.
///
/// - No note → fast-path: no annotation written (clean move).
/// - Note provided → YAML frontmatter only (`action: acknowledged` + note).
///   No `## Human Review` section is ever written for acknowledgments.
class AcknowledgeFeedbackAnnotation extends FeedbackAnnotation {
  final String? note;
  const AcknowledgeFeedbackAnnotation({this.note});
}

// --- Parsing ---

/// Pattern matching `> **Key:** Value` lines in markdown frontmatter.
final _metadataPattern = RegExp(r'^>\s*\*\*(.+?):\*\*\s*(.+)$');

/// Pattern matching `# Title` lines.
final _titlePattern = RegExp(r'^#\s+(.+)$');

/// Parse markdown content and extract metadata from `> **Key:** Value` blocks
/// and from YAML frontmatter `human_feedback:` block.
///
/// Returns [MarkdownMetadata] with extracted fields. Unknown keys are ignored.
/// If no title is found, uses the filename (without extension) as fallback.
MarkdownMetadata parseMarkdownMetadata(String content, {String? filename}) {
  String? title;
  String? date;
  String? from;
  String? to;
  String? deployment;
  String? type;
  String? status;
  String? priority;

  // Parse YAML frontmatter first (before scanning body lines)
  final humanFeedback = _parseFrontmatterFeedback(content);

  // Strip frontmatter before scanning body for inline metadata
  final bodyContent = _stripFrontmatter(content);

  for (final line in bodyContent.split('\n')) {
    final trimmed = line.trim();

    // Extract title from first heading
    if (title == null) {
      final titleMatch = _titlePattern.firstMatch(trimmed);
      if (titleMatch != null) {
        title = titleMatch.group(1)!.trim();
        continue;
      }
    }

    // Extract metadata from `> **Key:** Value` lines
    final metaMatch = _metadataPattern.firstMatch(trimmed);
    if (metaMatch != null) {
      final key = metaMatch.group(1)!.trim().toLowerCase();
      final value = metaMatch.group(2)!.trim();

      switch (key) {
        case 'date':
          date = value;
        case 'from':
          from = value;
        case 'to':
          to = value;
        case 'deployment':
          deployment = value;
        case 'type':
          type = value;
        case 'status':
          status = value;
        case 'priority':
          priority = value;
      }
    }
  }

  // Fallback title from filename
  title ??= filename?.replaceAll(RegExp(r'\.md$'), '') ?? 'Untitled';

  return MarkdownMetadata(
    title: title,
    date: date,
    from: from,
    to: to,
    deployment: deployment,
    type: type,
    status: status,
    priority: priority,
    humanFeedback: humanFeedback,
  );
}

/// Parse `human_feedback:` block from YAML frontmatter.
///
/// Returns null if no frontmatter or no `human_feedback:` block is present.
HumanFeedback? _parseFrontmatterFeedback(String content) {
  final frontmatter = _extractFrontmatter(content);
  if (frontmatter == null) return null;

  // Find the human_feedback: block
  final lines = frontmatter.split('\n');
  int? feedbackStart;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].trimRight() == 'human_feedback:') {
      feedbackStart = i + 1;
      break;
    }
  }
  if (feedbackStart == null) return null;

  // Collect indented key-value pairs under human_feedback:
  final feedbackMap = <String, String>{};
  for (int i = feedbackStart; i < lines.length; i++) {
    final line = lines[i];
    // Stop if we hit a non-indented line (end of block)
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('\t')) {
      break;
    }
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    // Parse "key: value" pairs
    final colonIdx = trimmed.indexOf(':');
    if (colonIdx <= 0) continue;
    final key = trimmed.substring(0, colonIdx).trim();
    final rawValue = trimmed.substring(colonIdx + 1).trim();
    feedbackMap[key] = _unquoteYamlValue(rawValue);
  }

  final action = feedbackMap['action'];
  if (action == null) return null;

  // Parse chips list if present
  final chipsRaw = feedbackMap['chips'];
  final chips = chipsRaw != null ? _parseYamlList(chipsRaw) : <String>[];

  return HumanFeedback(
    action: action,
    by: feedbackMap['by'],
    at: feedbackMap['at'],
    note: feedbackMap['note'],
    chips: chips,
    whatIsWrong: feedbackMap['what_is_wrong'],
    whatToFix: feedbackMap['what_to_fix'],
    priority: feedbackMap['priority'],
    deferReason: feedbackMap['defer_reason'],
    requeueAfter: feedbackMap['requeue_after'],
  );
}

// --- Document type detection ---

/// Detect the canonical document type from content and filename.
///
/// Detection order:
/// 1. Parse `> **Type:** <value>` from header block; normalize via alias map.
/// 2. Filename fallback: `review-*` prefix → `review-request`;
///    `plan-draft` in name → `plan-draft`.
/// 3. Default: `work-report`.
///
/// Unknown `Type:` values fall back to `work-report` (tolerant).
String detectDocumentType(String content, String filename) {
  // Strip frontmatter before scanning body (handles annotated files)
  final body = _stripFrontmatter(content);
  final lines = body.split('\n');
  for (final line in lines) {
    if (line.startsWith('> **Type:**')) {
      final value = line.replaceFirst('> **Type:**', '').trim();
      return _normalizeDocumentType(value);
    }
    // Stop at first non-blockquote, non-title, non-empty line (end of header)
    if (line.isNotEmpty &&
        !line.startsWith('#') &&
        !line.startsWith('>') &&
        line.trim().isNotEmpty) break;
  }

  // Filename fallback: strip YYYY-MM-DD- date prefix
  final base = p.basename(filename);
  final withoutDate = base.replaceFirst(RegExp(r'^\d{4}-\d{2}-\d{2}-'), '');
  if (withoutDate.startsWith('review-')) return 'review-request';
  if (withoutDate.contains('plan-draft')) return 'plan-draft';

  // Default
  return 'work-report';
}

/// Normalize a raw `Type:` value to its canonical type ID.
///
/// Case-insensitive. Unknown values fall back to `work-report`.
String _normalizeDocumentType(String raw) {
  final lower = raw.toLowerCase().trim();
  if (lower == 'work-report' || lower == 'work report') return 'work-report';
  if (lower.startsWith('review')) return 'review-request';
  if (lower.startsWith('plan')) return 'plan-draft';
  if (lower.startsWith('fyi') || lower == 'notification') return 'fyi';
  if (lower.startsWith('decision')) return 'decision-needed';
  return 'work-report'; // tolerant fallback
}

// --- Annotation writing ---

/// Write a feedback annotation to file content, returning the updated content.
///
/// Implements the annotation decision table (§8 of requirements):
///
/// | Action         | Feedback           | YAML frontmatter | ## Human Review |
/// |----------------|--------------------|-----------------|-----------------|
/// | Approve        | None               | No              | No              |
/// | Approve        | Note and/or chips  | Yes             | Yes             |
/// | Reject         | Full fields        | Yes             | Yes             |
/// | Reject         | Pending (dismiss)  | Yes (pending)   | No              |
/// | Defer          | None               | No              | No              |
/// | Defer          | Note and/or date   | Yes             | Yes             |
/// | Save for Later | (always)           | Yes (minimal)   | No              |
String writeFeedbackAnnotation(String content, FeedbackAnnotation annotation) {
  final now = DateTime.now().toIso8601String();
  const by = 'Sinh';

  switch (annotation) {
    case ApproveFeedbackAnnotation(:final note, :final chips):
      final hasContent =
          (note?.isNotEmpty ?? false) || chips.isNotEmpty;
      if (!hasContent) return content; // fast-path: no annotation

      final yaml = _buildFeedbackYaml(
        action: 'approved',
        by: by,
        at: now,
        note: note,
        chips: chips,
      );
      final section = _buildHumanReviewSection(
        action: 'approved',
        at: now,
        note: note,
        chips: chips,
      );
      return _applyAnnotation(content, yaml, section);

    case RejectFeedbackAnnotation(
        :final whatIsWrong,
        :final whatToFix,
        :final priority,
        :final chips
      ):
      final yaml = _buildFeedbackYaml(
        action: 'rejected',
        by: by,
        at: now,
        chips: chips,
        whatIsWrong: whatIsWrong,
        whatToFix: whatToFix,
        priority: priority,
      );
      final section = _buildHumanReviewSection(
        action: 'rejected',
        at: now,
        chips: chips,
        whatIsWrong: whatIsWrong,
        whatToFix: whatToFix,
        priority: priority,
      );
      return _applyAnnotation(content, yaml, section);

    case PendingRejectAnnotation():
      // Write YAML frontmatter only (file stays in inbox)
      final yaml = _buildFeedbackYaml(
        action: 'pending-reject-feedback',
        by: by,
        at: now,
      );
      return _applyAnnotation(content, yaml, null);

    case DeferFeedbackAnnotation(:final reason, :final requeueAfter, :final chips):
      final hasContent =
          (reason?.isNotEmpty ?? false) || requeueAfter != null || chips.isNotEmpty;
      if (!hasContent) return content; // fast-path: no annotation

      final yaml = _buildFeedbackYaml(
        action: 'deferred',
        by: by,
        at: now,
        chips: chips,
        deferReason: reason,
        requeueAfter: requeueAfter,
      );
      final section = _buildHumanReviewSection(
        action: 'deferred',
        at: now,
        chips: chips,
        deferReason: reason,
        requeueAfter: requeueAfter,
      );
      return _applyAnnotation(content, yaml, section);

    case SaveForLaterAnnotation():
      // Always write minimal YAML frontmatter; never write ## Human Review
      final yaml = _buildFeedbackYaml(
        action: 'saved-for-later',
        by: by,
        at: now,
      );
      return _applyAnnotation(content, yaml, null);

    case AcknowledgeFeedbackAnnotation(:final note):
      // Fast-path: no note → clean move (no annotation written)
      if (note == null || note.isEmpty) return content;
      // Note provided → YAML frontmatter only; NO ## Human Review section
      final yaml = _buildFeedbackYaml(
        action: 'acknowledged',
        by: by,
        at: now,
        note: note,
      );
      return _applyAnnotation(content, yaml, null);
  }
}

// --- YAML frontmatter helpers ---

/// Extract raw YAML frontmatter content (between `---` delimiters).
///
/// Returns null if no frontmatter is present.
String? _extractFrontmatter(String content) {
  if (!content.startsWith('---\n')) return null;
  final end = content.indexOf('\n---\n', 4);
  if (end == -1) return null;
  return content.substring(4, end);
}

/// Strip YAML frontmatter block from content (for body scanning).
String _stripFrontmatter(String content) {
  if (!content.startsWith('---\n')) return content;
  final end = content.indexOf('\n---\n', 4);
  if (end == -1) return content;
  return content.substring(end + 5); // skip '\n---\n'
}

/// Unquote a YAML scalar value (removes surrounding quotes).
String _unquoteYamlValue(String value) {
  if (value.length >= 2) {
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}

/// Parse a YAML inline list like `["a", "b", "c"]` or `[a, b]`.
List<String> _parseYamlList(String value) {
  if (!value.startsWith('[') || !value.endsWith(']')) return [];
  final inner = value.substring(1, value.length - 1);
  return inner
      .split(',')
      .map((e) => _unquoteYamlValue(e.trim()))
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Build the `human_feedback:` YAML block content (not the full frontmatter).
String _buildFeedbackYaml({
  required String action,
  required String by,
  required String at,
  String? note,
  List<String> chips = const [],
  String? whatIsWrong,
  String? whatToFix,
  String? priority,
  String? deferReason,
  String? requeueAfter,
}) {
  final buf = StringBuffer();
  buf.writeln('human_feedback:');
  buf.writeln('  action: $action');
  buf.writeln('  by: $by');
  buf.writeln('  at: $at');
  if (note != null && note.isNotEmpty) {
    buf.writeln('  note: ${_quoteYamlString(note)}');
  }
  if (chips.isNotEmpty) {
    final chipsStr =
        chips.map((c) => '"${c.replaceAll('"', '\\"')}"').join(', ');
    buf.writeln('  chips: [$chipsStr]');
  }
  if (whatIsWrong != null && whatIsWrong.isNotEmpty) {
    buf.writeln('  what_is_wrong: ${_quoteYamlString(whatIsWrong)}');
  }
  if (whatToFix != null && whatToFix.isNotEmpty) {
    buf.writeln('  what_to_fix: ${_quoteYamlString(whatToFix)}');
  }
  if (priority != null && priority.isNotEmpty) {
    buf.writeln('  priority: $priority');
  }
  if (deferReason != null && deferReason.isNotEmpty) {
    buf.writeln('  defer_reason: ${_quoteYamlString(deferReason)}');
  }
  if (requeueAfter != null) {
    buf.writeln('  requeue_after: "$requeueAfter"');
  }
  return buf.toString().trimRight();
}

/// Quote a YAML string value if it contains special characters.
String _quoteYamlString(String value) {
  // Quote if contains colon, hash, or quote characters
  if (value.contains(': ') ||
      value.contains('#') ||
      value.contains('"') ||
      value.contains("'")) {
    final escaped = value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    return '"$escaped"';
  }
  return value;
}

/// Build the `## Human Review` markdown section for appending to the file.
String _buildHumanReviewSection({
  required String action,
  required String at,
  String? note,
  List<String> chips = const [],
  String? whatIsWrong,
  String? whatToFix,
  String? priority,
  String? deferReason,
  String? requeueAfter,
}) {
  // Format timestamp for human display (trim sub-seconds)
  final displayAt = at.length > 16 ? at.substring(0, 16) : at;

  final buf = StringBuffer();
  buf.writeln('## Human Review');
  buf.writeln();
  buf.writeln('> **Action:** $action');
  buf.writeln('> **By:** Sinh');
  buf.writeln('> **At:** $displayAt');

  if (note != null && note.isNotEmpty) {
    buf.writeln('> **Note:** $note');
  }
  if (chips.isNotEmpty) {
    buf.writeln('> **Chips:** ${chips.join(', ')}');
  }
  if (whatIsWrong != null && whatIsWrong.isNotEmpty) {
    buf.writeln("> **What's wrong:** $whatIsWrong");
  }
  if (whatToFix != null && whatToFix.isNotEmpty) {
    buf.writeln('> **What to fix:** $whatToFix');
  }
  if (priority != null && priority.isNotEmpty) {
    buf.writeln('> **Priority:** ${priority[0].toUpperCase()}${priority.substring(1)}');
  }
  if (deferReason != null && deferReason.isNotEmpty) {
    buf.writeln('> **Reason:** $deferReason');
  }
  if (requeueAfter != null) {
    buf.writeln('> **Re-queue after:** $requeueAfter');
  }

  return buf.toString().trimRight();
}

/// Apply YAML frontmatter and optional `## Human Review` section to content.
///
/// - If content has no frontmatter: prepends new `---` block.
/// - If content already has frontmatter: merges `human_feedback:` into it.
/// - If [humanReviewSection] is provided: appends to end of file.
String _applyAnnotation(
    String content, String yamlBlock, String? humanReviewSection) {
  String result = _mergeYamlFrontmatter(content, yamlBlock);

  if (humanReviewSection != null) {
    // Ensure exactly one blank line before the section
    if (!result.endsWith('\n')) result = '$result\n';
    if (!result.endsWith('\n\n')) result = '$result\n';
    result = '$result$humanReviewSection\n';
  }

  return result;
}

/// Merge a new YAML block into the file's frontmatter.
///
/// If no frontmatter exists, prepends `---\n<block>\n---\n`.
/// If frontmatter exists, appends the block content inside the `---` delimiters.
/// (Overwrites existing `human_feedback:` key if present.)
String _mergeYamlFrontmatter(String content, String yamlBlock) {
  if (content.startsWith('---\n')) {
    final endIdx = content.indexOf('\n---\n', 4);
    if (endIdx != -1) {
      // Extract existing frontmatter
      var existing = content.substring(4, endIdx);
      final afterFrontmatter = content.substring(endIdx + 5);

      // Remove existing human_feedback: block (if present) to replace it
      existing = _removeFrontmatterKey(existing, 'human_feedback');

      // Append new block
      if (existing.isNotEmpty && !existing.endsWith('\n')) {
        existing = '$existing\n';
      }
      final merged = '$existing$yamlBlock';
      return '---\n$merged\n---\n$afterFrontmatter';
    }
  }

  // No existing frontmatter — prepend new block
  return '---\n$yamlBlock\n---\n$content';
}

/// Remove a top-level key and its indented children from a YAML string.
String _removeFrontmatterKey(String yaml, String key) {
  final lines = yaml.split('\n');
  final result = <String>[];
  bool inKey = false;

  for (final line in lines) {
    if (line.trimRight() == '$key:' ||
        line.startsWith('$key:') ||
        line.startsWith('$key ')) {
      inKey = true;
      continue;
    }
    if (inKey) {
      // Continue skipping indented children
      if (line.startsWith(' ') || line.startsWith('\t') || line.isEmpty) {
        continue;
      }
      inKey = false;
    }
    result.add(line);
  }

  // Remove trailing empty lines left by removal
  while (result.isNotEmpty && result.last.isEmpty) {
    result.removeLast();
  }

  return result.join('\n');
}
