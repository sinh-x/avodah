// Data model for PA system bulletins.
//
// Matches the API response shape from pa serve /api/bulletin.
// The [block] field is either the String "all" or a List of team name strings.

class Bulletin {
  final String id;
  final String title;
  final dynamic block; // String "all" or List<String>
  final List<String> except;
  final String? message;
  final String status; // "active" or "resolved"
  final DateTime created;

  const Bulletin({
    required this.id,
    required this.title,
    required this.block,
    required this.except,
    this.message,
    required this.status,
    required this.created,
  });

  /// Whether this bulletin is currently active.
  bool get isActive => status == 'active';

  /// Whether this bulletin blocks all teams.
  bool get blocksAll => block == 'all';

  /// Returns the list of blocked teams, or empty list if blocks all.
  List<String> get blockedTeams {
    if (block is List) {
      return (block as List).map((e) => e as String).toList();
    }
    return [];
  }

  factory Bulletin.fromJson(Map<String, dynamic> json) {
    final exceptList = json['except'] as List? ?? [];
    return Bulletin(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      block: json['block'] ?? 'all',
      except: exceptList.map((e) => e as String).toList(),
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'active',
      created: DateTime.tryParse(json['created'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
