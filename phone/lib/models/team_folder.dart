/// Data model for an agent team and its folder listing.
class TeamFolder {
  final String name;
  final List<String> folders;

  const TeamFolder({required this.name, required this.folders});

  factory TeamFolder.fromJson(Map<String, dynamic> json) {
    return TeamFolder(
      name: json['name'] as String,
      folders: (json['folders'] as List).cast<String>(),
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
