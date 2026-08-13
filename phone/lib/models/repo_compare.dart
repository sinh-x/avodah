import 'repo_git_info.dart';

// Data model for comparing two refs from GET /api/repos/:key/compare.

class RepoCompare {
  final RepoMeta repo;
  final String from;
  final String to;
  final List<CompareCommit> commits;
  final int count;
  final CompareMeta meta;

  const RepoCompare({
    required this.repo,
    required this.from,
    required this.to,
    required this.commits,
    required this.count,
    required this.meta,
  });

  factory RepoCompare.fromJson(Map<String, dynamic> json) {
    return RepoCompare(
      repo: RepoMeta.fromJson(json['repo'] as Map<String, dynamic>),
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      commits: (json['commits'] as List?)
              ?.map((e) => CompareCommit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      count: json['count'] as int? ?? 0,
      meta: CompareMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// A commit in a compare result.
class CompareCommit {
  final String hash;
  final String hashShort;
  final String authorName;
  final String authorEmail;
  final String date;
  final String message;

  const CompareCommit({
    required this.hash,
    required this.hashShort,
    required this.authorName,
    required this.authorEmail,
    required this.date,
    required this.message,
  });

  factory CompareCommit.fromJson(Map<String, dynamic> json) {
    return CompareCommit(
      hash: json['hash'] as String? ?? '',
      hashShort: json['hash_short'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      authorEmail: json['author_email'] as String? ?? '',
      date: json['date'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Pagination metadata for a compare result.
class CompareMeta {
  final String from;
  final String to;
  final int total;
  final int limit;
  final int offset;

  const CompareMeta({
    required this.from,
    required this.to,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory CompareMeta.fromJson(Map<String, dynamic> json) {
    return CompareMeta(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      offset: json['offset'] as int? ?? 0,
    );
  }
}