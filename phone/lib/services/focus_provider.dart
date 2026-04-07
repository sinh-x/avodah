import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/focus_item.dart';
import 'agent_api_client.dart';

const _prefEnrichEnabled = 'focus_enrich_enabled';
const _prefViewMode = 'focus_view_mode';

enum FocusViewMode { board, focus }

/// Provides GTD focus view state with polling support.
///
/// Fetches cross-project focus items from GET /api/focus.
/// Polls every 30 seconds when started. Supports project/assignee filtering
/// and enrich toggle for AI suggestions.
class FocusProvider extends ChangeNotifier {
  final AgentApiClient _client;

  FocusResult? _result;
  bool _loading = false;
  String? _error;
  String? _selectedProject;
  String? _selectedAssignee;
  bool _enrichEnabled = false;
  FocusViewMode _viewMode = FocusViewMode.board;
  Timer? _pollTimer;
  SharedPreferences? _prefs;

  FocusProvider(this._client) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _enrichEnabled = _prefs?.getBool(_prefEnrichEnabled) ?? false;
    final viewModeIndex = _prefs?.getInt(_prefViewMode) ?? 0;
    _viewMode = FocusViewMode.values[viewModeIndex];
  }

  // --- Getters ---

  FocusResult? get result => _result;
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedProject => _selectedProject;
  String? get selectedAssignee => _selectedAssignee;
  bool get enrichEnabled => _enrichEnabled;
  FocusViewMode get viewMode => _viewMode;

  /// All focus items from the last fetch.
  List<FocusItem> get allFocusItems => _result?.focus ?? [];

  /// Filtered focus items based on selected project and assignee.
  List<FocusItem> get filteredFocusItems {
    var items = allFocusItems;

    if (_selectedProject != null && _selectedProject!.isNotEmpty) {
      items = items.where((i) => i.project == _selectedProject).toList();
    }

    if (_selectedAssignee != null && _selectedAssignee!.isNotEmpty) {
      items = items.where((i) => i.assignee == _selectedAssignee).toList();
    }

    return items;
  }

  /// WIP summary from the last fetch.
  WipSummary? get wipSummary => _result?.wip;

  /// Available projects (unique, from focus items).
  List<String> get availableProjects {
    final projects = allFocusItems.map((i) => i.project).toSet().toList();
    projects.sort();
    return projects;
  }

  /// Available assignees (unique, from focus items).
  List<String> get availableAssignees {
    final assignees = allFocusItems
        .map((i) => i.assignee)
        .where((a) => a != null)
        .cast<String>()
        .toSet()
        .toList();
    assignees.sort();
    return assignees;
  }

  // --- Setters ---

  void setProject(String? project) {
    _selectedProject = project;
    notifyListeners();
  }

  void setAssignee(String? assignee) {
    _selectedAssignee = assignee;
    notifyListeners();
  }

  void setEnrichEnabled(bool enabled) {
    if (_enrichEnabled == enabled) return;
    _enrichEnabled = enabled;
    _prefs?.setBool(_prefEnrichEnabled, enabled);
    notifyListeners();
    refresh();
  }

  void setViewMode(FocusViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _prefs?.setInt(_prefViewMode, mode.index);
    notifyListeners();
  }

  // --- Data loading ---

  /// Fetch focus data from the API.
  Future<void> refresh() async {
    final wasEmpty = _result == null;
    if (wasEmpty) {
      _loading = true;
      notifyListeners();
    }

    try {
      _result = await _client.getFocus(enrich: _enrichEnabled);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('FocusProvider refresh error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- Polling ---

  /// Start polling for focus updates every 30 seconds.
  void startPolling() {
    refresh();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refresh();
    });
  }

  /// Stop polling.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}