/// Parses markdown frontmatter metadata blocks.
///
/// The agent workflow system uses `> **Key:** Value` format for metadata
/// in inbox files. This parser extracts those key-value pairs and the title.
library;

/// Parsed metadata from a markdown file's frontmatter block.
class MarkdownMetadata {
  final String title;
  final String? date;
  final String? from;
  final String? deployment;
  final String? type;
  final String? status;
  final String? priority;

  MarkdownMetadata({
    required this.title,
    this.date,
    this.from,
    this.deployment,
    this.type,
    this.status,
    this.priority,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (date != null) 'date': date,
        if (from != null) 'from': from,
        if (deployment != null) 'deployment': deployment,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
      };
}

/// Pattern matching `> **Key:** Value` lines in markdown frontmatter.
final _metadataPattern = RegExp(r'^>\s*\*\*(.+?):\*\*\s*(.+)$');

/// Pattern matching `# Title` lines.
final _titlePattern = RegExp(r'^#\s+(.+)$');

/// Parse markdown content and extract metadata from `> **Key:** Value` blocks.
///
/// Returns [MarkdownMetadata] with extracted fields. Unknown keys are ignored.
/// If no title is found, uses the filename (without extension) as fallback.
MarkdownMetadata parseMarkdownMetadata(String content, {String? filename}) {
  String? title;
  String? date;
  String? from;
  String? deployment;
  String? type;
  String? status;
  String? priority;

  for (final line in content.split('\n')) {
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
    deployment: deployment,
    type: type,
    status: status,
    priority: priority,
  );
}
