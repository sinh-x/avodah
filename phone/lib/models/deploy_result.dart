/// Result of a PA deployment trigger (POST /api/deploy).
class DeployResult {
  final String deploymentId;
  final bool started;
  final String team;
  final String mode;

  const DeployResult({
    required this.deploymentId,
    required this.started,
    required this.team,
    required this.mode,
  });

  factory DeployResult.fromJson(Map<String, dynamic> json) {
    return DeployResult(
      deploymentId: (json['deployment_id'] ?? json['deploy_id']) as String? ?? '',
      started: json['started'] as bool? ?? json['status'] == 'launched',
      team: json['team'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
    );
  }
}
