import 'package:flutter/foundation.dart';

import '../models/deploy_result.dart';
import '../models/pa_team.dart';
import '../models/review_item.dart';
import '../models/team_folder.dart';
import 'agent_api_client.dart';

/// Provides agent team browsing — teams, folders, files, and PA deploy.
class TeamBrowserProvider extends ChangeNotifier {
  final AgentApiClient _client;

  List<TeamFolder> _teams = [];
  List<TeamFile> _files = [];
  List<PaTeam> _paTeams = [];
  List<PaRepo> _paRepos = [];
  bool _loading = false;
  String? _error;

  TeamBrowserProvider(this._client);

  List<TeamFolder> get teams => _teams;
  List<TeamFile> get files => _files;
  List<PaTeam> get paTeams => _paTeams;
  List<PaRepo> get paRepos => _paRepos;
  bool get loading => _loading;
  String? get error => _error;

  /// Return the PA team config for [teamName], or null if not deployable.
  PaTeam? paTeamFor(String teamName) {
    try {
      return _paTeams.firstWhere((t) => t.name == teamName);
    } catch (_) {
      return null;
    }
  }

  /// Fetch PA teams with deploy modes.
  Future<void> loadPaTeams() async {
    try {
      _paTeams = await _client.listPaTeams();
      notifyListeners();
    } catch (e) {
      debugPrint('TeamBrowserProvider loadPaTeams error: $e');
    }
  }

  /// Fetch PA repos from the repos registry.
  Future<void> loadRepos() async {
    try {
      _paRepos = await _client.listPaRepos();
      notifyListeners();
    } catch (e) {
      debugPrint('TeamBrowserProvider loadRepos error: $e');
    }
  }

  /// Trigger a PA team deployment.
  ///
  /// Optional [repo] passes `--repo <name>` to PA for codebase-aware modes.
  Future<DeployResult> deploy(String team, String mode,
      {String? objective, String? repo}) {
    return _client.triggerDeployment(team, mode,
        objective: objective, repo: repo);
  }

  /// Fetch team list.
  Future<void> refreshTeams() async {
    _loading = true;
    notifyListeners();

    try {
      _teams = await _client.listTeams();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('TeamBrowserProvider refreshTeams error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch files in a team folder.
  Future<void> loadFolder(String team, String folder) async {
    _loading = true;
    _files = [];
    notifyListeners();

    try {
      _files = await _client.listTeamFolder(team, folder);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('TeamBrowserProvider loadFolder error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch files in a team folder and return directly (no shared state update).
  Future<List<TeamFile>> fetchFolder(String team, String folder) async {
    return _client.listTeamFolder(team, folder);
  }

  /// Read a file from a team folder.
  Future<ReviewItem> readFile(
      String team, String folder, String filename) async {
    return _client.getTeamFile(team, folder, filename);
  }
}
