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

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String? ?? '',
      deploymentId: json['deploymentId'] as String?,
      model: json['model'] as String?,
      status: json['status'] as String? ?? '',
    );
  }
}