import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists and restores partial deploy form data across app sessions.
///
/// Used to restore user input when they revisit the deploy screen
/// after navigating away or switching apps.
class DeployDraftService {
  DeployDraftService._();

  static const String _key = 'deploy_draft';

  static Timer? _saveTimer;

  /// Saves [draft] asynchronously to SharedPreferences with 500ms debounce.
  static Future<void> saveDraft(DeployDraft draft) async {
    _saveTimer?.cancel();
    final completer = Completer<void>();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final json = jsonEncode(draft.toJson());
        await prefs.setString(_key, json);
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    });
    return completer.future;
  }

  /// Loads the saved draft, or null if none exists.
  static Future<DeployDraft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return DeployDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clears any saved draft.
  static Future<void> clearDraft() async {
    _saveTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Partial deploy form state captured as a draft.
///
/// All fields are optional so the draft can be saved incrementally.
class DeployDraft {
  final String? team;
  final String? mode;
  final String? repo;
  final String? provider;
  final String? model;
  final String? objective;

  const DeployDraft({
    this.team,
    this.mode,
    this.repo,
    this.provider,
    this.model,
    this.objective,
  });

  Map<String, dynamic> toJson() => {
        'team': team,
        'mode': mode,
        'repo': repo,
        'provider': provider,
        'model': model,
        'objective': objective,
      };

  factory DeployDraft.fromJson(Map<String, dynamic> json) => DeployDraft(
        team: json['team'] as String?,
        mode: json['mode'] as String?,
        repo: json['repo'] as String?,
        provider: json['provider'] as String?,
        model: json['model'] as String?,
        objective: json['objective'] as String?,
      );
}
