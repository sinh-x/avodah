import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/deployment.dart';
import 'agent_api_client.dart';

/// Provides deployment status data with filtering and auto-refresh.
///
/// Auto-refresh polls every 7 seconds when any deployment is running,
/// and stops automatically when no running deployments remain.
class DeploymentProvider extends ChangeNotifier {
  final AgentApiClient _client;

  List<Deployment> _deployments = [];
  bool _loading = false;
  String? _error;
  String? _filterTeam;
  String? _filterStatus;
  Timer? _refreshTimer;

  DeploymentProvider(this._client);

  List<Deployment> get deployments {
    var result = _deployments;
    if (_filterTeam != null) {
      result = result.where((d) => d.team == _filterTeam).toList();
    }
    if (_filterStatus != null) {
      result = result.where((d) => d.status == _filterStatus).toList();
    }
    return result;
  }

  List<Deployment> get allDeployments => _deployments;
  bool get loading => _loading;
  String? get error => _error;
  String? get filterTeam => _filterTeam;
  String? get filterStatus => _filterStatus;

  bool get hasRunning => _deployments.any((d) => d.isRunning);

  /// Get unique team names from all deployments.
  List<String> get availableTeams {
    final teams = _deployments.map((d) => d.team).toSet().toList();
    teams.sort();
    return teams;
  }

  /// Get unique statuses from all deployments.
  List<String> get availableStatuses {
    final statuses = _deployments.map((d) => d.status).toSet().toList();
    statuses.sort();
    return statuses;
  }

  void setFilterTeam(String? team) {
    _filterTeam = team;
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  /// Start auto-refresh. Fetches immediately, then polls every 7s while
  /// running deployments exist. Call once after construction.
  void startAutoRefresh() {
    refresh();
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 7), () async {
      await refresh();
      // Continue polling only if deployments are running.
      if (hasRunning) {
        _scheduleRefresh();
      }
    });
  }

  /// Fetch deployments from the API and restart auto-refresh if needed.
  Future<void> refresh() async {
    // Avoid loading flicker on background refreshes.
    final wasEmpty = _deployments.isEmpty;
    if (wasEmpty) {
      _loading = true;
      notifyListeners();
    }

    try {
      _deployments = await _client.listDeployments();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('DeploymentProvider refresh error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }

    // Resume auto-refresh if running deployments appeared.
    if (hasRunning && _refreshTimer == null) {
      _scheduleRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
