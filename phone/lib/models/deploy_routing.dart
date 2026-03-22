import 'pa_team.dart';

/// Result of GET /api/deploy-routing.
///
/// Returns all teams with non-interactive deploy modes and available repos.
/// Server already filters out interactive modes, so all returned modes are
/// safe to display.
class DeployRouting {
  final List<RoutingTeam> teams;
  final List<PaRepo> repos;

  const DeployRouting({required this.teams, required this.repos});

  factory DeployRouting.fromJson(Map<String, dynamic> json) {
    return DeployRouting(
      teams: (json['teams'] as List?)
              ?.map((e) => RoutingTeam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      repos: (json['repos'] as List?)
              ?.map((e) => PaRepo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert teams to [PaTeam] list for use with [DeploySheet].
  List<PaTeam> toPaTeams() => teams.map((t) => t.toPaTeam()).toList();
}

/// A team entry from GET /api/deploy-routing.
class RoutingTeam {
  final String name;
  final String description;
  final List<RoutingMode> modes;

  const RoutingTeam({
    required this.name,
    required this.description,
    required this.modes,
  });

  factory RoutingTeam.fromJson(Map<String, dynamic> json) {
    return RoutingTeam(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      modes: (json['modes'] as List?)
              ?.map((e) => RoutingMode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert to [PaTeam] for use with [DeploySheet].
  PaTeam toPaTeam() => PaTeam(
        name: name,
        description: description,
        deployModes: modes
            .map((m) => DeployMode(id: m.id, label: m.label, modeType: m.modeType))
            .toList(),
      );
}

/// A deploy mode from GET /api/deploy-routing.
///
/// Uses camelCase JSON keys (modeType) unlike [DeployMode] which uses
/// snake_case (mode_type) from GET /api/pa-teams.
class RoutingMode {
  final String id;
  final String label;
  final String? modeType;

  const RoutingMode({required this.id, required this.label, this.modeType});

  factory RoutingMode.fromJson(Map<String, dynamic> json) {
    return RoutingMode(
      id: json['id'] as String,
      label: json['label'] as String,
      modeType: json['modeType'] as String?,
    );
  }
}
