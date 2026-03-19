/// A single event from a deployment's activity.jsonl timeline.
class ActivityEvent {
  final String ts;
  final String deployId;
  final String agent;
  final String event;
  final Map<String, dynamic> data;

  const ActivityEvent({
    required this.ts,
    required this.deployId,
    required this.agent,
    required this.event,
    this.data = const {},
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      ts: json['ts'] as String? ?? '',
      deployId: json['deploy_id'] as String? ?? '',
      agent: json['agent'] as String? ?? '',
      event: json['event'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  DateTime? get timestamp => DateTime.tryParse(ts);

  /// Short label suitable for compact timeline display.
  String get eventLabel {
    switch (event) {
      case 'agent_spawned':
        return 'Agent spawned';
      case 'agent_stopped':
        return 'Agent stopped';
      case 'task_completed':
        return 'Task completed';
      case 'task_failed':
        return 'Task failed';
      case 'tool_call':
        final tool = data['tool'] as String?;
        return tool != null ? 'Tool: $tool' : 'Tool call';
      case 'deployment_started':
        return 'Deployment started';
      case 'deployment_completed':
        return 'Deployment completed';
      default:
        return event;
    }
  }

  bool get isMilestone {
    const milestones = {
      'agent_spawned',
      'agent_stopped',
      'task_completed',
      'task_failed',
      'deployment_started',
      'deployment_completed',
    };
    return milestones.contains(event);
  }
}
