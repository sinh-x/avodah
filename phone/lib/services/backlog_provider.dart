import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ticket.dart';
import 'agent_api_client.dart';

/// Sentinel value to distinguish "not provided" from explicit null in copyWith.
const _sentinel = Object();

/// Filter state for the backlog view.
class BacklogFilter {
  final String? project;
  final List<String> assignees;
  final List<String> priorities;
  final List<String> tags;
  final String searchQuery;

  const BacklogFilter({
    this.project,
    this.assignees = const [],
    this.priorities = const [],
    this.tags = const [],
    this.searchQuery = '',
  });

  BacklogFilter copyWith({
    Object? project = _sentinel,
    List<String>? assignees,
    List<String>? priorities,
    List<String>? tags,
    String? searchQuery,
  }) {
    return BacklogFilter(
      project: identical(project, _sentinel) ? this.project : project as String?,
      assignees: assignees ?? this.assignees,
      priorities: priorities ?? this.priorities,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Returns true if no filters are active.
  bool get isEmpty =>
      project == null &&
      assignees.isEmpty &&
      priorities.isEmpty &&
      tags.isEmpty &&
      searchQuery.isEmpty;
}

/// Manages backlog state: ticket list, filters, and multi-select.
///
/// Fetches the combined tag-based and status-based backlog from the API,
/// applies client-side filtering, and maintains selection state for
/// bulk operations.
class BacklogProvider extends ChangeNotifier {
  final AgentApiClient _client;

  List<Ticket> _allTickets = [];
  BacklogFilter _filter = const BacklogFilter();
  Set<String> _selectedIds = {};
  bool _loading = false;
  String? _error;
  Timer? _debounceTimer;
  List<TicketProject> _projects = [];

  BacklogProvider(this._client);

  // --- Getters ---

  List<Ticket> get tickets => _applyFilter(_allTickets);
  List<Ticket> get allTickets => _allTickets;
  BacklogFilter get filter => _filter;
  Set<String> get selectedIds => _selectedIds;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasSelection => _selectedIds.isNotEmpty;
  int get selectionCount => _selectedIds.length;
  bool get allSelected =>
      tickets.isNotEmpty && _selectedIds.length == tickets.length;

  /// Total backlog count (unfiltered) for badge display.
  int get totalCount => _allTickets.length;

  /// Available projects for filtering.
  List<TicketProject> get projects => _projects;

  // --- Client access ---

  AgentApiClient get client => _client;

  // --- Data loading ---

  /// Fetch the full backlog from the API.
  Future<void> fetchBacklog() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch projects and backlog in parallel
      final results = await Future.wait([
        _client.getProjects(),
        _client.getBacklog(
          project: _filter.project,
          assignee: _filter.assignees.isNotEmpty ? _filter.assignees.join(',') : null,
          priority: _filter.priorities.isNotEmpty ? _filter.priorities.join(',') : null,
          tags: _filter.tags.isNotEmpty ? _filter.tags.join(',') : null,
        ),
      ]);
      _projects = results[0] as List<TicketProject>;
      _allTickets = results[1] as List<Ticket>;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('BacklogProvider fetchBacklog error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh — re-fetch from API preserving selection.
  Future<void> refresh() async {
    await fetchBacklog();
  }

  // --- Filter methods ---

  /// Update the filter and re-apply client-side filtering.
  ///
  /// [searchQuery] is debounced (300ms) before applying.
  void applyFilter({
    String? project,
    List<String>? assignees,
    List<String>? priorities,
    List<String>? tags,
    String? searchQuery,
  }) {
    _filter = _filter.copyWith(
      project: project,
      assignees: assignees,
      priorities: priorities,
      tags: tags,
      searchQuery: searchQuery,
    );

    // Debounce search to avoid excessive re-renders
    _debounceTimer?.cancel();
    if (searchQuery != null) {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  /// Set search query with debouncing.
  void setSearchQuery(String query) {
    applyFilter(searchQuery: query);
  }

  /// Set project filter.
  void setProject(String? project) {
    applyFilter(project: project);
  }

  /// Set assignee filter (replaces existing).
  void setAssignees(List<String> assignees) {
    applyFilter(assignees: assignees);
  }

  /// Set priority filter (replaces existing).
  void setPriorities(List<String> priorities) {
    applyFilter(priorities: priorities);
  }

  /// Set tags filter (replaces existing).
  void setTags(List<String> tags) {
    applyFilter(tags: tags);
  }

  /// Clear all filters.
  void clearFilters() {
    _filter = const BacklogFilter();
    _debounceTimer?.cancel();
    notifyListeners();
  }

  // --- Selection methods ---

  /// Select a single ticket by ID.
  void selectTicket(String id) {
    if (!_selectedIds.contains(id)) {
      _selectedIds = {..._selectedIds, id};
      notifyListeners();
    }
  }

  /// Deselect a single ticket by ID.
  void deselectTicket(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds = {..._selectedIds}..remove(id);
      notifyListeners();
    }
  }

  /// Toggle selection for a single ticket.
  void toggleTicket(String id) {
    if (_selectedIds.contains(id)) {
      deselectTicket(id);
    } else {
      selectTicket(id);
    }
  }

  /// Select all currently filtered tickets.
  void selectAll() {
    final filteredIds = tickets.map((t) => t.id).toSet();
    _selectedIds = {..._selectedIds, ...filteredIds};
    notifyListeners();
  }

  /// Deselect all tickets.
  void deselectAll() {
    _selectedIds = {};
    notifyListeners();
  }

  // --- Private helpers ---

  /// Apply client-side filter to ticket list.
  List<Ticket> _applyFilter(List<Ticket> source) {
    if (_filter.isEmpty) return List.from(source);

    final query = _filter.searchQuery.toLowerCase();

    return source.where((ticket) {
      // Project filter
      if (_filter.project != null &&
          ticket.project != _filter.project) {
        return false;
      }

      // Assignee filter
      if (_filter.assignees.isNotEmpty &&
          !_filter.assignees.contains(ticket.assignee)) {
        return false;
      }

      // Priority filter
      if (_filter.priorities.isNotEmpty &&
          !_filter.priorities.contains(ticket.priority)) {
        return false;
      }

      // Tags filter
      if (_filter.tags.isNotEmpty &&
          !_filter.tags.any((tag) => ticket.tags.contains(tag))) {
        return false;
      }

      // Free-text search: title and ticket ID
      if (query.isNotEmpty) {
        final matchesTitle = ticket.title.toLowerCase().contains(query);
        final matchesId = ticket.id.toLowerCase().contains(query);
        if (!matchesTitle && !matchesId) return false;
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // --- Activate a single ticket ---

  /// Activate a backlog ticket — removes 'backlog' tag if present and
  /// updates the status to [newStatus].
  Future<Ticket> activateTicket(String ticketId, String newStatus) async {
    final ticket = _allTickets.firstWhere((t) => t.id == ticketId);
    final updates = <String, dynamic>{'status': newStatus};
    if (ticket.tags.contains('backlog')) {
      final newTags = List<String>.from(ticket.tags)..remove('backlog');
      updates['tags'] = newTags;
    }
    final updated = await _client.updateTicket(ticketId, updates);
    await refresh();
    return updated;
  }
}
