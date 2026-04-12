// Kanban board status constants.
//
// Used by both the main Kanban board (BoardProvider) and the backlog
// view (BacklogProvider) to categorize ticket statuses.

/// Active kanban columns — tickets in active sprint workflow.
const activeStatuses = {'implementing', 'review-uat'};

/// Terminal columns — tickets that are done and out of workflow.
const terminalStatuses = {'done', 'rejected', 'cancelled'};

/// Backlog statuses — tickets that are inactive but not yet terminal.
///
/// The backlog is the union of:
/// - tickets with 'backlog' tag (tag-based backlog)
/// - tickets with status in this set (status-based backlog)
const backlogStatuses = {
  'idea',
  'on-hold',
  'requirement-review',
  'pending-approval',
  'pending-implementation',
};
