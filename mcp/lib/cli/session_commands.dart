/// `avo session` subcommands for managing opencode sessions.
///
/// Phases 2–4 deliverables for AVO-116 (opencode session integration).
/// Implements:
/// - `SessionListCommand` — renders all deployments from the registry as a
///   formatted table (deployment id, team, mode, status, start time).
/// - `SessionHistoryCommand` — opens a session's conversation log file in a
///   scrollable read-only pager.
/// - `SessionStartCommand` — spawns `opa deploy <team> --mode <mode>` as a
///   subprocess and captures the deployment ID from opa's stdout.
/// - `SessionStopCommand` — sends SIGTERM to a running session's subprocess.
/// - `SessionAttachCommand` — live tail of a running session's activity log
///   with ANSI passthrough, stdin forwarding (when a live process handle is
///   available), and Ctrl+C/Esc detach.
///
/// The pager and attach runner live in their own files (`session_pager.dart`
/// and `session_attach_runner.dart`) to keep this file under the ~400 line
/// guideline (CQ-3 review finding). Command registration in `avo.dart` is
/// handled by Phase 5.
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

/// `avo session list` — list all deployments from the registry.
///
/// Calls [SessionService.listSessions] and renders the results as a
/// fixed-width table using [format.dart] utilities. Column order: deployment
/// id, team, mode, status, start time. Newest first (the service already
/// sorts by start time descending).
class SessionListCommand extends Command<void> {
  final SessionService sessionService;

  SessionListCommand(this.sessionService);

  @override
  String get name => 'list';

  @override
  String get description =>
      'List all deployments with id, team, mode, status, and start time';

  @override
  String get invocation => 'avo session list';

  @override
  void run() {
    final sessions = sessionService.listSessions();

    print(sectionHeader('SESSIONS'));
    print('');

    if (sessions.isEmpty) {
      print('  No deployments found.');
      print('');
      print(hintPlain('Registry is empty or missing.'));
      return;
    }

    // Column widths chosen to fit a standard 80-column terminal while keeping
    // the deployment id, team, and timestamp readable. Mode is narrow because
    // Phase 1 leaves it empty for most rows (rendered as "-").
    const colDeploy = 10;
    const colTeam = 18;
    const colMode = 10;
    const colStatus = 10;
    // Start time column takes the remaining width.

    // Header
    final header = '  '
        '${'ID'.padRight(colDeploy)} '
        '${'Team'.padRight(colTeam)} '
        '${'Mode'.padRight(colMode)} '
        '${'Status'.padRight(colStatus)} '
        'Started';
    print(header);
    print('  ${'-' * (colDeploy + colTeam + colMode + colStatus + 24)}');

    for (final s in sessions) {
      final mode = s.mode.isEmpty ? '-' : s.mode;
      final started = _formatStartedAt(s.startedAt);
      final row = '  '
          '${s.deploymentId.padRight(colDeploy)} '
          '${_truncate(s.team, colTeam).padRight(colTeam)} '
          '${_truncate(mode, colMode).padRight(colMode)} '
          '${_truncate(s.status, colStatus).padRight(colStatus)} '
          '$started';
      print(row);
    }

    print('');
    print(hintPlain('${sessions.length} deployment(s).'));
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

/// `avo session start <team> --mode <mode>` — spawn a new opencode session.
///
/// Spawns `opa deploy <team> --mode <mode>` as a subprocess via
/// [SessionService.startSession] (which mirrors the `Process.start` pattern
/// from `agent_api_service.dart`). The deployment ID is extracted from opa's
/// first stdout line using the regex `Deployment: (d-[a-f0-9]+)` and printed
/// on success.
///
/// On success the spawned [Process] handle is recorded in [liveProcesses]
/// (keyed by deployment id) so `SessionAttachCommand` can forward stdin to
/// it (CQ-1 review finding). The subprocess stdout/stderr are drained and
/// detached so the process survives this command's exit; the drains are
/// properly cancelled when a live process is registered.
class SessionStartCommand extends Command<void> {
  final SessionService sessionService;

  /// In-process registry of live subprocess handles, shared with
  /// [SessionAttachCommand]. Populated here after a successful start.
  final Map<String, LiveProcess> liveProcesses;

  SessionStartCommand(this.sessionService, {required this.liveProcesses}) {
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
      'Start a new opencode session via `opa deploy` and print its '
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

    print(sectionHeader('START SESSION'));
    print('');
    print(kvRow('Team:', team));
    print(kvRow('Mode:', mode.isEmpty ? '(default)' : mode));
    print('');
    print('Spawning `opa deploy $team${mode.isEmpty ? '' : ' --mode $mode'}`…');
    print('');

    final result = await sessionService.startSession(team, mode);
    if (!result.succeeded) {
      print('Failed to start session.');
      print('');
      print(hintPlain(result.error ?? 'Unknown error.'));
      if (result.pid != null) {
        print(hintPlain('Spawned pid ${result.pid} but could not capture the '
            'deployment ID; it may need to be stopped manually.'));
      }
      return;
    }

    print('Session started.');
    print('');
    print(kvRow('Deployment:', result.deploymentId));
    print(kvRow('PID:', '${result.pid}'));
    print('');

    // Register the live process so `avo session attach` can forward stdin
    // (CQ-1: live stdin forwarding was previously unreachable because this
    // command never populated the shared map). Wrap stdout/stderr in the
    // broadcast streams exposed by the service so attach can subscribe
    // alongside the service's drain listener (OPS-2).
    final process = result.process;
    if (process != null && result.stdoutStream != null) {
      liveProcesses[result.deploymentId] = LiveProcess(
        process: process,
        stdoutStream: result.stdoutStream!,
        stderrStream: result.stderrStream ?? process.stderr,
      );
    }

    print(hintPlain('The session is running in the background. Use '
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

/// `avo session stop <deployment-id>` — terminate a running session.
/// Calls [SessionService.stopSession] with the deployment ID, which looks up
/// the recorded pid from the registry and sends SIGTERM. Prints a
/// confirmation message on success and an error when the session is not
/// running or has no recorded pid.
class SessionStopCommand extends Command<void> {
  final SessionService sessionService;

  SessionStopCommand(this.sessionService);

  @override
  String get name => 'stop';

  @override
  String get description =>
      'Stop a running opencode session by sending SIGTERM to its subprocess';

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
    if (result.signalSent) {
      print('SIGTERM sent to the session subprocess.');
      print('');
      print(hintPlain('The session will terminate and its registry entry '
          'will be updated as it exits.'));
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
/// Tails the deployment's `activity.jsonl` event stream (written in real time
/// by the opencode PA plugin) and renders each event with ANSI escape codes
/// passed through unmodified. Keyboard input is forwarded to the subprocess
/// stdin when the deployment was started in the same avo process and a live
/// [Process] handle is registered; for sessions started elsewhere (reattach
/// by deployment id) the subprocess stdin is not reachable and the command
/// runs in read-only tail mode.
///
/// Detach with Ctrl+C or Escape — the subprocess is left running. Subprocess
/// exit is detected by polling the recorded pid and by watching the registry
/// for a terminal event (completed/crashed); on exit the command prints a
/// notification and returns to the CLI.
class SessionAttachCommand extends Command<void> {
  final SessionService sessionService;

  /// Optional in-process registry of live subprocess handles, keyed by
  /// deployment id. Populated by [SessionStartCommand] when it keeps the
  /// [Process] from `startSession`; used here to forward stdin.
  final Map<String, LiveProcess> liveProcesses;

  SessionAttachCommand(this.sessionService, {this.liveProcesses = const {}});

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

    final handle = sessionService.findSession(deploymentId);
    if (handle == null) {
      print('No deployment found with id $deploymentId.');
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

    final activityFile = File(handle.activityLogPath);
    if (!activityFile.existsSync()) {
      print('No activity log found for $deploymentId at '
          '${handle.activityLogPath}.');
      print('');
      print(hintPlain('The deployment directory may have been removed.'));
      return;
    }

    final liveProcess = liveProcesses[deploymentId];
    final hasStdin = liveProcess != null;

    print(sectionHeader('ATTACH SESSION'));
    print('');
    print(kvRow('Deployment:', deploymentId));
    print(kvRow('PID:', '${handle.pid ?? '-'}'));
    print(kvRow('Mode:', hasStdin ? 'live (stdin forwarding)' : 'tail-only'));
    print('');
    print(hintPlain('Streaming live output. Ctrl+C or Esc to detach '
        '(session keeps running).'));
    print('');

    await SessionAttachRunner(
      deploymentId: deploymentId,
      activityFile: activityFile,
      pid: handle.pid,
      liveProcess: liveProcess?.process,
      stdoutStream: liveProcess?.stdoutStream,
      stderrStream: liveProcess?.stderrStream,
      registryPath: sessionService.registryPath,
    ).run();
  }

  void printUsageError(String message) {
    print(message);
    print('');
    print('Usage: $invocation');
  }
}