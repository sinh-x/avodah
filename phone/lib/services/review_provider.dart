import 'dart:async';

import 'package:flutter/foundation.dart';

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
  Future<void> approve(String filename) async {
    await _client.approveItem(filename);
    _items.removeWhere((item) => item.id == filename);
    notifyListeners();
  }

  /// Reject an item with a reason and remove it from the local list.
  Future<void> reject(String filename, {String? reason}) async {
    await _client.rejectItem(filename, reason: reason);
    _items.removeWhere((item) => item.id == filename);
    notifyListeners();
  }

  /// Defer an item and remove it from the local list.
  Future<void> defer(String filename) async {
    await _client.deferItem(filename);
    _items.removeWhere((item) => item.id == filename);
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
