import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pa_team.dart';
import '../models/session_record.dart';
import '../models/ws_session_event.dart';
import '../services/agent_api_client.dart';
import '../services/ws_session_client.dart';

/// Session screen for real-time opencode interaction via WebSocket.
///
/// Three modes:
/// - **Setup** — choose to start a new session (select team, mode, type prompt)
///   or resume an existing session (select from session list).
/// - **Live** — chat input enabled; events stream in real-time via
///   [WsSessionClient.events]. User can send follow-up prompts by resuming
///   the active session id, and stop the session.
/// - **View-only** — when a session is closed/ended, the event history is
///   shown read-only with no chat input.
///
/// Follows the screen pattern of [DeploymentScreen] (StatefulWidget receiving
/// [AgentApiClient]). All network calls are async — no UI blocking.
class SessionScreen extends StatefulWidget {
  final AgentApiClient apiClient;

  const SessionScreen({super.key, required this.apiClient});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

/// Internal state machine for the screen.
enum _SessionMode { setup, live, viewOnly }

class _SessionScreenState extends State<SessionScreen> {
  _SessionMode _mode = _SessionMode.setup;

  // Setup state
  List<PaTeam> _paTeams = [];
  List<SessionRecord> _sessions = [];
  bool _loadingSetup = false;
  String? _setupError;

  String? _selectedTeam;
  String? _selectedMode;
  final TextEditingController _promptController = TextEditingController();

  // Active session state
  WsSessionClient? _wsClient;
  String? _activeSessionId;
  StreamSubscription<WsSessionEvent>? _eventSub;
  final List<_EventLine> _eventLines = [];
  final TextEditingController _chatController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadSetupData();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _chatController.dispose();
    _eventSub?.cancel();
    _wsClient?.close();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Setup data
  // --------------------------------------------------------------------------

  Future<void> _loadSetupData() async {
    setState(() {
      _loadingSetup = true;
      _setupError = null;
    });
    try {
      final teams = await widget.apiClient.listPaTeams();
      List<SessionRecord> sessions = [];
      try {
        sessions = await widget.apiClient.listSessions();
      } catch (_) {
        // Sessions list is best-effort — may fail if pa-platform is down.
      }
      if (!mounted) return;
      setState(() {
        _paTeams = teams;
        _sessions = sessions;
        _loadingSetup = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _setupError = e.toString();
        _loadingSetup = false;
      });
    }
  }

  // --------------------------------------------------------------------------
  // WebSocket connection
  // --------------------------------------------------------------------------

  /// Derive `ws://host:port` from the apiClient's `http://host:port` baseUrl.
  String _deriveWsBaseUrl() {
    final base = widget.apiClient.baseUrl;
    if (base.startsWith('https://')) {
      return base.replaceFirst('https://', 'wss://');
    }
    return base.replaceFirst('http://', 'ws://');
  }

  /// Connect to `/ws/session` using the sync server proxy (which forwards to
  /// pa-platform on 9848). Auth headers (pairing token, node id) are passed
  /// so the proxy authenticates the request like all other API calls.
  WsSessionClient _connectWs() {
    final wsBase = _deriveWsBaseUrl();
    return WsSessionClient.connect(
      wsBase,
      headers: {
        if (widget.apiClient.pairingToken != null)
          'X-Av-Pair-Token': widget.apiClient.pairingToken!,
        if (widget.apiClient.nodeId != null)
          'X-Av-Node-Id': widget.apiClient.nodeId!,
      },
    );
  }

  void _startSession() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    if (_selectedTeam == null || _selectedMode == null) return;

    final client = _connectWs();
    setState(() {
      _wsClient = client;
      _mode = _SessionMode.live;
      _eventLines.clear();
      _sending = true;
    });

    _eventSub = client.events.listen(_onEvent, onError: _onWsError,
        onDone: _onWsDone);

    client.start(
      prompt,
      team: _selectedTeam,
      mode: _selectedMode,
    );
  }

  void _resumeSession(String sessionId) {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final client = _connectWs();
    setState(() {
      _wsClient = client;
      _mode = _SessionMode.live;
      _eventLines.clear();
      _sending = true;
    });

    _eventSub = client.events.listen(_onEvent, onError: _onWsError,
        onDone: _onWsDone);

    client.resume(
      sessionId,
      prompt,
      team: _selectedTeam,
      mode: _selectedMode,
    );
  }

  void _stopSession() {
    _wsClient?.stop();
  }

  /// Send a follow-up prompt during a live session.
  ///
  /// The current WS session protocol does not support free-form chat messages
  /// after `start` — the only client message types are `start`, `resume`, and
  /// `stop`. To send a follow-up, we close the current connection and open a
  /// new one that resumes the active session id with the new prompt. This
  /// matches the opencode `--session` resume semantics.
  void _sendFollowUp() {
    final text = _chatController.text.trim();
    if (text.isEmpty || _activeSessionId == null) return;

    setState(() => _sending = true);
    _chatController.clear();

    // Close current connection and resume with the new prompt.
    _eventSub?.cancel();
    _wsClient?.close();

    final client = _connectWs();
    _wsClient = client;
    _eventSub = client.events.listen(_onEvent, onError: _onWsError,
        onDone: _onWsDone);

    client.resume(_activeSessionId!, text);
  }

  // --------------------------------------------------------------------------
  // Event handlers
  // --------------------------------------------------------------------------

  void _onEvent(WsSessionEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event.type) {
        case WsSessionEventType.sessionId:
          _activeSessionId = event.sessionId;
          _sending = false;
          _eventLines.add(_EventLine(
            kind: _LineKind.system,
            text: 'Session started: ${event.sessionId}',
            timestamp: event.timestamp,
          ));
          break;
        case WsSessionEventType.event:
          final data = event.data;
          final body = data?['body']?.toString() ?? data.toString();
          _eventLines.add(_EventLine(
            kind: _LineKind.event,
            text: body,
            timestamp: event.timestamp,
          ));
          break;
        case WsSessionEventType.error:
          _eventLines.add(_EventLine(
            kind: _LineKind.error,
            text: event.message ?? 'Unknown error',
            timestamp: event.timestamp,
          ));
          _sending = false;
          break;
        case WsSessionEventType.end:
          final reason = event.data?['reason']?.toString() ??
              event.data?['exitCode']?.toString() ??
              'ended';
          _eventLines.add(_EventLine(
            kind: _LineKind.end,
            text: 'Session ended ($reason)',
            timestamp: event.timestamp,
          ));
          _mode = _SessionMode.viewOnly;
          _sending = false;
          break;
      }
    });
  }

  void _onWsError(Object error) {
    if (!mounted) return;
    setState(() {
      _eventLines.add(_EventLine(
        kind: _LineKind.error,
        text: 'Connection error: $error',
        timestamp: DateTime.now().toIso8601String(),
      ));
      _sending = false;
    });
  }

  void _onWsDone() {
    if (!mounted) return;
    // If the WebSocket closed without an explicit `end` event, switch to
    // view-only mode so the event history is preserved.
    if (_mode == _SessionMode.live) {
      setState(() {
        _mode = _SessionMode.viewOnly;
        _sending = false;
      });
    }
  }

  void _resetToSetup() {
    _eventSub?.cancel();
    _wsClient?.close();
    setState(() {
      _wsClient = null;
      _activeSessionId = null;
      _mode = _SessionMode.setup;
      _eventLines.clear();
      _promptController.clear();
      _chatController.clear();
      _sending = false;
    });
    _loadSetupData();
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (_mode) {
      case _SessionMode.setup:
        return _buildSetup(theme);
      case _SessionMode.live:
        return _buildLive(theme);
      case _SessionMode.viewOnly:
        return _buildViewOnly(theme);
    }
  }

  // -- Setup -----------------------------------------------------------------

  Widget _buildSetup(ThemeData theme) {
    if (_loadingSetup) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_setupError != null && _paTeams.isEmpty) {
      return _buildErrorState(theme, _setupError!);
    }
    return RefreshIndicator(
      onRefresh: _loadSetupData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // New session section
          Text('New Session', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_paTeams.isEmpty)
            Text(
              'No PA teams configured. Start pa-platform first.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            )
          else ...[
            _TeamDropdown(
              paTeams: _paTeams,
              selectedTeam: _selectedTeam,
              onChanged: (team) => setState(() {
                _selectedTeam = team;
                _selectedMode = null;
              }),
            ),
            const SizedBox(height: 12),
            if (_selectedTeam != null) ...[
              _ModeChips(
                paTeam: _paTeamFor(_selectedTeam!),
                selectedMode: _selectedMode,
                onChanged: (mode) => setState(() => _selectedMode = mode),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Type the initial prompt for the session',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _canStart ? _startSession : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
            ),
          ],
          const SizedBox(height: 32),

          // Resume section
          Text('Resume Existing Session', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_sessions.isEmpty)
            Text(
              'No active sessions found.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            )
          else ...[
            for (final session in _sessions)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(session.id),
                  subtitle: Text(
                    'Status: ${session.status}'
                    '${session.deploymentId != null ? ' • ${session.deploymentId}' : ''}',
                  ),
                  onTap: () => _showResumeDialog(session),
                ),
              ),
          ],
          if (_setupError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Warning: $_setupError',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  bool get _canStart =>
      _selectedTeam != null &&
      _selectedMode != null &&
      _promptController.text.trim().isNotEmpty;

  PaTeam? _paTeamFor(String name) {
    try {
      return _paTeams.firstWhere((t) => t.name == name);
    } catch (_) {
      return null;
    }
  }

  void _showResumeDialog(SessionRecord session) {
    final promptController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resume ${session.id}'),
        content: TextField(
          controller: promptController,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Prompt',
            hintText: 'Type the prompt to resume with',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final prompt = promptController.text.trim();
              Navigator.of(ctx).pop();
              if (prompt.isNotEmpty) {
                _promptController.text = prompt;
                _resumeSession(session.id);
              }
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  // -- Live ------------------------------------------------------------------

  Widget _buildLive(ThemeData theme) {
    return Column(
      children: [
        // AppBar-like header with session info + stop button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _activeSessionId != null
                      ? 'Session: $_activeSessionId'
                      : 'Starting session…',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined),
                tooltip: 'Stop session',
                onPressed: _stopSession,
              ),
            ],
          ),
        ),
        // Event stream
        Expanded(child: _buildEventList(theme)),
        // Chat input
        _buildChatInput(theme),
      ],
    );
  }

  Widget _buildViewOnly(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Session ended — view-only',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: _resetToSetup,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New Session'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildEventList(theme)),
      ],
    );
  }

  Widget _buildEventList(ThemeData theme) {
    if (_eventLines.isEmpty) {
      return Center(
        child: Text(
          'Waiting for events…',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: _eventLines.length,
      itemBuilder: (context, index) {
        final line = _eventLines[index];
        return _EventLineWidget(line: line);
      },
    );
  }

  Widget _buildChatInput(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                enabled: _activeSessionId != null && !_sending,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type a follow-up prompt…',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _sendFollowUp(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: _activeSessionId != null && !_sending
                  ? _sendFollowUp
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // -- Error -----------------------------------------------------------------

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Cannot reach pa-platform', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadSetupData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A single rendered event line with a kind for color coding.
class _EventLine {
  final _LineKind kind;
  final String text;
  final String timestamp;

  const _EventLine({
    required this.kind,
    required this.text,
    required this.timestamp,
  });
}

enum _LineKind { system, event, error, end }

class _EventLineWidget extends StatelessWidget {
  final _EventLine line;

  const _EventLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = switch (line.kind) {
      _LineKind.system => (
          theme.colorScheme.primary,
          Icons.info_outline,
        ),
      _LineKind.event => (
          theme.colorScheme.onSurface,
          Icons.terminal,
        ),
      _LineKind.error => (
          theme.colorScheme.error,
          Icons.error_outline,
        ),
      _LineKind.end => (
          theme.colorScheme.tertiary,
          Icons.stop_circle_outlined,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              line.text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontFamily: line.kind == _LineKind.event ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team/mode selector widgets (simplified from DeploySheet)
// ---------------------------------------------------------------------------

class _TeamDropdown extends StatelessWidget {
  final List<PaTeam> paTeams;
  final String? selectedTeam;
  final void Function(String?) onChanged;

  const _TeamDropdown({
    required this.paTeams,
    required this.selectedTeam,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Team',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButton<String>(
        value: selectedTeam,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: const Text('Select team'),
        items: paTeams
            .map((t) => DropdownMenuItem(
                  value: t.name,
                  child: Text(t.name),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ModeChips extends StatelessWidget {
  final PaTeam? paTeam;
  final String? selectedMode;
  final void Function(String?) onChanged;

  const _ModeChips({
    required this.paTeam,
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (paTeam == null || paTeam!.deployModes.isEmpty) {
      return const Text('No deploy modes configured for this team.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: paTeam!.deployModes.map((mode) {
        final selected = selectedMode == mode.id;
        return FilterChip(
          label: Text(mode.label),
          selected: selected,
          onSelected: (sel) => onChanged(sel ? mode.id : null),
        );
      }).toList(),
    );
  }
}