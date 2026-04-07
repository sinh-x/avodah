/// Data model for repository git information from the agent workflow API.
///
/// Represents the response from GET /api/repos/:key/git-info
class RepoGitInfo {
  final RepoMeta repo;
  final String currentBranch;
  final BranchInfo mainBranch;
  final BranchInfo developBranch;
  final MainVsDevelop mainVsDevelop;
  final List<FeatureBranch> featureBranches;
  final WorkingDirectoryStatus workingDirectory;
  final List<String> errors;

  const RepoGitInfo({
    required this.repo,
    required this.currentBranch,
    required this.mainBranch,
    required this.developBranch,
    required this.mainVsDevelop,
    required this.featureBranches,
    required this.workingDirectory,
    this.errors = const [],
  });

  static List<String> _parseErrors(dynamic errors) {
    if (errors is List) {
      return errors.cast<String>();
    } else if (errors is Map) {
      return errors.values.map((v) => v.toString()).toList();
    }
    return const [];
  }

  factory RepoGitInfo.fromJson(Map<String, dynamic> json) {
    return RepoGitInfo(
      repo: RepoMeta.fromJson(json['repo'] as Map<String, dynamic>),
      currentBranch: json['current_branch'] as String? ?? '',
      mainBranch: BranchInfo.fromJson(json['main_branch'] as Map<String, dynamic>),
      developBranch: BranchInfo.fromJson(json['develop_branch'] as Map<String, dynamic>),
      mainVsDevelop: MainVsDevelop.fromJson(json['main_vs_develop'] as Map<String, dynamic>),
      featureBranches: (json['feature_branches'] as List?)
              ?.map((e) => FeatureBranch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      workingDirectory: WorkingDirectoryStatus.fromJson(
          json['working_directory'] as Map<String, dynamic>),
      errors: _parseErrors(json['errors']),
    );
  }

  static List<String> _parseErrors(dynamic raw) {
    if (raw is Map) {
      return raw.values.whereType<String>().toList();
    }
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return const [];
  }
}

/// Repository metadata (key, path, description, prefix).
class RepoMeta {
  final String key;
  final String path;
  final String description;
  final String prefix;

  const RepoMeta({
    required this.key,
    required this.path,
    required this.description,
    required this.prefix,
  });

  factory RepoMeta.fromJson(Map<String, dynamic> json) {
    return RepoMeta(
      key: json['key'] as String? ?? '',
      path: json['path'] as String? ?? '',
      description: json['description'] as String? ?? '',
      prefix: json['prefix'] as String? ?? '',
    );
  }
}

/// Commit information on a branch.
class BranchCommit {
  final String hash;
  final String? hashShort;
  final String message;
  final String date;

  const BranchCommit({
    required this.hash,
    this.hashShort,
    required this.message,
    required this.date,
  });

  factory BranchCommit.fromJson(Map<String, dynamic> json) {
    return BranchCommit(
      hash: json['hash'] as String? ?? json['hash_short'] as String? ?? '',
      hashShort: json['hash_short'] as String?,
      message: json['message'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }
}

/// Branch information (name, exists, latest commit).
class BranchInfo {
  final String name;
  final bool exists;
  final BranchCommit? latestCommit;

  const BranchInfo({
    required this.name,
    required this.exists,
    this.latestCommit,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      name: json['name'] as String? ?? '',
      exists: json['exists'] as bool? ?? false,
      latestCommit: json['latestCommit'] != null
          ? BranchCommit.fromJson(json['latestCommit'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Comparison between main and develop branches.
class MainVsDevelop {
  final int mainAhead;
  final int developAhead;
  final bool diverged;

  const MainVsDevelop({
    required this.mainAhead,
    required this.developAhead,
    required this.diverged,
  });

  factory MainVsDevelop.fromJson(Map<String, dynamic> json) {
    return MainVsDevelop(
      mainAhead: json['main_ahead'] as int? ?? 0,
      developAhead: json['develop_ahead'] as int? ?? 0,
      diverged: json['diverged'] as bool? ?? false,
    );
  }
}

/// A feature branch with its latest commit.
class FeatureBranch {
  final String name;
  final BranchCommit latestCommit;

  const FeatureBranch({
    required this.name,
    required this.latestCommit,
  });

  factory FeatureBranch.fromJson(Map<String, dynamic> json) {
    return FeatureBranch(
      name: json['name'] as String? ?? '',
      latestCommit: BranchCommit.fromJson(json['latestCommit'] as Map<String, dynamic>),
    );
  }
}

/// Working directory status (clean vs dirty).
class WorkingDirectoryStatus {
  final bool clean;
  final int uncommittedCount;

  const WorkingDirectoryStatus({
    required this.clean,
    required this.uncommittedCount,
  });

  factory WorkingDirectoryStatus.fromJson(Map<String, dynamic> json) {
    return WorkingDirectoryStatus(
      clean: json['clean'] as bool? ?? true,
      uncommittedCount: json['uncommitted_count'] as int? ?? 0,
    );
  }
}
