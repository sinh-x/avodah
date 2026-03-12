/// Data model for an inbox review item from the agent workflow API.
class ReviewItem {
  final String id; // filename
  final String title;
  final String? date;
  final String? from;
  final String? deployment;
  final String? type;
  final String? status;
  final String? priority;
  final int? size;
  final DateTime? modified;
  final String? content; // full markdown, only present in detail view

  const ReviewItem({
    required this.id,
    required this.title,
    this.date,
    this.from,
    this.deployment,
    this.type,
    this.status,
    this.priority,
    this.size,
    this.modified,
    this.content,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      date: json['date'] as String?,
      from: json['from'] as String?,
      deployment: json['deployment'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      priority: json['priority'] as String?,
      size: json['size'] as int?,
      modified: json['modified'] != null
          ? DateTime.tryParse(json['modified'] as String)
          : null,
      content: json['content'] as String?,
    );
  }
}
