/// Result of a PA deployment trigger (POST /api/deploy).
///
/// Pa-serve returns `{status: "pending"|"failed", reason?: string}`.
/// Dart AgentApiService returns `{started: bool, deployment_id: string}`.
class DeployResult {
  final String deploymentId;
  final bool started;
  final String team;
  final String mode;
  final String reason;

  const DeployResult({
    required this.deploymentId,
    required this.started,
    required this.team,
    required this.mode,
    this.reason = '',
  });

  factory DeployResult.fromJson(Map<String, dynamic> json) {
    return DeployResult(
      deploymentId:
          (json['deployment_id'] ?? json['deploy_id']) as String? ?? '',
      started: json['started'] as bool? ?? json['status'] != 'failed',
      team: json['team'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}
