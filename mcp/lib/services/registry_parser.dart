/// Parses the deployment registry JSONL file.
///
/// The registry at `~/Documents/ai-usage/deployments/registry.jsonl` contains
/// one JSON object per line, tracking deployment lifecycle events.
library;

import 'dart:convert';
import 'dart:io';

/// A single event line from registry.jsonl.
class RegistryEvent {
  final String deploymentId;
  final String team;
  final String event; // started, pid, completed, crashed
  final String timestamp;
  final int? pid;
  final String? status; // success, partial, failed
  final String? summary;
  final List<String>? agents;
  final int? exitCode;

  RegistryEvent({
    required this.deploymentId,
    required this.team,
    required this.event,
    required this.timestamp,
    this.pid,
    this.status,
    this.summary,
    this.agents,
    this.exitCode,
  });

  factory RegistryEvent.fromJson(Map<String, dynamic> json) {
    return RegistryEvent(
      deploymentId: json['deployment_id'] as String,
      team: json['team'] as String,
      event: json['event'] as String,
      timestamp: json['timestamp'] as String? ?? '',
      pid: json['pid'] as int?,
      status: json['status'] as String?,
      summary: json['summary'] as String?,
      agents: (json['agents'] as List?)?.cast<String>(),
      exitCode: json['exit_code'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'deployment_id': deploymentId,
        'team': team,
        'event': event,
        'timestamp': timestamp,
        if (pid != null) 'pid': pid,
        if (status != null) 'status': status,
        if (summary != null) 'summary': summary,
        if (agents != null) 'agents': agents,
        if (exitCode != null) 'exit_code': exitCode,
      };
}

/// Computed deployment status from grouped registry events.
class DeploymentStatus {
  final String deploymentId;
  final String team;
  final String status; // running, success, partial, failed, crashed
  final String startedAt;
  final String? completedAt;
  final String? summary;
  final List<String> agents;

  DeploymentStatus({
    required this.deploymentId,
    required this.team,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.summary,
    this.agents = const [],
  });

  Map<String, dynamic> toJson() => {
        'deployment_id': deploymentId,
        'team': team,
        'status': status,
        'started_at': startedAt,
        if (completedAt != null) 'completed_at': completedAt,
        if (summary != null) 'summary': summary,
        if (agents.isNotEmpty) 'agents': agents,
      };
}

/// Parse registry.jsonl and return all events.
///
/// Skips malformed lines gracefully — logs to stderr but doesn't crash.
List<RegistryEvent> parseRegistryFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return [];

  final events = <RegistryEvent>[];
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    try {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      events.add(RegistryEvent.fromJson(json));
    } catch (e) {
      stderr.writeln('Skipping malformed registry line: $e');
    }
  }
  return events;
}

/// Group registry events by deployment_id and compute status for each.
///
/// Returns deployments sorted by start time (newest first).
List<DeploymentStatus> computeDeploymentStatuses(List<RegistryEvent> events) {
  final grouped = <String, List<RegistryEvent>>{};
  for (final event in events) {
    grouped.putIfAbsent(event.deploymentId, () => []).add(event);
  }

  final deployments = <DeploymentStatus>[];
  for (final entry in grouped.entries) {
    final deployEvents = entry.value;
    final started =
        deployEvents.where((e) => e.event == 'started').firstOrNull;
    final completed =
        deployEvents.where((e) => e.event == 'completed').firstOrNull;
    final crashed =
        deployEvents.where((e) => e.event == 'crashed').firstOrNull;

    String status;
    String? completedAt;
    String? summary;

    if (crashed != null) {
      status = 'crashed';
      completedAt = crashed.timestamp;
      summary = crashed.summary;
    } else if (completed != null) {
      status = completed.status ?? 'success';
      completedAt = completed.timestamp;
      summary = completed.summary;
    } else {
      status = 'running';
    }

    deployments.add(DeploymentStatus(
      deploymentId: entry.key,
      team: started?.team ?? deployEvents.first.team,
      status: status,
      startedAt: started?.timestamp ?? '',
      completedAt: completedAt,
      summary: summary,
      agents: started?.agents ?? [],
    ));
  }

  // Sort newest first
  deployments.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return deployments;
}
