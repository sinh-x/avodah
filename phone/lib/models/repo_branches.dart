import 'repo_git_info.dart';

/// Data model for repository branch list from the agent workflow API.
///
/// Represents the response from GET /api/repos/:key/branches
class RepoBranches {
  final RepoMeta repo;
  final List<Branch> branches;

  const RepoBranches({
    required this.repo,
    required this.branches,
  });

  factory RepoBranches.fromJson(Map<String, dynamic> json) {
    return RepoBranches(
      repo: RepoMeta.fromJson(json['repo'] as Map<String, dynamic>),
      branches: (json['branches'] as List?)
              ?.map((e) => Branch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// A git branch with its latest commit info.
class Branch {
  final String name;
  final bool isCurrent;
  final BranchLatestCommit latestCommit;

  const Branch({
    required this.name,
    required this.isCurrent,
    required this.latestCommit,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      name: json['name'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
      latestCommit: BranchLatestCommit.fromJson(
          json['latest_commit'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// The latest commit on a branch.
class BranchLatestCommit {
  final String hashShort;
  final String message;
  final String date;
  final String author;

  const BranchLatestCommit({
    required this.hashShort,
    required this.message,
    required this.date,
    required this.author,
  });

  factory BranchLatestCommit.fromJson(Map<String, dynamic> json) {
    return BranchLatestCommit(
      hashShort: json['hash_short'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: json['date'] as String? ?? '',
      author: json['author'] as String? ?? '',
    );
  }
}