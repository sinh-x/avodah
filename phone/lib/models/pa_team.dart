/// Model for a PA team with its deploy modes.
///
/// Deserialized from GET /api/pa-teams response.
class PaTeam {
  final String name;
  final String description;
  final List<DeployMode> deployModes;

  const PaTeam({
    required this.name,
    required this.description,
    required this.deployModes,
  });

  factory PaTeam.fromJson(Map<String, dynamic> json) {
    final modes = (json['deploy_modes'] as List?)
            ?.map((e) => DeployMode.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return PaTeam(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      deployModes: modes,
    );
  }
}

/// A single deploy mode for a PA team (phone-visible only).
class DeployMode {
  final String id;
  final String label;

  const DeployMode({required this.id, required this.label});

  factory DeployMode.fromJson(Map<String, dynamic> json) {
    return DeployMode(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}
