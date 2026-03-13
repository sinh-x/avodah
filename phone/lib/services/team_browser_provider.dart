import 'package:flutter/foundation.dart';

import '../models/review_item.dart';
import '../models/team_folder.dart';
import 'agent_api_client.dart';

/// Provides agent team browsing — teams, folders, files.
class TeamBrowserProvider extends ChangeNotifier {
  final AgentApiClient _client;

  List<TeamFolder> _teams = [];
  List<TeamFile> _files = [];
  bool _loading = false;
  String? _error;

  TeamBrowserProvider(this._client);

  List<TeamFolder> get teams => _teams;
  List<TeamFile> get files => _files;
  bool get loading => _loading;
  String? get error => _error;

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
