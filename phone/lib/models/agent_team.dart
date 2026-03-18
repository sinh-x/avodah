/// Model for an agent team entry from GET /api/agent-teams.
///
/// Used by [DestinationTeamSelector] to populate the routing dropdown.
class AgentTeam {
  final String name;
  final bool inboxExists;

  const AgentTeam({required this.name, required this.inboxExists});

  factory AgentTeam.fromJson(Map<String, dynamic> json) {
    return AgentTeam(
      name: json['name'] as String,
      inboxExists: json['inbox_exists'] as bool? ?? false,
    );
  }
}
