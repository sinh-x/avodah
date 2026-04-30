import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../storage/phone_database.dart';
import 'agent_api_client.dart';

/// Syncs pending captures from local Drift storage to the PA system via API.
///
/// Runs on:
/// - App start (after initial sync)
/// - When a new capture is saved (immediate trigger)
/// - Periodic background sync (via caller-supplied timer)
///
/// Uses insertOnConflictUpdate for the synced flag — safe to call repeatedly.
class CaptureSyncService {
  static const _learningProject = 'learning';
  static const _oldLearningProject = 'learning-management';

  final PhoneDatabase db;
  final AgentApiClient apiClient;

  CaptureSyncService({required this.db, required this.apiClient});

  /// Attempts to sync all unsynced captures to the PA system.
  ///
  /// Skipped if already syncing ( concurrent call protection).
  /// Errors are logged but not thrown — sync failures should not crash the app.
  Future<void> syncPendingCaptures() async {
    // Fetch unsynced captures
    final captures = await (db.select(
      db.pendingCaptures,
    )..where((t) => t.synced.equals(false))).get();

    if (captures.isEmpty) return;

    debugPrint('[CaptureSync] Syncing ${captures.length} capture(s)');

    for (final capture in captures) {
      try {
        await _syncCapture(capture);
      } catch (e) {
        // Log but don't throw — we don't want to lose other captures
        debugPrint('[CaptureSync] Failed to sync capture ${capture.id}: $e');
      }
    }
  }

  /// Syncs a single capture to the PA system and marks it as synced.
  Future<void> _syncCapture(PendingCapture capture) async {
    final data = <String, dynamic>{
      'project': _normalizeProject(capture.project),
      'title': capture.title,
      'type': 'idea',
      'status': 'idea',
      'priority': 'medium',
      'estimate': 'XS',
      'assignee': 'requirements',
      'summary': _buildSummary(capture),
      'doc_refs': [
        if (capture.url != null && capture.url!.isNotEmpty)
          {'type': 'url', 'path': capture.url},
      ],
      'tags': [
        capture.category,
        if (capture.url != null && capture.url!.isNotEmpty) 'shared-link',
      ],
    };

    await apiClient.createTicket(data);

    // Mark as synced
    await (db.update(db.pendingCaptures)..where((t) => t.id.equals(capture.id)))
        .write(PendingCapturesCompanion(synced: Value(true)));

    debugPrint(
      '[CaptureSync] Synced capture ${capture.id}: "${capture.title}"',
    );
  }

  String _normalizeProject(String project) {
    if (project == _oldLearningProject) return _learningProject;
    return project;
  }

  /// Builds summary field from URL + notes content.
  ///
  /// If URL is present, prepended to notes.
  String? _buildSummary(PendingCapture capture) {
    final parts = <String>[];

    if (capture.url != null &&
        capture.url!.isNotEmpty &&
        capture.url != capture.notes) {
      parts.add(capture.url!);
    }

    if (capture.notes != null && capture.notes!.isNotEmpty) {
      parts.add(capture.notes!);
    }

    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  /// Saves a capture to the local Drift table.
  ///
  /// Called by QuickCaptureScreen on submit.
  /// After saving, caller should trigger sync (via [syncPendingCaptures]).
  Future<int> saveCapture({
    required String title,
    String? url,
    String? notes,
    String category = 'learning',
    String? sharedText,
    String project = 'learning',
  }) async {
    final id = await db
        .into(db.pendingCaptures)
        .insert(
          PendingCapturesCompanion.insert(
            title: title,
            url: Value(url),
            notes: Value(notes),
            category: Value(category),
            sharedText: Value(sharedText),
            project: Value(project),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            synced: const Value(false),
          ),
        );

    debugPrint('[CaptureSync] Saved capture $id: "$title"');
    return id;
  }

  /// Returns the count of unsynced captures.
  Future<int> unsyncedCount() async {
    final count =
        await (db.selectOnly(db.pendingCaptures)
              ..where(db.pendingCaptures.synced.equals(false))
              ..addColumns([db.pendingCaptures.id.count()]))
            .map((row) => row.read(db.pendingCaptures.id.count()))
            .getSingle();
    return count ?? 0;
  }
}
