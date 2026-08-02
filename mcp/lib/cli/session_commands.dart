/// `avo session` subcommands for managing opencode sessions.
///
/// Phase 2 + Phase 3 deliverables for AVO-116 (opencode session integration).
/// Implements:
/// - `SessionListCommand` — renders all deployments from the registry as a
///   formatted table (deployment id, team, mode, status, start time).
/// - `SessionHistoryCommand` — opens a session's conversation log file in a
///   scrollable read-only pager.
/// - `SessionStartCommand` — spawns `opa deploy <team> --mode <mode>` as a
///   subprocess and captures the deployment ID from opa's stdout.
/// - `SessionStopCommand` — sends SIGTERM to a running session's subprocess.
///
/// Command registration in `avo.dart` is handled by Phase 5; this file only
/// defines the command classes so they can be wired up later.
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';

import '../services/session_service.dart';
import 'format.dart';

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
    _Pager(lines, logFile.path, deploymentId).run();
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
/// Attach mode (streaming the subprocess stdout live) is a Phase 4
/// deliverable; this command only captures the deployment ID and leaves the
/// subprocess running in the background. The process handle is drained and
/// detached so it survives this command's exit.
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

    // Drain and detach the subprocess so it survives this command's exit.
    // Phase 4 will replace this with live attach mode.
    result.process?.stdout.listen((_) {});
    result.process?.stderr.listen((_) {});

    print(hintPlain('The session is running in the background. Use '
        '`avo session stop ${result.deploymentId}` to terminate it.'));
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
///
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
// Simple read-only pager
// ============================================================

/// Minimal read-only pager built on `dart_console`.
///
/// Renders a window of lines from [lines] and responds to:
/// - ↑ / ↓ — scroll one line
/// - Page Up / Page Down — scroll one page
/// - Home / End — jump to top / bottom
/// - `q`, `Esc`, `Ctrl+C` — quit
///
/// The pager is intentionally simple: it redraws the whole visible window on
/// each keypress rather than diffing, which keeps the code small and avoids
/// ANSI scroll-region tricks that don't survive all terminals.
class _Pager {
  final List<String> lines;
  final String filePath;
  final String deploymentId;

  _Pager(this.lines, this.filePath, this.deploymentId);

  void run() {
    final console = Console();
    final height = console.windowHeight;
    // Reserve 2 lines for the status bar (top) and the help line (bottom).
    final visibleRows = height > 4 ? height - 3 : 1;
    final maxWidth = console.windowWidth;

    var topLine = 0;
    var needsRedraw = true;

    stdin.echoMode = false;
    stdin.lineMode = false;
    console.hideCursor();
    try {
      while (true) {
        if (needsRedraw) {
          _render(console, topLine, visibleRows, maxWidth);
          needsRedraw = false;
        }

        final key = console.readKey();

        if (key.controlChar == ControlCharacter.ctrlC ||
            key.controlChar == ControlCharacter.escape ||
            (key.controlChar == ControlCharacter.none &&
                key.char.toLowerCase() == 'q')) {
          // Clear the pager area before returning so the shell prompt isn't
          // left covered by stale log output.
          console.showCursor();
          stdout.write('\r\x1B[J');
          return;
        } else if (key.controlChar == ControlCharacter.arrowDown) {
          final maxTop = _maxTop(visibleRows);
          if (topLine < maxTop) {
            topLine++;
            needsRedraw = true;
          }
        } else if (key.controlChar == ControlCharacter.arrowUp) {
          if (topLine > 0) {
            topLine--;
            needsRedraw = true;
          }
        } else if (key.controlChar == ControlCharacter.pageDown) {
          final maxTop = _maxTop(visibleRows);
          final next = topLine + visibleRows;
          topLine = next > maxTop ? maxTop : next;
          needsRedraw = true;
        } else if (key.controlChar == ControlCharacter.pageUp) {
          final prev = topLine - visibleRows;
          topLine = prev < 0 ? 0 : prev;
          needsRedraw = true;
        } else if (key.controlChar == ControlCharacter.home) {
          topLine = 0;
          needsRedraw = true;
        } else if (key.controlChar == ControlCharacter.end) {
          topLine = _maxTop(visibleRows);
          needsRedraw = true;
        }
      }
    } finally {
      console.showCursor();
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  int _maxTop(int visibleRows) {
    if (lines.length <= visibleRows) return 0;
    return lines.length - visibleRows;
  }

  void _render(Console console, int topLine, int visibleRows, int maxWidth) {
    stdout.write('\r\x1B[J');

    // Status bar (line 1).
    final bottom = topLine + visibleRows > lines.length
        ? lines.length
        : topLine + visibleRows;
    final status = ' $deploymentId  ${bottom}/${lines.length}  $filePath';
    console.setForegroundColor(ConsoleColor.blue);
    stdout.writeln(_truncateForDisplay(status, maxWidth));
    console.resetColorAttributes();

    // Visible log lines.
    final end = topLine + visibleRows;
    for (var i = topLine; i < end && i < lines.length; i++) {
      stdout.writeln(_truncateForDisplay(lines[i], maxWidth));
    }

    // Pad the window to visibleRows so the help line stays at the bottom.
    final rendered = (end > lines.length ? lines.length : end) - topLine;
    for (var i = rendered; i < visibleRows; i++) {
      stdout.writeln('');
    }

    // Help line.
    console.setForegroundColor(ConsoleColor.brightBlack);
    stdout.write(
        '↑/↓ scroll · PgUp/PgDn · Home/End · q/Esc quit');
    console.resetColorAttributes();
  }

  /// Truncates [text] to [maxWidth] display columns, appending an ellipsis
  /// when truncated. Treats each code unit as one column, which is correct
  /// for the ASCII-heavy session logs and simple enough for the pager.
  static String _truncateForDisplay(String text, int maxWidth) {
    if (maxWidth <= 0) return '';
    if (text.length <= maxWidth) return text;
    if (maxWidth <= 1) return '\u2026';
    return '${text.substring(0, maxWidth - 1)}\u2026';
  }
}