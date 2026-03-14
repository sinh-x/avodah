import 'package:flutter/material.dart';

import '../models/review_item.dart';

/// Actions available in the inbox item action bar, keyed by type.
///
/// Each [DocumentTypeConfig.actions] list is ordered left-to-right as they
/// appear in the UI. Phases 3–6 consume this config to render the action bar,
/// type badge, and filter chips.
enum InboxAction {
  /// Full d-40e61d approve flow (review-request).
  approve,

  /// Full d-40e61d reject flow (review-request).
  reject,

  /// Defer to deferred/ (review-request, plan-draft).
  defer,

  /// Move to for-later/ (all types).
  saveForLater,

  /// Acknowledge work-report — fast-path clean move to done/ (optional note).
  acknowledge,

  /// Plan confirmed as-is — clean move to done/ (plan-draft fast-path).
  planLooksGood,

  /// Plan confirmed with changes — note dialog, then move to done/ (plan-draft).
  planHasChanges,

  /// FYI acknowledged — clean move to done/ (fyi fast-path).
  gotIt,
}

/// Badge and workflow configuration for a single document type.
class DocumentTypeConfig {
  /// Label displayed on the type badge chip (e.g. "REPORT").
  final String badgeLabel;

  /// Background color for the badge chip.
  final Color badgeColor;

  /// Whether items of this type count toward the inbox badge number.
  ///
  /// FYI items are excluded (informational only, no action required).
  final bool countInBadge;

  /// Sort priority within the inbox list (lower = higher urgency, sorts first).
  ///
  /// 0 = decision-needed, 1 = review-request, 2 = plan-draft,
  /// 3 = work-report, 4 = fyi.
  final int sortPriority;

  /// Ordered list of actions shown in the item detail action bar.
  final List<InboxAction> actions;

  const DocumentTypeConfig({
    required this.badgeLabel,
    required this.badgeColor,
    required this.countInBadge,
    required this.sortPriority,
    required this.actions,
  });
}

/// Per-type configuration map for all known inbox document types.
///
/// Add a new entry here (plus a dialog if needed) to support a new type.
/// Unknown types at runtime fall back to [DocumentType.workReport] via
/// [DocumentType.fromString], so no crash occurs for forward-compatible files.
const kDocumentTypeConfigs = <DocumentType, DocumentTypeConfig>{
  DocumentType.workReport: DocumentTypeConfig(
    badgeLabel: 'REPORT',
    badgeColor: Colors.blueGrey,
    countInBadge: true,
    sortPriority: 3,
    actions: [InboxAction.acknowledge, InboxAction.saveForLater],
  ),
  DocumentType.reviewRequest: DocumentTypeConfig(
    badgeLabel: 'REVIEW',
    badgeColor: Colors.deepPurple,
    countInBadge: true,
    sortPriority: 1,
    // Reject is leftmost to match d-40e61d layout; Approve is rightmost (primary).
    actions: [
      InboxAction.reject,
      InboxAction.defer,
      InboxAction.saveForLater,
      InboxAction.approve,
    ],
  ),
  DocumentType.planDraft: DocumentTypeConfig(
    badgeLabel: 'PLAN',
    badgeColor: Colors.blue,
    countInBadge: true,
    sortPriority: 2,
    actions: [
      InboxAction.planLooksGood,
      InboxAction.planHasChanges,
      InboxAction.defer,
      InboxAction.saveForLater,
    ],
  ),
  DocumentType.fyi: DocumentTypeConfig(
    badgeLabel: 'FYI',
    badgeColor: Colors.green,
    countInBadge: false,
    sortPriority: 4,
    actions: [InboxAction.gotIt],
  ),
  DocumentType.decisionNeeded: DocumentTypeConfig(
    badgeLabel: 'DECIDE',
    badgeColor: Colors.orange,
    countInBadge: true,
    sortPriority: 0,
    // Placeholder — full spec pending real examples (see requirements §13).
    actions: [InboxAction.approve, InboxAction.reject, InboxAction.defer],
  ),
};
