/// Data model for an agent team and its folder listing.
class TeamFolder {
  final String name;
  final List<String> folders;
  final int inboxCount;
  final int ongoingCount;
  final int wfrCount;

  const TeamFolder({
    required this.name,
    required this.folders,
    this.inboxCount = 0,
    this.ongoingCount = 0,
    this.wfrCount = 0,
  });

  factory TeamFolder.fromJson(Map<String, dynamic> json) {
    return TeamFolder(
      name: json['name'] as String,
      folders: (json['folders'] as List).cast<String>(),
      inboxCount: json['inbox_count'] as int? ?? 0,
      ongoingCount: json['ongoing_count'] as int? ?? 0,
      wfrCount: json['wfr_count'] as int? ?? 0,
    );
  }
}

/// Data model for a file within an agent team folder.
class TeamFile {
  final String name;
  final int size;
  final DateTime modified;

  const TeamFile({
    required this.name,
    required this.size,
    required this.modified,
  });

  factory TeamFile.fromJson(Map<String, dynamic> json) {
    return TeamFile(
      name: json['name'] as String,
      size: json['size'] as int? ?? 0,
      modified: DateTime.parse(json['modified'] as String),
    );
  }
}
