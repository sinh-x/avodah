import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/feedback_payload.dart';
import '../models/review_item.dart';
import 'agent_api_client.dart';

/// Provides inbox review items with auto-refresh.
///
/// Fetches items from the agent workflow API and refreshes every 10 seconds.
class ReviewProvider extends ChangeNotifier {
  final AgentApiClient _client;

  List<ReviewItem> _items = [];
  bool _loading = false;
  String? _error;
  Timer? _refreshTimer;

  ReviewProvider(this._client);

  List<ReviewItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  int get pendingCount => _items.length;

  /// Start auto-refresh timer. Call once after construction.
  void startAutoRefresh() {
    refresh();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      refresh();
    });
  }

  /// Fetch inbox items from the API.
  Future<void> refresh() async {
    // Don't set loading=true on auto-refresh to avoid UI flicker
    final wasEmpty = _items.isEmpty;
    if (wasEmpty) {
      _loading = true;
      notifyListeners();
    }

    try {
      _items = await _client.listInbox();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('ReviewProvider refresh error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Get full item detail (with markdown content).
  Future<ReviewItem> getDetail(String filename) async {
    return _client.getInboxItem(filename);
  }

  /// Approve an item and remove it from the local list.
  ///
  /// Pass [feedback] to include optional note and chips.
  Future<void> approve(String filename, {ApproveFeedback? feedback}) async {
    await _client.approveItem(filename, feedback: feedback);
    _items.removeWhere((item) => item.id == filename);
    notifyListeners();
  }

  /// Reject an item with structured feedback and remove it from the local list.
  ///
  /// Use [RejectFeedback.pendingOnly()] to create a pending-reject-feedback state;
  /// the item stays in the inbox in that case and the list refreshes.
  Future<void> reject(String filename, RejectFeedback feedback) async {
    await _client.rejectItem(filename, feedback);
    if (feedback.pending) {
      // Item stays in inbox with pending status — refresh to get updated state
      await refresh();
    } else {
      _items.removeWhere((item) => item.id == filename);
      notifyListeners();
    }
  }

  /// Defer an item and remove it from the local list.
  ///
  /// Pass [feedback] to include optional note, date, and chips.
  Future<void> defer(String filename, {DeferFeedback? feedback}) async {
    await _client.deferItem(filename, feedback: feedback);
    _items.removeWhere((item) => item.id == filename);
    notifyListeners();
  }

  /// Move an item to for-later/ and remove it from the local list.
  Future<void> saveForLater(String filename) async {
    await _client.saveForLater(filename);
    _items.removeWhere((item) => item.id == filename);
    notifyListeners();
  }

  /// Append a named section to an item (item stays in inbox).
  Future<void> appendSection(
      String filename, String title, String content) async {
    await _client.appendSection(filename, title, content);
  }

  /// Fetch feedback chip labels from server config.
  Future<List<String>> getFeedbackChips() async {
    return _client.getFeedbackChips();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
