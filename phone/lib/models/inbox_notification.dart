/// An informational record, never a PA approval or prompt response.
class InboxNotification {
  final String id, title, body, createdAt, remarks;
  final int revision;
  final bool read, handled;

  const InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.remarks,
    required this.revision,
    required this.read,
    required this.handled,
  });

  factory InboxNotification.fromJson(Map<String, dynamic> json) =>
      InboxNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: json['createdAt'] as String,
        remarks: json['remarks'] as String,
        revision: json['revision'] as int,
        read: json['read'] as bool,
        handled: json['handled'] as bool,
      );
}
