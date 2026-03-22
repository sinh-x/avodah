// Data models for the PA ticket/kanban system.
//
// Matches the API response shapes from pa serve /api/tickets and /api/board.
// JSON keys are camelCase as returned by the server.

class TicketComment {
  final String id;
  final String author;
  final String content;
  final DateTime timestamp;
  final String? editedAt;

  const TicketComment({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    this.editedAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'] as String? ?? '',
      author: json['author'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      editedAt: json['editedAt'] as String?,
    );
  }
}

class Ticket {
  final String id; // e.g. "PA-001"
  final String project;
  final String title;
  final String? summary;
  final String? description;
  final String status; // idea|requirement-review|pending-approval|pending-implementation|implementing|review-uat|done|rejected|cancelled|on-hold
  final String priority; // critical|high|medium|low|normal
  final String? type; // feature|bug|task|review-request|work-report|fyi|idea|question
  final String? team;
  final String? assignee;
  final String? estimate; // XS|S|M|L|XL
  final String? from;
  final String? to;
  final List<String> tags;
  final List<String> dependencies;
  final List<String> attachments;
  final String? docRef;
  final List<TicketComment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const Ticket({
    required this.id,
    required this.project,
    required this.title,
    this.summary,
    this.description,
    required this.status,
    required this.priority,
    this.type,
    this.team,
    this.assignee,
    this.estimate,
    this.from,
    this.to,
    required this.tags,
    required this.dependencies,
    required this.attachments,
    this.docRef,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final tagsList = json['tags'] as List? ?? [];
    final depsList = json['dependencies'] as List? ?? [];
    final attachmentsList = json['attachments'] as List? ?? [];
    final commentsList = json['comments'] as List? ?? [];

    return Ticket(
      id: json['id'] as String? ?? '',
      project: json['project'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'idea',
      priority: json['priority'] as String? ?? 'normal',
      type: json['type'] as String?,
      team: json['team'] as String?,
      assignee: json['assignee'] as String?,
      estimate: json['estimate'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      tags: tagsList.map((e) => e as String).toList(),
      dependencies: depsList.map((e) => e as String).toList(),
      attachments: attachmentsList.map((e) => e as String).toList(),
      docRef: json['doc_ref'] as String?,
      comments: commentsList
          .map((e) => TicketComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }
}

class BoardColumn {
  final String status;
  final List<Ticket> tickets;
  final int count;

  const BoardColumn({
    required this.status,
    required this.tickets,
    required this.count,
  });

  factory BoardColumn.fromJson(Map<String, dynamic> json) {
    final ticketsList = json['tickets'] as List? ?? [];
    return BoardColumn(
      status: json['status'] as String? ?? '',
      tickets: ticketsList
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int? ?? 0,
    );
  }
}

class BoardView {
  final String project;
  final List<BoardColumn> columns;
  final int total;
  final Map<String, int> teamCounts;

  const BoardView({
    required this.project,
    required this.columns,
    required this.total,
    required this.teamCounts,
  });

  factory BoardView.fromJson(Map<String, dynamic> json) {
    final columnsList = json['columns'] as List? ?? [];
    final teamCountsRaw = json['teamCounts'] as Map<String, dynamic>? ?? {};
    return BoardView(
      project: json['project'] as String? ?? '',
      columns: columnsList
          .map((e) => BoardColumn.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      teamCounts: teamCountsRaw.map((k, v) => MapEntry(k, v as int)),
    );
  }
}
