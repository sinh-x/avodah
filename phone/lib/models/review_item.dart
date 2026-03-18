/// Canonical document type for inbox items.
///
/// Mirrors the server-side detection in `markdown_parser.dart`.
/// Unknown values fall back to [workReport] (tolerant).
enum DocumentType {
  workReport,
  reviewRequest,
  planDraft,
  fyi,
  decisionNeeded;

  static DocumentType fromString(String? type) {
    switch (type) {
      case 'work-report':
        return DocumentType.workReport;
      case 'review-request':
        return DocumentType.reviewRequest;
      case 'plan-draft':
        return DocumentType.planDraft;
      case 'fyi':
        return DocumentType.fyi;
      case 'decision-needed':
        return DocumentType.decisionNeeded;
      default:
        return DocumentType.workReport;
    }
  }
}

/// Data model for an inbox review item from the agent workflow API.
class ReviewItem {
  final String id; // filename
  final String title;
  final String? date;
  final String? from;
  final String? to;
  final String? deployment;
  final String? type;
  final String? status;
  final String? priority;
  final int? size;
  final DateTime? modified;
  final String? content; // full markdown, only present in detail view
  final String? requeueAfter; // deferred items: ISO date string (YYYY-MM-DD)

  const ReviewItem({
    required this.id,
    required this.title,
    this.date,
    this.from,
    this.to,
    this.deployment,
    this.type,
    this.status,
    this.priority,
    this.size,
    this.modified,
    this.content,
    this.requeueAfter,
  });

  /// Parsed document type; defaults to [DocumentType.workReport] for unknown values.
  DocumentType get documentType => DocumentType.fromString(type);

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      date: json['date'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      deployment: json['deployment'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      priority: json['priority'] as String?,
      size: json['size'] as int?,
      modified: json['modified'] != null
          ? DateTime.tryParse(json['modified'] as String)
          : null,
      content: json['content'] as String?,
      requeueAfter: json['requeue_after'] as String?,
    );
  }
}
