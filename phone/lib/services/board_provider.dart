import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bulletin.dart';
import '../models/ticket.dart';
import 'agent_api_client.dart';

/// Kanban board status categorization.
const _activeStatuses = {
  'idea',
  'requirement-review',
  'pending-approval',
  'pending-implementation',
  'implementing',
  'review-uat',
};

const _terminalStatuses = {
  'done',
  'rejected',
  'cancelled',
};

/// Provides kanban board state with polling support.
///
/// Fetches board columns and bulletins from the PA ticket API.
/// Polls every 30 seconds when started. Supports project/team filtering
/// and toggling visibility of terminal columns (done/rejected/cancelled).
class BoardProvider extends ChangeNotifier {
  final AgentApiClient _client;

  BoardView? _board;
  List<Bulletin> _bulletins = [];
  List<TicketProject> _projects = [];
  bool _loading = false;
  String? _error;
  String _selectedProject = 'personal-assistant';
  String? _selectedTeam;
  bool _showTerminal = false;
  Timer? _pollTimer;

  BoardProvider(this._client);

  // --- Client access ---

  /// Exposes the underlying API client for direct ticket/bulletin operations.
  AgentApiClient get client => _client;

  // --- Getters ---

  BoardView? get board => _board;
  List<Bulletin> get bulletins => _bulletins;
  List<TicketProject> get projects => _projects;
  bool get loading => _loading;
  String? get error => _error;
  String get selectedProject => _selectedProject;
  String? get selectedTeam => _selectedTeam;
  bool get showTerminal => _showTerminal;

  /// Active (non-terminal, non-on-hold) columns in kanban order.
  List<BoardColumn> get activeColumns {
    if (_board == null) return [];
    return _board!.columns
        .where((c) => _activeStatuses.contains(c.status))
        .toList();
  }

  /// Terminal columns: done, rejected, cancelled.
  List<BoardColumn> get terminalColumns {
    if (_board == null) return [];
    return _board!.columns
        .where((c) => _terminalStatuses.contains(c.status))
        .toList();
  }

  /// The on-hold column, if present.
  BoardColumn? get onHoldColumn {
    if (_board == null) return null;
    try {
      return _board!.columns.firstWhere((c) => c.status == 'on-hold');
    } catch (_) {
      return null;
    }
  }

  /// Count of tickets requiring Sinh's action: pending-approval + review-uat.
  int get actionableCount {
    if (_board == null) return 0;
    int count = 0;
    for (final col in _board!.columns) {
      if (col.status == 'pending-approval' || col.status == 'review-uat') {
        count += col.count;
      }
    }
    return count;
  }

  /// Active bulletins only.
  List<Bulletin> get activeBulletins =>
      _bulletins.where((b) => b.isActive).toList();

  // --- Setters ---

  void setProject(String project) {
    if (_selectedProject == project) return;
    _selectedProject = project;
    notifyListeners();
    refresh();
  }

  void setTeam(String? team) {
    if (_selectedTeam == team) return;
    _selectedTeam = team;
    notifyListeners();
    refresh();
  }

  void toggleTerminal() {
    _showTerminal = !_showTerminal;
    notifyListeners();
  }

  // --- Data loading ---

  /// Fetch board and bulletins from the API.
  Future<void> refresh() async {
    final wasEmpty = _board == null;
    if (wasEmpty) {
      _loading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _client.getBoard(project: _selectedProject, team: _selectedTeam),
        _client.getBulletins(),
        _client.getTicketProjects(),
      ]);
      _board = results[0] as BoardView;
      _bulletins = results[1] as List<Bulletin>;
      _projects = results[2] as List<TicketProject>;
      // Update selected project to first alphabetically if current selection
      // is not in the project list (and projects are available).
      if (_projects.isNotEmpty &&
          !_projects.any((p) => p.key == _selectedProject)) {
        _selectedProject = (_projects.map((p) => p.key).toList()..sort()).first;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('BoardProvider refresh error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Optimistically update a ticket's status, rolling back on failure.
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    // Capture old state for rollback
    final oldBoard = _board;

    // Optimistic update: rebuild board with new status
    if (_board != null) {
      _board = _buildBoardWithUpdatedTicket(_board!, ticketId, newStatus);
      notifyListeners();
    }

    try {
      await _client.updateTicket(ticketId, {'status': newStatus});
      // Refresh to get authoritative state
      await refresh();
    } catch (e) {
      // Rollback on failure
      _board = oldBoard;
      _error = e.toString();
      debugPrint('BoardProvider updateTicketStatus error: $e');
      notifyListeners();
    }
  }

  // --- Polling ---

  /// Start polling for board updates every 30 seconds.
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

  // --- Private helpers ---

  /// Rebuild a BoardView with one ticket moved to a new status column.
  BoardView _buildBoardWithUpdatedTicket(
      BoardView board, String ticketId, String newStatus) {
    Ticket? movedTicket;

    // Remove ticket from its current column
    final updatedColumns = board.columns.map((col) {
      final idx = col.tickets.indexWhere((t) => t.id == ticketId);
      if (idx == -1) return col;
      movedTicket = col.tickets[idx];
      final newTickets = List<Ticket>.from(col.tickets)..removeAt(idx);
      return BoardColumn(
        status: col.status,
        tickets: newTickets,
        count: col.count - 1,
      );
    }).toList();

    if (movedTicket == null) return board;

    // Add ticket to the target column (create column if missing)
    final targetIdx =
        updatedColumns.indexWhere((c) => c.status == newStatus);
    if (targetIdx != -1) {
      final col = updatedColumns[targetIdx];
      updatedColumns[targetIdx] = BoardColumn(
        status: col.status,
        tickets: [movedTicket!, ...col.tickets],
        count: col.count + 1,
      );
    } else {
      updatedColumns.add(BoardColumn(
        status: newStatus,
        tickets: [movedTicket!],
        count: 1,
      ));
    }

    return BoardView(
      project: board.project,
      columns: updatedColumns,
      total: board.total,
      teamCounts: board.teamCounts,
    );
  }
}
