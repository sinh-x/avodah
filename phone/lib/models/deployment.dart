/// Data model for a deployment status from the agent workflow API.
class Deployment {
  final String deploymentId;
  final String team;
  final String status; // running, success, partial, failed, crashed
  final String startedAt;
  final String? completedAt;
  final String? summary;
  final List<String> agents;

  const Deployment({
    required this.deploymentId,
    required this.team,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.summary,
    this.agents = const [],
  });

  factory Deployment.fromJson(Map<String, dynamic> json) {
    return Deployment(
      deploymentId: json['deployment_id'] as String,
      team: json['team'] as String,
      status: json['status'] as String,
      startedAt: json['started_at'] as String? ?? '',
      completedAt: json['completed_at'] as String?,
      summary: json['summary'] as String?,
      agents: (json['agents'] as List?)?.cast<String>() ?? const [],
    );
  }

  bool get isRunning => status == 'running';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed' || status == 'crashed';
}
