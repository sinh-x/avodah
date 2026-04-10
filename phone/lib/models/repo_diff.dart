import 'repo_git_info.dart';

/// Data model for repository commit diff from the agent workflow API.
///
/// Represents the response from GET /api/repos/:key/diff?commit=<sha>
class RepoDiff {
  final RepoMeta repo;
  final String commit;
  final List<DiffEntry> diffEntries;
  final DiffMeta meta;

  const RepoDiff({
    required this.repo,
    required this.commit,
    required this.diffEntries,
    required this.meta,
  });

  factory RepoDiff.fromJson(Map<String, dynamic> json) {
    return RepoDiff(
      repo: RepoMeta.fromJson(json['repo'] as Map<String, dynamic>),
      commit: json['commit'] as String? ?? '',
      diffEntries: (json['diff_entries'] as List?)
              ?.map((e) => DiffEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      meta: DiffMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// A file changed in a commit with its diff hunks.
class DiffEntry {
  final String oldPath;
  final String newPath;
  final String changeType;
  final List<DiffHunk> hunks;
  final bool binary;

  const DiffEntry({
    required this.oldPath,
    required this.newPath,
    required this.changeType,
    required this.hunks,
    required this.binary,
  });

  factory DiffEntry.fromJson(Map<String, dynamic> json) {
    final oldPath = json['old_path'] as String? ?? '';
    return DiffEntry(
      oldPath: oldPath,
      newPath: json['new_path'] as String? ?? '',
      changeType: json['change_type'] as String? ?? '',
      hunks: (json['hunks'] as List?)
              ?.map((e) {
                final hunkJson = e as Map<String, dynamic>;
                // Inject old_path from entry level into hunk JSON for language inference
                hunkJson['old_path'] = oldPath;
                return DiffHunk.fromJson(hunkJson);
              })
              .toList() ??
          const [],
      binary: json['binary'] as bool? ?? false,
    );
  }
}

/// A hunk (contiguous group of changed lines) within a diff entry.
class DiffHunk {
  final int oldStart;
  final int oldLines;
  final int newStart;
  final int newLines;
  final List<DiffLine> lines;
  /// Path of the file this hunk belongs to (used for language inference).
  final String oldPath;

  const DiffHunk({
    required this.oldStart,
    required this.oldLines,
    required this.newStart,
    required this.newLines,
    required this.lines,
    this.oldPath = '',
  });

  factory DiffHunk.fromJson(Map<String, dynamic> json) {
    return DiffHunk(
      oldStart: json['old_start'] as int? ?? 0,
      oldLines: json['old_lines'] as int? ?? 0,
      newStart: json['new_start'] as int? ?? 0,
      newLines: json['new_lines'] as int? ?? 0,
      lines: (json['lines'] as List?)
              ?.map((e) => DiffLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      oldPath: json['old_path'] as String? ?? '',
    );
  }
}

/// A single line within a diff hunk.
class DiffLine {
  final String type; // 'context' | 'add' | 'del'
  final String content;

  const DiffLine({
    required this.type,
    required this.content,
  });

  factory DiffLine.fromJson(Map<String, dynamic> json) {
    return DiffLine(
      type: json['type'] as String? ?? 'context',
      content: json['content'] as String? ?? '',
    );
  }
}

/// Summary metadata for a commit diff.
class DiffMeta {
  final String commit;
  final int filesChanged;
  final int insertions;
  final int deletions;

  const DiffMeta({
    required this.commit,
    required this.filesChanged,
    required this.insertions,
    required this.deletions,
  });

  factory DiffMeta.fromJson(Map<String, dynamic> json) {
    return DiffMeta(
      commit: json['commit'] as String? ?? '',
      filesChanged: json['files_changed'] as int? ?? 0,
      insertions: json['insertions'] as int? ?? 0,
      deletions: json['deletions'] as int? ?? 0,
    );
  }
}