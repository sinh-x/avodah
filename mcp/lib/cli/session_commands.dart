/// `avo session` subcommands for managing opencode sessions.
///
/// Phase 3 deliverable for AVO-117 (pa-platform API integration). Implements:
/// - `SessionListCommand` — renders active sessions from `GET /api/sessions`
///   as a formatted table (session id, deployment id, model, status, start).
/// - `SessionHistoryCommand` — opens a session's conversation log file in a
///   scrollable read-only pager.
/// - `SessionStartCommand` — triggers a deployment via `POST /api/deploy`
///   and prints the deployment ID. No subprocess is spawned locally.
/// - `SessionStopCommand` — stops a session via `POST /api/sessions/:id/stop`.
/// - `SessionAttachCommand` — live tail of a running session's activity log
///   with ANSI passthrough and Ctrl+C/Esc detach.
///
/// The pager and attach runner live in their own files (`session_pager.dart`
/// and `session_attach_runner.dart`) to keep this file under the ~400 line
/// guideline (CQ-3 review finding).
library;

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../services/session_service.dart';
import 'format.dart';
import 'session_attach_runner.dart';
import 'session_pager.dart';

// ============================================================
// Session Command Group
// ============================================================

/// `avo session` — group command hosting all session subcommands.
///
/// Phase 2 only adds `list` and `history`; `start`, `stop`, and `attach`
/// arrive in later phases. The group is declared here so Phase 5 can import
/// and register it in one place. Subcommands are added lazily via
/// [addSubcommand] from `avo.dart` (Phase 5) to avoid constructing a
/// [SessionService] with default paths before the CLI has a chance to inject
/// overrides. Tests can construct this directly and add the subcommands they
/// need.
class SessionCommand extends Command<void> {
  SessionCommand();

  @override
  String get name => 'session';

  @override
  String get description =>
      'Manage opencode sessions: list, history, start, stop, attach';

  @override
  String get invocation => 'avo session <subcommand>';
}

// ============================================================
// Session List
// ============================================================

/// `avo session list` — list all active sessions from the pa-platform API.
///
/// Calls [SessionService.listSessions] and renders the results as a
/// fixed-width table using [format.dart] utilities. Column order: session
/// id, deployment id, model, status, start time.
class SessionListCommand extends Command<void> {
  final SessionService sessionService;

  SessionListCommand(this.sessionService);

  @override
  String get name => 'list';

  @override
  String get description =>
      'List all active sessions with id, deployment, model, status, and '
      'start time';

  @override
  String get invocation => 'avo session list';

  @override
  Future<void> run() async {
    final healthy = await sessionService.checkHealth();
    if (!healthy) {
      print(sectionHeader('SESSIONS'));
      print('');
      print('  pa-platform is not running.');
      print('');
      print(hintPlain(
          'Start it with `pa-core serve` before listing sessions.'));
      return;
    }

    List<SessionSummary> sessions;
    try {
      sessions = await sessionService.listSessions();
    } catch (e) {
      print(sectionHeader('SESSIONS'));
      print('');
      print('  Failed to list sessions.');
      print('');
      print(hintPlain('$e'));
      return;
    }

    print(sectionHeader('SESSIONS'));
    print('');

    if (sessions.isEmpty) {
      print('  No active sessions found.');
      print('');
      print(hintPlain('pa-platform reports no active sessions.'));
      return;
    }

    const colSession = 18;
    const colDeploy = 10;
    const colModel = 24;
    const colStatus = 10;

    final header = '  '
        '${'Session'.padRight(colSession)} '
        '${'Deployment'.padRight(colDeploy)} '
        '${'Model'.padRight(colModel)} '
        '${'Status'.padRight(colStatus)} '
        'Started';
    print(header);
    print('  ${'-' * (colSession + colDeploy + colModel + colStatus + 24)}');

    for (final s in sessions) {
      final started = _formatStartedAt(s.startedAt);
      final row = '  '
          '${_truncate(s.sessionId, colSession).padRight(colSession)} '
          '${s.deploymentId.padRight(colDeploy)} '
          '${_truncate(s.model, colModel).padRight(colModel)} '
          '${_truncate(s.status, colStatus).padRight(colStatus)} '
          '$started';
      print(row);
    }

    print('');
    print(hintPlain('${sessions.length} session(s).'));
  }

  /// Formats an ISO-8601 timestamp (as stored in the registry) for display.
  /// Falls back to the raw string when parsing fails or the field is empty.
  static String _formatStartedAt(String iso) {
    if (iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm';
    } catch (_) {
      return iso;
    }
  }

  /// Truncates [text] to [max] columns, appending an ellipsis when truncated.
  static String _truncate(String text, int max) {
    if (text.length <= max) return text;
    if (max <= 1) return text.substring(0, max);
    return '${text.substring(0, max - 1)}\u2026';
  }
}

// ============================================================
// Session History
// ============================================================

/// `avo session history <deployment-id>` — read-only scrollable pager for a
/// session's conversation log.
///
/// Locates the log file via [SessionService.getSessionLog] and renders it
/// with a simple pager: arrow keys / Page Up-Down / Home / End scroll, and
/// `q`, `Esc`, or `Ctrl+C` exits. When the file is missing or stdin is not a
/// TTY, the content is printed directly (no pager) so the command still
/// works in pipes and CI logs.
class SessionHistoryCommand extends Command<void> {
  final SessionService sessionService;

  SessionHistoryCommand(this.sessionService) {
    argParser.addOption(
      'lines',
      abbr: 'n',
      help: 'Print the last N lines and exit (non-interactive, no pager)',
    );
  }

  @override
  String get name => 'history';

  @override
  String get description =>
      'Display the conversation log for a session in a scrollable read-only view';

  @override
  String get invocation => 'avo session history <deployment-id> [-n lines]';

  @override
  void run() {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      printUsageError('Missing deployment-id argument.');
      return;
    }
    final deploymentId = args.first;

    final logFile = sessionService.getSessionLog(deploymentId);
    if (logFile == null) {
      print('No session log found for $deploymentId.');
      print('');
      print(hintPlain(
          'Logs are searched under ~/Documents/ai-usage/sessions/YYYY/MM/ '
          'for the current and previous month.'));
      return;
    }

    final lines = logFile.readAsLinesSync();
    if (lines.isEmpty) {
      print('Session log for $deploymentId is empty: ${logFile.path}');
      return;
    }

    // Non-interactive mode: print last N lines (or all) and exit.
    final linesOpt = argResults?['lines'] as String?;
    if (linesOpt != null) {
      final n = int.tryParse(linesOpt);
      if (n == null || n < 0) {
        printUsageError('Invalid --lines value: "$linesOpt".');
        return;
      }
      final start = lines.length > n ? lines.length - n : 0;
      for (final line in lines.sublist(start)) {
        print(line);
      }
      return;
    }

    // No TTY → stream the whole file (pipes, redirects, CI).
    if (!stdin.hasTerminal) {
      for (final line in lines) {
        print(line);
      }
      return;
    }

    // Interactive pager.
    SessionPager(lines, logFile.path, deploymentId).run();
  }

  void printUsageError(String message) {
    print(message);
    print('');
    print('Usage: $invocation');
  }
}

// ============================================================
// Session Start
// ============================================================

/// `avo session start <team> --mode <mode>` — trigger a deployment via the
/// pa-platform API.
///
/// Calls `POST /api/deploy` via [SessionService.startSession]. The
/// pa-platform spawns the `opa deploy` subprocess server-side and
/// auto-registers the session. No subprocess is spawned locally.
class SessionStartCommand extends Command<void> {
  final SessionService sessionService;

  SessionStartCommand(this.sessionService) {
    argParser.addOption(
      'mode',
      abbr: 'm',
      help: 'Deployment mode (e.g. implement, analyze)',
    );
  }

  @override
  String get name => 'start';

  @override
  String get description =>
      'Trigger a new opencode session via the pa-platform API and print its '
      'deployment ID';

  @override
  String get invocation => 'avo session start <team> [--mode <mode>]';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      printUsageError('Missing <team> argument.');
      return;
    }
    final team = args.first;
    final mode = argResults?['mode'] as String? ?? '';

    final healthy = await sessionService.checkHealth();
    if (!healthy) {
      print(sectionHeader('START SESSION'));
      print('');
      print('  pa-platform is not running.');
      print('');
      print(hintPlain(
          'Start it with `pa-core serve` before starting a session.'));
      return;
    }

    print(sectionHeader('START SESSION'));
    print('');
    print(kvRow('Team:', team));
    print(kvRow('Mode:', mode.isEmpty ? '(default)' : mode));
    print('');
    print('Calling pa-platform API…');
    print('');

    final result = await sessionService.startSession(team, mode);
    if (!result.succeeded) {
      print('Failed to start session.');
      print('');
      print(hintPlain(result.error ?? 'Unknown error.'));
      return;
    }

    print('Session started.');
    print('');
    print(kvRow('Deployment:', result.deploymentId));
    print(kvRow('Status:', result.status));
    print('');

    print(hintPlain('The session is running on pa-platform. Use '
        '`avo session stop ${result.deploymentId}` to terminate it or '
        '`avo session attach ${result.deploymentId}` to view its live '
        'output.'));
  }

  void printUsageError(String message) {
    print(message);
    print('');
    print('Usage: $invocation');
  }
}

// ============================================================
// Session Stop
// ============================================================

/// `avo session stop <deployment-id>` — stop a session via the pa-platform
/// API.
/// Calls [SessionService.stopSession] which resolves the deployment id to
/// a session id and calls `POST /api/sessions/:id/stop`. Prints a
/// confirmation message on success and an error when the session is not
/// found.
class SessionStopCommand extends Command<void> {
  final SessionService sessionService;

  SessionStopCommand(this.sessionService);

  @override
  String get name => 'stop';

  @override
  String get description =>
      'Stop a running opencode session via the pa-platform API';

  @override
  String get invocation => 'avo session stop <deployment-id>';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      printUsageError('Missing <deployment-id> argument.');
      return;
    }
    final deploymentId = args.first;

    print(sectionHeader('STOP SESSION'));
    print('');
    print(kvRow('Deployment:', deploymentId));
    print('');

    final result = await sessionService.stopSession(deploymentId);
    if (result.stopped) {
      print('Session stopped.');
      print('');
      print(hintPlain('The session has been terminated on pa-platform.'));
    } else {
      print('Could not stop session.');
      print('');
      print(hintPlain(result.error ??
          'No signal sent. The session may not be running.'));
    }
  }

  void printUsageError(String message) {
    print(message);
    print('');
    print('Usage: $invocation');
  }
}

// ============================================================
// Session Attach (Phase 4 — live tail with ANSI passthrough)
// ============================================================

/// `avo session attach <deployment-id>` — live view of a running opencode
/// session.
///
/// Connects to the pa-platform SSE stream (`GET /api/sessions/:id/stream`)
/// for real-time session events. File-based `activity.jsonl` reading is
/// dropped — WebSocket sessions are the primary interactive path. Deploy
/// sessions (started via `avo session start`) do not support streaming and
/// will produce a clear error message from the SSE endpoint.
///
/// Detach with Ctrl+C or Escape — the session keeps running. When the
/// session emits an `end` event (child closed or stopped), the command
/// prints a notification and returns to the CLI.
class SessionAttachCommand extends Command<void> {
  final SessionService sessionService;

  SessionAttachCommand(this.sessionService);

  @override
  String get name => 'attach';

  @override
  String get description =>
      'Attach to a running opencode session and stream its live output';

  @override
  String get invocation => 'avo session attach <deployment-id>';

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      printUsageError('Missing <deployment-id> argument.');
      return;
    }
    final deploymentId = args.first;

    final healthy = await sessionService.checkHealth();
    if (!healthy) {
      print(sectionHeader('ATTACH SESSION'));
      print('');
      print('  pa-platform is not running.');
      print('');
      print(hintPlain(
          'Start it with `pa-core serve` before attaching to a session.'));
      return;
    }

    final handle = await sessionService.findSession(deploymentId);
    if (handle == null) {
      print('No active session found for $deploymentId.');
      print('');
      print(hintPlain('Check `avo session list` for valid deployment ids.'));
      return;
    }

    if (handle.status != 'running') {
      print('Session $deploymentId is not running (status: ${handle.status}).');
      print('');
      print(hintPlain('Use `avo session history $deploymentId` to view its log.'));
      return;
    }

    final sessionId = handle.sessionId ?? '';
    if (sessionId.isEmpty) {
      print('Session $deploymentId has no session id — cannot stream.');
      print('');
      print(hintPlain('Deploy sessions started via `avo session start` do not '
          'support live streaming. WebSocket sessions from the phone app are '
          'the primary interactive path.'));
      return;
    }

    print(sectionHeader('ATTACH SESSION'));
    print('');
    print(kvRow('Deployment:', deploymentId));
    print(kvRow('Session:', sessionId));
    print(kvRow('Mode:', 'SSE stream'));
    print('');
    print(hintPlain('Streaming live output. Ctrl+C or Esc to detach '
        '(session keeps running).'));
    print('');

    await SessionAttachRunner(
      deploymentId: deploymentId,
      sessionId: sessionId,
      apiBaseUrl: sessionService.apiBaseUrl,
    ).run();
  }

  void printUsageError(String message) {
    print(message);
    print('');
    print('Usage: $invocation');
  }
}