import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists and restores partial ticket form data across app sessions.
///
/// Used to restore user input when they revisit the create ticket screen
/// after navigating away or switching apps.
class TicketDraftService {
  TicketDraftService._();

  static const String _key = 'ticket_draft';

  /// Saves [draft] asynchronously to SharedPreferences.
  static Future<void> saveDraft(TicketDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(draft.toJson());
    await prefs.setString(_key, json);
  }

  /// Loads the saved draft, or null if none exists.
  static Future<TicketDraft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return TicketDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clears any saved draft.
  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Partial ticket form state captured as a draft.
///
/// All fields are optional so the draft can be saved incrementally.
class TicketDraft {
  final String? project;
  final String? title;
  final String? typeName;
  final String? status;
  final String? team;
  final String? priority;
  final String? estimate;
  final Map<String, String> guidedValues;
  final String? freeformNotes;
  final List<String> imagePaths;

  const TicketDraft({
    this.project,
    this.title,
    this.typeName,
    this.status,
    this.team,
    this.priority,
    this.estimate,
    this.guidedValues = const {},
    this.freeformNotes,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toJson() => {
        'project': project,
        'title': title,
        'typeName': typeName,
        'status': status,
        'team': team,
        'priority': priority,
        'estimate': estimate,
        'guidedValues': guidedValues,
        'freeformNotes': freeformNotes,
        'imagePaths': imagePaths,
      };

  factory TicketDraft.fromJson(Map<String, dynamic> json) => TicketDraft(
        project: json['project'] as String?,
        title: json['title'] as String?,
        typeName: json['typeName'] as String?,
        status: json['status'] as String?,
        team: json['team'] as String?,
        priority: json['priority'] as String?,
        estimate: json['estimate'] as String?,
        guidedValues: (json['guidedValues'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
        freeformNotes: json['freeformNotes'] as String?,
        imagePaths: (json['imagePaths'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}
