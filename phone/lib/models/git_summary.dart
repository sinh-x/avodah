/// Data model for the git summary of all repos from GET /api/repos/git-summary.
class GitSummary {
  final List<GitSummaryRepo> repos;

  const GitSummary({required this.repos});

  factory GitSummary.fromJson(Map<String, dynamic> json) {
    return GitSummary(
      repos: (json['repos'] as List?)
              ?.map((e) => GitSummaryRepo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// A single repo entry in the git summary.
class GitSummaryRepo {
  final String key;
  final String path;
  final String? prefix;
  final String currentBranch;
  final bool isDirty;
  final int featureBranchCount;
  final int developAheadOfMain;
  final String? error;

  const GitSummaryRepo({
    required this.key,
    required this.path,
    this.prefix,
    required this.currentBranch,
    required this.isDirty,
    required this.featureBranchCount,
    required this.developAheadOfMain,
    this.error,
  });

  factory GitSummaryRepo.fromJson(Map<String, dynamic> json) {
    return GitSummaryRepo(
      key: json['key'] as String? ?? '',
      path: json['path'] as String? ?? '',
      prefix: json['prefix'] as String?,
      currentBranch: json['current_branch'] as String? ?? '',
      isDirty: json['is_dirty'] as bool? ?? false,
      featureBranchCount: json['feature_branch_count'] as int? ?? 0,
      developAheadOfMain: json['develop_ahead_of_main'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }
}