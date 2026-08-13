/// Data model for a session record from GET /api/sessions.
///
/// Represents an active session registered with the SessionManager.
class SessionRecord {
  final String id;
  final String? deploymentId;
  final String? model;
  final String status;

  const SessionRecord({
    required this.id,
    this.deploymentId,
    this.model,
    required this.status,
  });

  /// Extract the deployment id from [json], accepting both the canonical
  /// snake_case key `deployment_id` and the camelCase variant `deploymentId`.
  /// The pa-platform `GET /api/sessions` route normalises the key to
  /// `deploymentId` (camelCase), but some intermediate proxies or older
  /// clients may emit `deployment_id`. This helper reads the camelCase key
  /// first and falls back to snake_case so callers do not need to duplicate
  /// the fallback logic. Returns null when neither key is present.
  static String? _extractDeploymentId(Map<String, dynamic> json) {
    final camel = json['deploymentId'];
    if (camel is String && camel.isNotEmpty) return camel;
    final snake = json['deployment_id'];
    if (snake is String && snake.isNotEmpty) return snake;
    return null;
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String? ?? '',
      deploymentId: _extractDeploymentId(json),
      model: json['model'] as String?,
      status: json['status'] as String? ?? '',
    );
  }
}