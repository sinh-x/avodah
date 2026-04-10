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
  /// [provider] is null when using team default.
  /// [teamModel] is null when using team default.
  final Future<void> Function(String team, String mode, String objective,
      {String? repo, String? provider, String? teamModel}) onDeploy;

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
  String? _selectedProvider;
  String? _selectedModel;
  bool _deploying = false;
  bool _objectiveTouched = false;
  late final TextEditingController _objectiveController;

  @override
  void initState() {
    super.initState();
    _objectiveController =
        TextEditingController(text: widget.initialObjective ?? '');
    _objectiveController.addListener(_onObjectiveChanged);

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

    // Pre-select provider and model from team's configured defaults.
    _applyTeamDefaults();
  }

  void _applyTeamDefaults() {
    if (_selectedTeam == null) return;
    final paTeam = _paTeamFor(_selectedTeam!);
    if (paTeam == null) return;
    _selectedProvider = paTeam.defaultProvider;
    _selectedModel = paTeam.defaultModel;
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

  void _onObjectiveChanged() {
    if (!_objectiveTouched && _objectiveController.text.isNotEmpty) {
      _objectiveTouched = true;
    }
    setState(() {});
  }

  /// Sanitize objective text: replace & with 'and', strip blocked chars.
  String _sanitizeObjective(String raw) {
    return raw
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[`;|$\\><]'), '')
        .trim();
  }

  /// Returns true if the objective text contains any blocked characters.
  bool get _objectiveHasBlockedChars {
    final text = _objectiveController.text;
    return RegExp(r'[&`;|$\\><]').hasMatch(text);
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

  Color? _modeTypeColor(String? modeType) {
    switch (modeType) {
      case 'work':
        return Colors.blue;
      case 'housekeeping':
        return Colors.orange;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Wrap in Padding to push content above keyboard when objective field focused.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
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
                      _applyTeamDefaults();
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

                // Provider dropdown
                if (_selectedTeam != null) ...[
                  Text('Provider', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  _ProviderSelector(
                    selectedProvider: _selectedProvider,
                    enabled: !_deploying,
                    onChanged: (p) =>
                        setState(() => _selectedProvider = p),
                  ),
                  const SizedBox(height: 16),
                ],

                // Model dropdown
                if (_selectedTeam != null) ...[
                  Text('Model', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  _ModelSelector(
                    selectedModel: _selectedModel,
                    enabled: !_deploying,
                    onChanged: (m) => setState(() => _selectedModel = m),
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
                    hintText: 'e.g. AVO-008: Implement feature or leave blank',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    errorText: _objectiveHasBlockedChars
                        ? 'Invalid characters detected (will be auto-corrected on send)'
                        : null,
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
            final modeColor = _modeTypeColor(mode.modeType);
            return FilterChip(
              label: Text(mode.label),
              selected: selected,
              backgroundColor:
                  modeColor?.withValues(alpha: 0.12),
              selectedColor: modeColor?.withValues(alpha: 0.25),
              avatar: modeColor != null
                  ? CircleAvatar(
                      backgroundColor: modeColor,
                      radius: 5,
                    )
                  : null,
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
      final sanitizedObjective = _sanitizeObjective(_objectiveController.text);
      await widget.onDeploy(
        _selectedTeam!,
        _selectedMode!,
        sanitizedObjective,
        repo: _selectedRepo,
        provider: _selectedProvider,
        teamModel: _selectedModel,
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

// ---------------------------------------------------------------------------
// Provider selector widget
// ---------------------------------------------------------------------------

class _ProviderSelector extends StatelessWidget {
  final String? selectedProvider;
  final bool enabled;
  final void Function(String?) onChanged;

  static const _providers = ['anthropic', 'minimax'];

  const _ProviderSelector({
    required this.selectedProvider,
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
        value: selectedProvider,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          'anthropic',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        items: _providers
            .map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(p),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Model selector widget
// ---------------------------------------------------------------------------

class _ModelSelector extends StatelessWidget {
  final String? selectedModel;
  final bool enabled;
  final void Function(String?) onChanged;

  static const _models = ['haiku', 'sonnet', 'opus'];

  const _ModelSelector({
    required this.selectedModel,
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
        value: selectedModel,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          'opus',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        items: _models
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Text(m),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
