import 'repo_git_info.dart';

/// Data model for repository commit history from the agent workflow API.
///
/// Represents the response from GET /api/repos/:key/commits?branch=X&limit=N&offset=M
class RepoCommits {
  final RepoMeta repo;
  final String branch;
  final List<RepoCommit> commits;
  final CommitsMeta meta;

  const RepoCommits({
    required this.repo,
    required this.branch,
    required this.commits,
    required this.meta,
  });

  factory RepoCommits.fromJson(Map<String, dynamic> json) {
    return RepoCommits(
      repo: RepoMeta.fromJson(json['repo'] as Map<String, dynamic>),
      branch: json['branch'] as String? ?? '',
      commits: (json['commits'] as List?)
              ?.map((e) => RepoCommit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      meta: CommitsMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// A single commit in the repository history.
class RepoCommit {
  final String hash;
  final String hashShort;
  final String authorName;
  final String authorEmail;
  final String date;
  final String message;
  final DiffSummary diffSummary;

  const RepoCommit({
    required this.hash,
    required this.hashShort,
    required this.authorName,
    required this.authorEmail,
    required this.date,
    required this.message,
    required this.diffSummary,
  });

  factory RepoCommit.fromJson(Map<String, dynamic> json) {
    return RepoCommit(
      hash: json['hash'] as String? ?? '',
      hashShort: json['hash_short'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      authorEmail: json['author_email'] as String? ?? '',
      date: json['date'] as String? ?? '',
      message: json['message'] as String? ?? '',
      diffSummary: DiffSummary.fromJson(
          json['diff_summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Summary of changes in a commit (files, insertions, deletions).
class DiffSummary {
  final int filesChanged;
  final int insertions;
  final int deletions;

  const DiffSummary({
    required this.filesChanged,
    required this.insertions,
    required this.deletions,
  });

  factory DiffSummary.fromJson(Map<String, dynamic> json) {
    return DiffSummary(
      filesChanged: json['files_changed'] as int? ?? 0,
      insertions: json['insertions'] as int? ?? 0,
      deletions: json['deletions'] as int? ?? 0,
    );
  }
}

/// Pagination metadata for commit history.
class CommitsMeta {
  final String branch;
  final int total;
  final int limit;
  final int offset;

  const CommitsMeta({
    required this.branch,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory CommitsMeta.fromJson(Map<String, dynamic> json) {
    return CommitsMeta(
      branch: json['branch'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      offset: json['offset'] as int? ?? 0,
    );
  }
}