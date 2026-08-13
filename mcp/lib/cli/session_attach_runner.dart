/// Drives the live attach loop for `avo session attach`.
///
/// Extracted from `session_commands.dart` (CQ-3 review finding) to keep each
/// CLI source file under the ~400 line guideline. Tails `activity.jsonl`,
/// renders events, polls the subprocess for exit, and detaches on Ctrl+C /
/// Escape. The keyboard watcher is cancelled via a [Completer] (CQ-4) so the
/// loop exits before terminal cleanup.
library;

import 'dart:async';
import 'dart:io';

import 'package:dart_console/dart_console.dart';

import 'format.dart';

class SessionAttachRunner {
  final String deploymentId;
  final File activityFile;
  final int? pid;
  final Process? liveProcess;
  final Stream<List<int>>? stdoutStream;
  final Stream<List<int>>? stderrStream;
  final String registryPath;

  SessionAttachRunner({
    required this.deploymentId,
    required this.activityFile,
    required this.pid,
    required this.liveProcess,
    this.stdoutStream,
    this.stderrStream,
    required this.registryPath,
  });

  Future<void> run() async {
    final console = Console();
    final hasTty = stdin.hasTerminal;

    // Enter raw mode so we can intercept Ctrl+C / Escape without waiting for
    // a full line. When there is no TTY (pipes, CI) we skip the keyboard watch
    // and just stream until the subprocess exits.
    var rawMode = false;
    if (hasTty) {
      stdin.echoMode = false;
      stdin.lineMode = false;
      rawMode = true;
    }

    var detached = false;
    var exited = false;

    final stdoutSub = stdoutStream?.listen((bytes) {
      // Raw byte-level passthrough — ANSI escape codes flow unmodified.
      stdout.add(bytes);
    });
    final stderrSub = stderrStream?.listen((bytes) {
      stderr.add(bytes);
    });

    final exitCompleter = Completer<int>();
    Future<void> exitWatcher() async {
      final p = liveProcess;
      if (p != null) {
        final code = await p.exitCode;
        if (!exitCompleter.isCompleted) exitCompleter.complete(code);
        return;
      }
      // No live handle — poll the pid and registry for exit.
      while (true) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (pid != null) {
          final alive = _pidAlive(pid!);
          if (!alive) {
            if (!exitCompleter.isCompleted) exitCompleter.complete(0);
            return;
          }
        }
        if (_registryHasTerminalEvent(deploymentId, registryPath)) {
          if (!exitCompleter.isCompleted) exitCompleter.complete(0);
          return;
        }
      }
    }

    // CQ-4: cancel the keyboard watcher via a Completer so the loop exits
    // before terminal cleanup instead of relying on .ignore() which leaks
    // the readKey() call until the next keypress arrives.
    final keyboardCancel = Completer<void>();
    Future<void> keyboardWatcher() async {
      if (!hasTty) return;
      while (!keyboardCancel.isCompleted) {
        final key = console.readKey();
        if (keyboardCancel.isCompleted) return;
        if (key.controlChar == ControlCharacter.ctrlC ||
            key.controlChar == ControlCharacter.escape) {
          detached = true;
          return;
        } else if (liveProcess != null &&
            key.controlChar == ControlCharacter.enter) {
          liveProcess!.stdin.add('\n'.codeUnits);
        } else if (liveProcess != null &&
            key.controlChar == ControlCharacter.none &&
            key.char.isNotEmpty) {
          liveProcess!.stdin.add(key.char.codeUnits);
        }
      }
    }

    final tailSub = _tailActivity(activityFile, (line) {
      stdout.writeln(line);
    });

    unawaited(exitWatcher());

    // Run the keyboard watcher and exit watcher concurrently; whichever
    // completes first (detach or subprocess exit) ends the loop.
    final keyboardFuture = keyboardWatcher();

    await Future.any<Object?>([
      keyboardFuture.then((_) => 'detach'),
      exitCompleter.future.then((code) {
        exited = true;
        return 'exit:$code';
      }),
    ]);

    // Cleanup.
    detached = detached || exited;
    if (!keyboardCancel.isCompleted) keyboardCancel.complete();
    await tailSub.cancel();
    await stdoutSub?.cancel();
    await stderrSub?.cancel();

    if (rawMode) {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }

    stdout.writeln('');
    if (exited) {
      print(sectionHeader('SESSION EXIT'));
      print('');
      print('Session $deploymentId has exited.');
    } else {
      print(sectionHeader('DETACHED'));
      print('');
      print('Detached from $deploymentId. The session is still running.');
      print(hintPlain('Use `avo session list` to check its status or '
          '`avo session stop $deploymentId` to terminate it.'));
    }
  }

  /// Tails [file] from the current end, invoking [onLine] for each new line
  /// as it appears. Returns a subscription that can be cancelled to stop
  /// tailing.
  StreamSubscription<List<int>> _tailActivity(
      File file, void Function(String) onLine) {
    final controller = StreamController<List<int>>();
    late StreamSubscription<void> timerSub;
    var offset = file.existsSync() ? file.lengthSync() : 0;
    final buffer = <int>[];

    timerSub = Stream<void>.periodic(const Duration(milliseconds: 100))
        .listen((_) async {
      if (!file.existsSync()) return;
      final len = file.lengthSync();
      if (len <= offset) return;
      final raf = file.openSync(mode: FileMode.read);
      try {
        raf.setPositionSync(offset);
        final chunk = raf.readSync(len - offset);
        offset = len;
        controller.add(chunk);
      } finally {
        raf.closeSync();
      }
    });

    final dataSub = controller.stream.listen((chunk) {
      buffer.addAll(chunk);
      while (true) {
        final nl = buffer.indexOf(0x0a);
        if (nl < 0) break;
        final line = String.fromCharCodes(buffer.sublist(0, nl));
        buffer.removeRange(0, nl + 1);
        onLine(line);
      }
    });
    dataSub.onDone(timerSub.cancel);
    return dataSub;
  }

  /// Returns true when [pid] is still alive. Sends signal 0 (no-op) via the
  /// `kill` shell command — exit code 0 means alive, non-zero means gone.
  static bool _pidAlive(int pid) {
    try {
      final r = Process.runSync('kill', ['-0', pid.toString()]);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Returns true when the registry has a terminal event (completed/crashed)
  /// for [deploymentId].
  static bool _registryHasTerminalEvent(
      String deploymentId, String registryPath) {
    final file = File(registryPath);
    if (!file.existsSync()) return false;
    for (final line in file.readAsLinesSync()) {
      if (line.isEmpty) continue;
      if (!line.contains(deploymentId)) continue;
      if (line.contains('"event":"completed"') ||
          line.contains('"event":"crashed"')) {
        return true;
      }
    }
    return false;
  }
}