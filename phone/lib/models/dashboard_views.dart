// Data models for dashboard views from GET /api/dashboard/*.

/// Overview counts from GET /api/dashboard/overview.
class DashboardOverview {
  final Map<String, int> counts;
  final DashboardLimits limits;

  const DashboardOverview({required this.counts, required this.limits});

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    final countsRaw = json['counts'] as Map<String, dynamic>? ?? {};
    return DashboardOverview(
      counts: countsRaw.map((k, v) => MapEntry(k, v as int)),
      limits: DashboardLimits.fromJson(
          json['limits'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Limits for dashboard views.
class DashboardLimits {
  final int deployments;
  final int tickets;
  final int skills;
  final int improvementCandidates;

  const DashboardLimits({
    required this.deployments,
    required this.tickets,
    required this.skills,
    required this.improvementCandidates,
  });

  factory DashboardLimits.fromJson(Map<String, dynamic> json) {
    return DashboardLimits(
      deployments: json['deployments'] as int? ?? 200,
      tickets: json['tickets'] as int? ?? 500,
      skills: json['skills'] as int? ?? 250,
      improvementCandidates: json['improvementCandidates'] as int? ?? 500,
    );
  }
}

/// Deployments view from GET /api/dashboard/views/deployments.
class DashboardDeployments {
  final List<DeploymentStatus> deployments;
  final int count;

  const DashboardDeployments({required this.deployments, required this.count});

  factory DashboardDeployments.fromJson(Map<String, dynamic> json) {
    return DashboardDeployments(
      deployments: (json['deployments'] as List?)
              ?.map((e) => DeploymentStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      count: json['count'] as int? ?? 0,
    );
  }
}

/// A lightweight deployment status entry in dashboard views.
class DeploymentStatus {
  final String deployId;
  final String team;
  final String status;
  final String startedAt;
  final String? completedAt;
  final String? summary;

  const DeploymentStatus({
    required this.deployId,
    required this.team,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.summary,
  });

  factory DeploymentStatus.fromJson(Map<String, dynamic> json) {
    return DeploymentStatus(
      deployId: (json['deploy_id'] ?? json['deployment_id'] ?? '') as String,
      team: json['team'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startedAt: json['started_at'] as String? ?? '',
      completedAt: json['completed_at'] as String?,
      summary: json['summary'] as String?,
    );
  }
}

/// Tickets view from GET /api/dashboard/views/tickets.
class DashboardTickets {
  final List<TicketSummary> tickets;
  final int count;

  const DashboardTickets({required this.tickets, required this.count});

  factory DashboardTickets.fromJson(Map<String, dynamic> json) {
    return DashboardTickets(
      tickets: (json['tickets'] as List?)
              ?.map((e) => TicketSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      count: json['count'] as int? ?? 0,
    );
  }
}

/// A lightweight ticket summary in dashboard views.
class TicketSummary {
  final String id;
  final String project;
  final String title;
  final String status;
  final String priority;
  final String? assignee;

  const TicketSummary({
    required this.id,
    required this.project,
    required this.title,
    required this.status,
    required this.priority,
    this.assignee,
  });

  factory TicketSummary.fromJson(Map<String, dynamic> json) {
    return TicketSummary(
      id: json['id'] as String? ?? '',
      project: json['project'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      assignee: json['assignee'] as String?,
    );
  }
}

/// Skills view from GET /api/dashboard/views/skills.
class DashboardSkills {
  final String generatedAt;
  final List<String> scannedRoots;
  final List<SkillEntry> inventory;
  final int count;

  const DashboardSkills({
    required this.generatedAt,
    required this.scannedRoots,
    required this.inventory,
    required this.count,
  });

  factory DashboardSkills.fromJson(Map<String, dynamic> json) {
    return DashboardSkills(
      generatedAt: json['generatedAt'] as String? ?? '',
      scannedRoots: (json['scannedRoots'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      inventory: (json['inventory'] as List?)
              ?.map((e) => SkillEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      count: json['count'] as int? ?? 0,
    );
  }
}

/// A skill entry in the skill registry.
class SkillEntry {
  final String name;
  final String? description;
  final String? team;
  final List<String> triggers;

  const SkillEntry({
    required this.name,
    this.description,
    this.team,
    this.triggers = const [],
  });

  factory SkillEntry.fromJson(Map<String, dynamic> json) {
    return SkillEntry(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      team: json['team'] as String?,
      triggers: (json['triggers'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Knowledge memory view from GET /api/dashboard/views/knowledge-memory.
class DashboardKnowledgeMemory {
  final List<KnowledgeBoundary> boundaries;
  final int count;

  const DashboardKnowledgeMemory({
    required this.boundaries,
    required this.count,
  });

  factory DashboardKnowledgeMemory.fromJson(Map<String, dynamic> json) {
    return DashboardKnowledgeMemory(
      boundaries: (json['boundaries'] as List?)
              ?.map((e) => KnowledgeBoundary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      count: json['count'] as int? ?? 0,
    );
  }
}

/// A knowledge boundary item.
class KnowledgeBoundary {
  final String type;
  final String? location;
  final String? description;

  const KnowledgeBoundary({
    required this.type,
    this.location,
    this.description,
  });

  factory KnowledgeBoundary.fromJson(Map<String, dynamic> json) {
    return KnowledgeBoundary(
      type: json['type'] as String? ?? '',
      location: json['location'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Improvement candidates view from GET /api/dashboard/views/improvement-candidates.
class DashboardImprovementCandidates {
  final List<ImprovementCandidate> candidates;
  final int count;

  const DashboardImprovementCandidates({
    required this.candidates,
    required this.count,
  });

  factory DashboardImprovementCandidates.fromJson(Map<String, dynamic> json) {
    return DashboardImprovementCandidates(
      candidates: (json['candidates'] as List?)
              ?.map((e) =>
                  ImprovementCandidate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      count: json['count'] as int? ?? 0,
    );
  }
}

/// An improvement candidate entry.
class ImprovementCandidate {
  final String? id;
  final String? scope;
  final String? suggestion;
  final String? category;
  final String? source;

  const ImprovementCandidate({
    this.id,
    this.scope,
    this.suggestion,
    this.category,
    this.source,
  });

  factory ImprovementCandidate.fromJson(Map<String, dynamic> json) {
    return ImprovementCandidate(
      id: json['id'] as String?,
      scope: json['scope'] as String?,
      suggestion: json['suggestion'] as String?,
      category: json['category'] as String?,
      source: json['source'] as String?,
    );
  }
}

/// OpenCode integration view from GET /api/dashboard/views/opencode-integration.
class DashboardOpencodeIntegration {
  final String runtimeOwner;
  final List<DeploymentContext> deploymentContexts;
  final List<String> memoryDocSources;
  final SkillInjectionInfo skillInjection;
  final List<String> opencodeSafeValidationWarnings;

  const DashboardOpencodeIntegration({
    required this.runtimeOwner,
    required this.deploymentContexts,
    required this.memoryDocSources,
    required this.skillInjection,
    required this.opencodeSafeValidationWarnings,
  });

  factory DashboardOpencodeIntegration.fromJson(Map<String, dynamic> json) {
    return DashboardOpencodeIntegration(
      runtimeOwner: json['runtimeOwner'] as String? ?? '',
      deploymentContexts: (json['deploymentContexts'] as List?)
              ?.map((e) =>
                  DeploymentContext.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      memoryDocSources: (json['memoryDocSources'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      skillInjection: SkillInjectionInfo.fromJson(
          json['skillInjection'] as Map<String, dynamic>? ?? {}),
      opencodeSafeValidationWarnings:
          (json['opencodeSafeValidationWarnings'] as List?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
    );
  }
}

/// Deployment context entry.
class DeploymentContext {
  final String deployId;
  final String runtime;
  final String binary;
  final String? ticketId;

  const DeploymentContext({
    required this.deployId,
    required this.runtime,
    required this.binary,
    this.ticketId,
  });

  factory DeploymentContext.fromJson(Map<String, dynamic> json) {
    return DeploymentContext(
      deployId: json['deployId'] as String? ?? '',
      runtime: json['runtime'] as String? ?? '',
      binary: json['binary'] as String? ?? '',
      ticketId: json['ticketId'] as String?,
    );
  }
}

/// Skill injection metadata.
class SkillInjectionInfo {
  final String source;
  final int primerSummaryBudgetChars;
  final String primerSkillSummary;
  final List<String> scannedRoots;

  const SkillInjectionInfo({
    required this.source,
    required this.primerSummaryBudgetChars,
    required this.primerSkillSummary,
    required this.scannedRoots,
  });

  factory SkillInjectionInfo.fromJson(Map<String, dynamic> json) {
    return SkillInjectionInfo(
      source: json['source'] as String? ?? '',
      primerSummaryBudgetChars:
          json['primerSummaryBudgetChars'] as int? ?? 0,
      primerSkillSummary: json['primerSkillSummary'] as String? ?? '',
      scannedRoots: (json['scannedRoots'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}