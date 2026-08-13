import 'repo_branches.dart' show BranchLatestCommit;
import 'repo_git_info.dart' show RepoMeta;

// Data model for remote branches from GET /api/repos/:key/branches/remote.

class RepoRemoteBranches {
  final RepoMeta repo;
  final List<RemoteBranch> remoteBranches;

  const RepoRemoteBranches({
    required this.repo,
    required this.remoteBranches,
  });

  factory RepoRemoteBranches.fromJson(Map<String, dynamic> json) {
    return RepoRemoteBranches(
      repo: RepoMeta.fromJson(json['repo'] as Map<String, dynamic>),
      remoteBranches: (json['remote_branches'] as List?)
              ?.map((e) => RemoteBranch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// A remote-tracking branch with its latest commit.
class RemoteBranch {
  final String name;
  final BranchLatestCommit? latestCommit;

  const RemoteBranch({
    required this.name,
    this.latestCommit,
  });

  factory RemoteBranch.fromJson(Map<String, dynamic> json) {
    final lc = json['latest_commit'];
    return RemoteBranch(
      name: json['name'] as String? ?? '',
      latestCommit: lc is Map<String, dynamic>
          ? BranchLatestCommit.fromJson(lc)
          : null,
    );
  }
}