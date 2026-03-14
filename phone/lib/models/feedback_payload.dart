/// Data models for rich human feedback on review actions.
///
/// Used by the phone app to serialize API request bodies when the user
/// submits feedback alongside approve/reject/defer/save-for-later actions.
library;

/// The type of review action taken by the human reviewer.
enum FeedbackAction {
  approved('approved'),
  rejected('rejected'),
  deferred('deferred'),
  savedForLater('saved-for-later'),
  pendingRejectFeedback('pending-reject-feedback');

  final String apiValue;
  const FeedbackAction(this.apiValue);

  static FeedbackAction? fromApiValue(String value) {
    for (final e in FeedbackAction.values) {
      if (e.apiValue == value) return e;
    }
    return null;
  }
}

/// Priority level for a rejected item.
enum FeedbackPriority {
  high('high'),
  medium('medium'),
  low('low');

  final String apiValue;
  const FeedbackPriority(this.apiValue);

  static FeedbackPriority fromApiValue(String value) {
    for (final e in FeedbackPriority.values) {
      if (e.apiValue == value) return e;
    }
    return medium;
  }

  String get label => switch (this) {
        high => 'High',
        medium => 'Medium',
        low => 'Low',
      };
}

/// Feedback submitted alongside an Approve action.
///
/// All fields are optional — fast-path approve sends no body.
class ApproveFeedback {
  final String? note;
  final List<String> chips;

  const ApproveFeedback({this.note, this.chips = const []});

  bool get hasContent => (note?.isNotEmpty ?? false) || chips.isNotEmpty;

  Map<String, dynamic> toJson() => {
        if (note != null && note!.isNotEmpty) 'note': note,
        if (chips.isNotEmpty) 'chips': chips,
      };
}

/// Feedback submitted alongside a Reject action.
///
/// [whatIsWrong] and [whatToFix] are required for a full rejection.
/// Set [pending] to true to create a pending-reject-feedback state instead.
class RejectFeedback {
  final String whatIsWrong;
  final String whatToFix;
  final FeedbackPriority priority;
  final List<String> chips;
  final bool pending;

  const RejectFeedback({
    required this.whatIsWrong,
    required this.whatToFix,
    this.priority = FeedbackPriority.medium,
    this.chips = const [],
    this.pending = false,
  });

  /// Creates a pending-only rejection (no detail required).
  const RejectFeedback.pendingOnly()
      : whatIsWrong = '',
        whatToFix = '',
        priority = FeedbackPriority.medium,
        chips = const [],
        pending = true;

  Map<String, dynamic> toJson() {
    if (pending) return {'pending': true};
    return {
      'what_is_wrong': whatIsWrong,
      'what_to_fix': whatToFix,
      'priority': priority.apiValue,
      if (chips.isNotEmpty) 'chips': chips,
    };
  }
}

/// Feedback submitted alongside a Defer action.
///
/// All fields are optional — fast-path defer sends no body.
class DeferFeedback {
  final String? reason;
  final String? requeueAfter; // ISO date string "YYYY-MM-DD"
  final List<String> chips;

  const DeferFeedback({this.reason, this.requeueAfter, this.chips = const []});

  bool get hasContent =>
      (reason?.isNotEmpty ?? false) ||
      requeueAfter != null ||
      chips.isNotEmpty;

  Map<String, dynamic> toJson() => {
        if (reason != null && reason!.isNotEmpty) 'defer_reason': reason,
        if (requeueAfter != null) 'requeue_after': requeueAfter,
        if (chips.isNotEmpty) 'chips': chips,
      };
}
