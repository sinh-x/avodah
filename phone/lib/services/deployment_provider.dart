import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/deployment.dart';
import 'agent_api_client.dart';

/// Provides deployment status data with filtering.
class DeploymentProvider extends ChangeNotifier {
  final AgentApiClient _client;

  List<Deployment> _deployments = [];
  bool _loading = false;
  String? _error;
  String? _filterTeam;
  String? _filterStatus;

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

  /// Fetch deployments from the API.
  Future<void> refresh() async {
    _loading = true;
    notifyListeners();

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
  }
}
