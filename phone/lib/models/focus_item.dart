// Data models for the GTD Focus view.
//
// Matches the API response shape from GET /api/focus.
// JSON keys are camelCase as returned by the server.

/// A single actionable item in the focus list.
class FocusItem {
  final String id;
  final String title;
  final String project;
  final String status;
  final String priority;
  final String? assignee;
  final int staleDays;
  final bool isBlocked;
  final List<String> blockerIds;
  final DateTime updatedAt;

  const FocusItem({
    required this.id,
    required this.title,
    required this.project,
    required this.status,
    required this.priority,
    this.assignee,
    required this.staleDays,
    required this.isBlocked,
    required this.blockerIds,
    required this.updatedAt,
  });

  factory FocusItem.fromJson(Map<String, dynamic> json) {
    final blockerIdsRaw = json['blockerIds'] as List? ?? [];
    return FocusItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      project: json['project'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      assignee: json['assignee'] as String?,
      staleDays: json['staleDays'] as int? ?? 0,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockerIds: blockerIdsRaw.map((e) => e as String).toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// WIP summary counts broken down by status and project.
class WipSummary {
  final Map<String, int> byStatus;
  final Map<String, int> byProject;
  final int total;

  const WipSummary({
    required this.byStatus,
    required this.byProject,
    required this.total,
  });

  factory WipSummary.fromJson(Map<String, dynamic> json) {
    final byStatusRaw = json['byStatus'] as Map<String, dynamic>? ?? {};
    final byProjectRaw = json['byProject'] as Map<String, dynamic>? ?? {};
    return WipSummary(
      byStatus: byStatusRaw.map((k, v) => MapEntry(k, v as int)),
      byProject: byProjectRaw.map((k, v) => MapEntry(k, v as int)),
      total: json['total'] as int? ?? 0,
    );
  }
}

/// An AI-generated suggestion for a focus item.
class FocusSuggestion {
  final String ticketId;
  final String action;
  final String reason;

  const FocusSuggestion({
    required this.ticketId,
    required this.action,
    required this.reason,
  });

  factory FocusSuggestion.fromJson(Map<String, dynamic> json) {
    return FocusSuggestion(
      ticketId: json['ticketId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}

/// Full response from GET /api/focus.
class FocusResult {
  final List<FocusItem> focus;
  final WipSummary wip;
  final List<FocusSuggestion>? suggestions;
  final int? reportAgeMinutes;

  const FocusResult({
    required this.focus,
    required this.wip,
    this.suggestions,
    this.reportAgeMinutes,
  });

  factory FocusResult.fromJson(Map<String, dynamic> json) {
    final focusList = json['focus'] as List? ?? [];
    final suggestionsList = json['suggestions'] as List?;
    return FocusResult(
      focus: focusList
          .map((e) => FocusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      wip: WipSummary.fromJson(json['wip'] as Map<String, dynamic>),
      suggestions: suggestionsList
          ?.map((e) => FocusSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      reportAgeMinutes: json['reportAgeMinutes'] as int?,
    );
  }
}