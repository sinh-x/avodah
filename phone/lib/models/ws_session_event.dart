/// A server-sent event from the `/ws/session` WebSocket protocol.
///
/// The pa-platform `SessionManager` streams four event kinds:
/// `session-id`, `event`, `error`, and `end`. Each carries an ISO-8601
/// timestamp and an optional payload. See the pa-platform WebSocket
/// protocol docs (`docs/api/websocket.md`) for the full spec.
class WsSessionEvent {
  final WsSessionEventType type;
  final String timestamp;

  /// `sessionId` field — present only on `session-id` events.
  final String? sessionId;

  /// `message` field — present only on `error` events.
  final String? message;

  /// `data` field — present on `event` and `end` events.
  final Map<String, dynamic>? data;

  const WsSessionEvent({
    required this.type,
    required this.timestamp,
    this.sessionId,
    this.message,
    this.data,
  });

  factory WsSessionEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    return WsSessionEvent(
      type: WsSessionEventType.fromString(typeStr),
      timestamp: json['timestamp'] as String? ?? '',
      sessionId: json['sessionId'] as String?,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'WsSessionEvent($type, ts=$timestamp'
      '${sessionId != null ? ', sessionId=$sessionId' : ''}'
      '${message != null ? ', message=$message' : ''}'
      '${data != null ? ', data=$data' : ''})';
}

/// Event kinds emitted by the `/ws/session` stream.
enum WsSessionEventType {
  /// Server allocated a session id after `start` or `resume`.
  sessionId,

  /// A streamed opencode output event (normalized `ActivityEvent`).
  event,

  /// An error during the session (spawn failure, protocol error, etc.).
  error,

  /// Session terminated (child closed or stopped).
  end;

  static WsSessionEventType fromString(String s) {
    switch (s) {
      case 'session-id':
        return WsSessionEventType.sessionId;
      case 'event':
        return WsSessionEventType.event;
      case 'error':
        return WsSessionEventType.error;
      case 'end':
        return WsSessionEventType.end;
      default:
        return WsSessionEventType.event;
    }
  }
}