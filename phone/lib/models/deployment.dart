/// Data model for a deployment status from the agent workflow API.
class Deployment {
  final String deploymentId;
  final String team;
  final String status; // running, success, partial, failed, crashed
  final String startedAt;
  final String? completedAt;
  final String? summary;
  final List<String> agents;
  final Map<String, String> models;
  final String? error;
  final int? exitCode;
  final String? logFile;

  const Deployment({
    required this.deploymentId,
    required this.team,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.summary,
    this.agents = const [],
    this.models = const {},
    this.error,
    this.exitCode,
    this.logFile,
  });

  factory Deployment.fromJson(Map<String, dynamic> json) {
    final rawModels = json['models'] as Map<String, dynamic>?;
    return Deployment(
      deploymentId: json['deployment_id'] as String,
      team: json['team'] as String,
      status: json['status'] as String,
      startedAt: json['started_at'] as String? ?? '',
      completedAt: json['completed_at'] as String?,
      summary: json['summary'] as String?,
      agents: (json['agents'] as List?)?.cast<String>() ?? const [],
      models: rawModels?.map((k, v) => MapEntry(k, v as String)) ?? const {},
      error: json['error'] as String?,
      exitCode: json['exit_code'] as int?,
      logFile: json['log_file'] as String?,
    );
  }

  bool get isRunning => status == 'running';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed' || status == 'crashed';

  /// Elapsed duration as a human-readable string.
  ///
  /// Uses [completedAt] if available, otherwise computes against now.
  String get elapsedDuration {
    final start = DateTime.tryParse(startedAt);
    if (start == null) return '';
    final end =
        completedAt != null ? DateTime.tryParse(completedAt!) : DateTime.now();
    if (end == null) return '';
    final diff = end.difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
