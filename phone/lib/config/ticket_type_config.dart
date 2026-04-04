import 'package:flutter/material.dart';

/// Phone-visible ticket types that human users can select when creating tickets.
///
/// Agent-only types (review-request, work-report, fyi) are excluded from this list
/// but remain valid in the CLI and API for PA agent workflows.
enum PhoneTicketType {
  task,
  bug,
  feature,
  idea,
  question,
}

/// Severity levels for bug tickets.
enum BugSeverity {
  critical,
  major,
  minor,
  trivial,
}

/// Extension to get display labels and descriptions for severity levels.
extension BugSeverityExtension on BugSeverity {
  String get label {
    switch (this) {
      case BugSeverity.critical:
        return 'Critical';
      case BugSeverity.major:
        return 'Major';
      case BugSeverity.minor:
        return 'Minor';
      case BugSeverity.trivial:
        return 'Trivial';
    }
  }
}

/// Definition of a single guided input field for a ticket type.
class GuidedField {
  /// The SUMMARY_TEMPLATES key (e.g. "WHAT", "WHY", "SEVERITY").
  final String templateKey;

  /// Human-readable label shown above the input.
  final String label;

  /// Hint text shown inside the input when empty.
  final String hint;

  /// Whether this field is required (validation will enforce).
  final bool required;

  /// For enum fields: the list of allowed values.
  /// Null for free-text fields.
  final List<String>? options;

  const GuidedField({
    required this.templateKey,
    required this.label,
    required this.hint,
    this.required = false,
    this.options,
  });
}

/// Phone-visible configuration for a single ticket type.
class TicketTypeConfig {
  /// User-friendly label (e.g. "Bug Report").
  final String label;

  /// One-line description shown in the type picker.
  final String description;

  /// Icon shown in the type picker.
  final IconData icon;

  /// Ordered list of guided fields shown when this type is selected.
  final List<GuidedField> fields;

  const TicketTypeConfig({
    required this.label,
    required this.description,
    required this.icon,
    required this.fields,
  });
}

/// Per-type configuration map for phone-visible ticket types.
const kTicketTypeConfigs = <PhoneTicketType, TicketTypeConfig>{
  PhoneTicketType.bug: TicketTypeConfig(
    label: 'Bug Report',
    description: 'Something is broken or not working as expected',
    icon: Icons.bug_report,
    fields: [
      GuidedField(
        templateKey: 'WHAT',
        label: 'What happened?',
        hint: 'Describe the bug clearly...',
        required: true,
      ),
      GuidedField(
        templateKey: 'EXPECTED',
        label: 'Expected behavior',
        hint: 'What should have happened...',
        required: true,
      ),
      GuidedField(
        templateKey: 'REPRO',
        label: 'Steps to reproduce',
        hint: '1. ...\n2. ...\n3. ...',
        required: true,
      ),
      GuidedField(
        templateKey: 'SEVERITY',
        label: 'Severity',
        hint: 'Select severity',
        required: true,
        options: ['critical', 'major', 'minor', 'trivial'],
      ),
    ],
  ),
  PhoneTicketType.task: TicketTypeConfig(
    label: 'Task',
    description: 'A unit of work to be completed',
    icon: Icons.task_alt,
    fields: [
      GuidedField(
        templateKey: 'WHAT',
        label: 'What',
        hint: 'What needs to be done...',
        required: true,
      ),
      GuidedField(
        templateKey: 'WHY',
        label: 'Why',
        hint: 'Why is this needed...',
        required: true,
      ),
      GuidedField(
        templateKey: 'SCOPE',
        label: 'Scope',
        hint: 'What is included/excluded...',
        required: false,
      ),
    ],
  ),
  PhoneTicketType.feature: TicketTypeConfig(
    label: 'Feature',
    description: 'A new capability or enhancement',
    icon: Icons.star,
    fields: [
      GuidedField(
        templateKey: 'WHAT',
        label: 'What',
        hint: 'What feature to build...',
        required: true,
      ),
      GuidedField(
        templateKey: 'WHY',
        label: 'Why',
        hint: 'Why is this valuable...',
        required: true,
      ),
      GuidedField(
        templateKey: 'SCOPE',
        label: 'Scope',
        hint: 'What is included/excluded...',
        required: false,
      ),
    ],
  ),
  PhoneTicketType.idea: TicketTypeConfig(
    label: 'Idea',
    description: 'A suggestion or innovation to consider',
    icon: Icons.lightbulb_outline,
    fields: [
      GuidedField(
        templateKey: 'WHAT',
        label: 'What',
        hint: 'Describe the idea...',
        required: true,
      ),
      GuidedField(
        templateKey: 'WHY',
        label: 'Why',
        hint: 'Why is this worth considering...',
        required: false,
      ),
    ],
  ),
  PhoneTicketType.question: TicketTypeConfig(
    label: 'Question',
    description: 'A question needing an answer',
    icon: Icons.help_outline,
    fields: [
      GuidedField(
        templateKey: 'WHAT',
        label: 'What',
        hint: 'What is your question...',
        required: true,
      ),
      GuidedField(
        templateKey: 'CONTEXT',
        label: 'Context',
        hint: 'Background information...',
        required: false,
      ),
      GuidedField(
        templateKey: 'BLOCKING',
        label: 'Blocking',
        hint: 'Is this blocking progress?',
        required: true,
        options: ['yes', 'no'],
      ),
    ],
  ),
};

/// Assemble guided field values into a conformant SUMMARY_TEMPLATES string.
///
/// Format: "WHAT: value\nWHY: value\nSCOPE: value\n..."
String assembleSummary(
  PhoneTicketType type,
  Map<String, String> fieldValues,
) {
  final config = kTicketTypeConfigs[type]!;
  final parts = <String>[];

  for (final field in config.fields) {
    final value = fieldValues[field.templateKey];
    if (value != null && value.trim().isNotEmpty) {
      parts.add('${field.templateKey}: ${value.trim()}');
    }
  }

  return parts.join('\n');
}
