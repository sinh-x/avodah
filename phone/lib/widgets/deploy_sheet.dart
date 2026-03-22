import 'package:flutter/material.dart';

import '../models/pa_team.dart';

/// A reusable deploy bottom sheet.
///
/// Used from two entry points:
/// - FAB on team list: no pre-selection, user picks team + mode + optional objective
/// - Item detail view: pre-selected team + pre-filled objective from inbox filename
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => DeploySheet(
///     paTeams: paTeams,
///     initialTeam: 'requirements',         // optional
///     initialObjective: '2026-03-16-foo.md', // optional
///     onDeploy: (team, mode, objective) async { ... },
///   ),
/// );
/// ```
class DeploySheet extends StatefulWidget {
  /// All PA teams with deploy modes.
  final List<PaTeam> paTeams;

  /// Available PA repos for the optional repo picker.
  /// When empty, the repo dropdown is hidden.
  final List<PaRepo> paRepos;

  /// Pre-selected team name. If null, user must select from [paTeams].
  final String? initialTeam;

  /// Pre-filled objective text. User can edit before launching.
  final String? initialObjective;

  /// Pre-selected repo name. User can change before launching.
  final String? initialRepo;

  /// Called when user taps Launch.
  /// [objective] may be empty string if user left the field blank.
  /// [repo] is null when no repo was selected.
  final Future<void> Function(String team, String mode, String objective,
      {String? repo}) onDeploy;

  const DeploySheet({
    super.key,
    required this.paTeams,
    this.paRepos = const [],
    this.initialTeam,
    this.initialObjective,
    this.initialRepo,
    required this.onDeploy,
  });

  @override
  State<DeploySheet> createState() => _DeploySheetState();
}

class _DeploySheetState extends State<DeploySheet> {
  String? _selectedTeam;
  String? _selectedMode;
  String? _selectedRepo;
  bool _deploying = false;
  late final TextEditingController _objectiveController;

  @override
  void initState() {
    super.initState();
    _objectiveController =
        TextEditingController(text: widget.initialObjective ?? '');

    // Pre-select repo if provided and it exists in the list.
    if (widget.initialRepo != null &&
        widget.paRepos.any((r) => r.name == widget.initialRepo)) {
      _selectedRepo = widget.initialRepo;
    }

    // Pre-select team from initialTeam, or auto-select if only one team.
    if (widget.initialTeam != null &&
        widget.paTeams.any((t) => t.name == widget.initialTeam)) {
      _selectedTeam = widget.initialTeam;
    } else if (widget.paTeams.length == 1) {
      _selectedTeam = widget.paTeams.first.name;
    }

    // Auto-select mode if the initial team has exactly one deploy mode.
    _autoSelectMode();
  }

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  void _autoSelectMode() {
    if (_selectedTeam == null) return;
    final paTeam = _paTeamFor(_selectedTeam!);
    if (paTeam != null && paTeam.deployModes.length == 1) {
      _selectedMode = paTeam.deployModes.first.id;
    }
  }

  PaTeam? _paTeamFor(String teamName) {
    try {
      return widget.paTeams.firstWhere((t) => t.name == teamName);
    } catch (_) {
      return null;
    }
  }

  bool get _canLaunch =>
      _selectedTeam != null && _selectedMode != null && !_deploying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Wrap in Padding to push content above keyboard when objective field focused.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text('Deploy', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              // Team selector
              if (widget.paTeams.isEmpty) ...[
                Text(
                  'No teams configured',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ] else ...[
                Text('Team', style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                _TeamSelector(
                  paTeams: widget.paTeams,
                  selectedTeam: _selectedTeam,
                  enabled: !_deploying,
                  onChanged: (team) {
                    setState(() {
                      _selectedTeam = team;
                      _selectedMode = null;
                      _autoSelectMode();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Mode chips
                if (_selectedTeam != null) ...[
                  _buildModeSection(theme),
                  const SizedBox(height: 16),
                ],

                // Repo picker (hidden when no repos configured)
                if (widget.paRepos.isNotEmpty) ...[
                  Text('Repo (optional)', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  _RepoSelector(
                    paRepos: widget.paRepos,
                    selectedRepo: _selectedRepo,
                    enabled: !_deploying,
                    onChanged: (repo) => setState(() => _selectedRepo = repo),
                  ),
                  const SizedBox(height: 16),
                ],

                // Objective field
                Text('Objective (optional)', style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _objectiveController,
                  enabled: !_deploying,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'e.g. 2026-03-16-task.md or leave blank',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Launch button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _canLaunch ? _launch : null,
                    icon: _deploying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.rocket_launch_outlined),
                    label: const Text('Launch'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSection(ThemeData theme) {
    final paTeam = _paTeamFor(_selectedTeam!);
    if (paTeam == null || paTeam.deployModes.isEmpty) {
      return Text(
        'No deploy modes configured for this team',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.outline),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deploy mode', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: paTeam.deployModes.map((mode) {
            final selected = _selectedMode == mode.id;
            return FilterChip(
              label: Text(mode.label),
              selected: selected,
              onSelected: _deploying
                  ? null
                  : (_) => setState(() {
                        _selectedMode = selected ? null : mode.id;
                      }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _launch() async {
    if (!_canLaunch) return;
    setState(() => _deploying = true);
    try {
      await widget.onDeploy(
        _selectedTeam!,
        _selectedMode!,
        _objectiveController.text.trim(),
        repo: _selectedRepo,
      );
    } finally {
      if (mounted) setState(() => _deploying = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Repo selector widget
// ---------------------------------------------------------------------------

class _RepoSelector extends StatelessWidget {
  final List<PaRepo> paRepos;
  final String? selectedRepo;
  final bool enabled;
  final void Function(String?) onChanged;

  const _RepoSelector({
    required this.paRepos,
    required this.selectedRepo,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButton<String>(
        value: selectedRepo,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          'None (no repo context)',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              'None',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          ...paRepos.map(
            (r) => DropdownMenuItem(
              value: r.name,
              child: Text(r.name),
            ),
          ),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team selector widget
// ---------------------------------------------------------------------------

class _TeamSelector extends StatelessWidget {
  final List<PaTeam> paTeams;
  final String? selectedTeam;
  final bool enabled;
  final void Function(String?) onChanged;

  const _TeamSelector({
    required this.paTeams,
    required this.selectedTeam,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButton<String>(
        value: selectedTeam,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          'Select team',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        items: paTeams
            .map(
              (t) => DropdownMenuItem(
                value: t.name,
                child: Text(t.name),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
