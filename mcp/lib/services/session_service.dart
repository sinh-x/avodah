/// Session service for managing opencode sessions from the Avodah CLI.
///
/// Provides read-only listing of deployments from the registry, subprocess
/// lifecycle (start/stop), and session log discovery. Reuses
/// [parseRegistryFile] and [computeDeploymentStatuses] from
/// `registry_parser.dart` and the `Process.start` pattern from
/// `agent_api_service.dart`.
///
/// Phase 1 deliverable for AVO-116 (opencode session integration). Only the
/// service layer lives here — CLI command wiring arrives in later phases.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'registry_parser.dart';

/// Summary of a single deployment, intended for `avo session list`.
///
/// Thin projection over [DeploymentStatus] with the fields the session
/// command surfaces. Kept as an immutable value type so callers (including
/// tests) can construct expected values without touching the registry.
class SessionSummary {
  final String deploymentId;
  final String team;
  final String mode;
  final String status;
  final String startedAt;
  final int? pid;

  const SessionSummary({
    required this.deploymentId,
    required this.team,
    required this.mode,
    required this.status,
    required this.startedAt,
    this.pid,
  });

  @override
  String toString() =>
      'SessionSummary($deploymentId, team=$team, mode=$mode, status=$status, '
      'startedAt=$startedAt, pid=$pid)';
}

/// Result of a `startSession` attempt.
class StartSessionResult {
  /// Deployment ID extracted from `opa deploy`'s first output line.
  ///
  /// Empty string when extraction failed (e.g. timeout or no match).
  final String deploymentId;

  /// OS pid of the spawned `opa` subprocess. Null if spawn failed.
  final int? pid;

  /// The running subprocess, when the caller wants to attach to it.
  ///
  /// Phase 1 returns the process so a future attach command can wire
  /// stdin/stdout. The service does not retain ownership — the caller is
  /// responsible for draining or terminating it.
  final Process? process;

  /// Human-readable error message when [deploymentId] is empty.
  final String? error;

  const StartSessionResult({
    required this.deploymentId,
    this.pid,
    this.process,
    this.error,
  });

  bool get succeeded => deploymentId.isNotEmpty && pid != null;
}

/// Outcome of `stopSession`.
class StopSessionResult {
  final String deploymentId;
  final bool signalSent;
  final String? error;

  const StopSessionResult({
    required this.deploymentId,
    required this.signalSent,
    this.error,
  });
}

/// Business logic for `avo session …` subcommands.
///
/// All filesystem and process access goes through injectable paths so the
/// service is testable without touching the real registry or spawning real
/// subprocesses. The default constructors resolve the standard PA locations
/// from `HOME` and `PA_BIN`.
class SessionService {
  /// Path to `registry.jsonl`.
  final String registryPath;

  /// Base path of the ai-usage tree (used to locate session logs).
  final String aiUsagePath;

  /// Path to the `opa` binary used by `startSession`.
  final String opaBinPath;

  /// Override for `Process.start` — used by tests to avoid real spawns.
  ///
  /// When null, `startSession` calls [Process.start] directly.
  final ProcessStartFn? processStartOverride;

  /// Override for sending a signal to a pid — used by tests.
  ///
  /// When null, `stopSession` calls [Process.killPid].
  final ProcessKillFn? processKillOverride;

  SessionService({
    String? registryPath,
    String? aiUsagePath,
    String? opaBinPath,
    this.processStartOverride,
    this.processKillOverride,
  })  : registryPath = registryPath ??
            p.join(Platform.environment['HOME'] ?? '/home', 'Documents',
                'ai-usage', 'deployments', 'registry.jsonl'),
        aiUsagePath = aiUsagePath ??
            p.join(
                Platform.environment['HOME'] ?? '/home', 'Documents',
                'ai-usage'),
        opaBinPath = opaBinPath ?? Platform.environment['OPA_BIN'] ?? 'opa';

  /// List all deployments as [SessionSummary] records.
  ///
  /// Reads and parses [registryPath] via [parseRegistryFile] +
  /// [computeDeploymentStatuses]. The mode is derived from the primer path
  /// embedded in the "started" event when present (best-effort); otherwise
  /// empty. Returns an empty list when the registry is missing.
  List<SessionSummary> listSessions() {
    final events = parseRegistryFile(registryPath);
    if (events.isEmpty) return [];
    final statuses = computeDeploymentStatuses(events);
    // Build a lookup of primer → mode by scanning started events.
    final primerByDeploy = <String, String>{};
    for (final e in events) {
      if (e.event == 'started') {
        // The "mode" is not a dedicated field in the registry; the primer
        // path sometimes encodes it. We leave mode empty for now — Phase 2
        // may surface it from the primer file. Keep the field stable so the
        // CLI can render a column without further refactor.
        primerByDeploy.putIfAbsent(e.deploymentId, () => '');
      }
    }
    return statuses
        .map((s) => SessionSummary(
              deploymentId: s.deploymentId,
              team: s.team,
              mode: primerByDeploy[s.deploymentId] ?? '',
              status: s.status,
              startedAt: s.startedAt,
              pid: s.pid,
            ))
        .toList(growable: false);
  }

  /// Spawn `opa deploy <team> --mode <mode>` and capture the deployment ID.
  ///
  /// Mirrors the pattern in `agent_api_service.dart:_handleStartDeployment`:
  /// read stdout until the first newline, extract `d-<hex6>` via regex. The
  /// returned [StartSessionResult.process] is the live subprocess — callers
  /// that want to attach must drain its stdout/stderr.
  ///
  /// [extraArgs] forwarded after the standard args (e.g. `--ticket`,
  /// `--provider`, `--objective`). [timeout] bounds the wait for the first
  /// stdout line; defaults to 5s matching the agent API.
  Future<StartSessionResult> startSession(
    String team,
    String mode, {
    List<String> extraArgs = const [],
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final args = [
      'deploy',
      team,
      '--mode',
      mode,
      ...extraArgs,
    ];

    final Process process;
    try {
      if (processStartOverride != null) {
        process = await processStartOverride!(opaBinPath, args);
      } else {
        process = await Process.start(opaBinPath, args, runInShell: false);
      }
    } catch (e) {
      return StartSessionResult(
        deploymentId: '',
        error: 'Failed to start opa deploy: $e',
      );
    }

    // Drain stderr to avoid back-pressure.
    process.stderr.listen((_) {});

    final completer = Completer<String>();
    var partial = '';
    final sub = process.stdout.transform(utf8.decoder).listen(
      (chunk) {
        if (completer.isCompleted) return;
        final nl = chunk.indexOf('\n');
        if (nl >= 0) {
          completer.complete(partial + chunk.substring(0, nl));
        } else {
          partial += chunk;
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(partial);
      },
      onError: (Object e) {
        if (!completer.isCompleted) completer.complete('');
      },
      cancelOnError: true,
    );

    final String firstLine;
    try {
      firstLine = await completer.future
          .timeout(timeout, onTimeout: () => '');
    } finally {
      await sub.cancel();
    }

    final match = RegExp(r'\b(d-[a-f0-9]{6})\b').firstMatch(firstLine);
    final deploymentId = match?.group(1) ?? '';
    if (deploymentId.isEmpty) {
      // Best-effort cleanup: kill the spawned process so we don't leak it
      // when the deployment ID couldn't be captured.
      try {
        process.kill(ProcessSignal.sigterm);
      } catch (_) {}
      return StartSessionResult(
        deploymentId: '',
        pid: process.pid,
        error: 'Could not extract deployment ID from opa output: '
            '"$firstLine"',
      );
    }
    return StartSessionResult(
      deploymentId: deploymentId,
      pid: process.pid,
      process: process,
    );
  }

  /// Send SIGTERM to the subprocess tracking [deploymentId].
  ///
  /// Looks up the pid from the registry (the most recent "pid" event for the
  /// deployment). Returns [StopSessionResult.signalSent] false when no pid is
  /// recorded or the signal could not be delivered. This method does NOT
  /// update the registry file — the deployment's own completion/crashed
  /// event is written by the `opa` process itself as it terminates.
  Future<StopSessionResult> stopSession(String deploymentId) async {
    final summaries = listSessions();
    final match =
        summaries.where((s) => s.deploymentId == deploymentId).firstOrNull;
    if (match == null) {
      return StopSessionResult(
        deploymentId: deploymentId,
        signalSent: false,
        error: 'No deployment found with id $deploymentId',
      );
    }
    final pid = match.pid;
    if (pid == null) {
      return StopSessionResult(
        deploymentId: deploymentId,
        signalSent: false,
        error: 'Deployment $deploymentId has no recorded pid',
      );
    }
    try {
      if (processKillOverride != null) {
        final ok = await processKillOverride!(pid, ProcessSignal.sigterm);
        return StopSessionResult(
            deploymentId: deploymentId, signalSent: ok);
      }
      final ok = Process.killPid(pid, ProcessSignal.sigterm);
      return StopSessionResult(
          deploymentId: deploymentId, signalSent: ok);
    } catch (e) {
      return StopSessionResult(
        deploymentId: deploymentId,
        signalSent: false,
        error: 'Failed to signal pid $pid: $e',
      );
    }
  }

  /// Locate the session conversation log file for [deploymentId].
  ///
  /// Session logs live under `~/Documents/ai-usage/sessions/YYYY/MM/` and are
  /// typically nested one level deeper under a team subfolder such as
  /// `agent-team/`. Filenames are of the form
  /// `YYYY-MM-DD-<deploymentId>-….md`. We scan the current month and the
  /// previous month (rolling window) recursively and return the first match.
  /// Returns null when no log is found.
  ///
  /// [atReference] may be supplied (mainly by tests) to anchor the search
  /// clock; defaults to [DateTime.now].
  File? getSessionLog(String deploymentId, {DateTime? atReference}) {
    final anchor = atReference ?? DateTime.now();
    final candidates = <String>[];
    for (final offset in [0, 1]) {
      final dt = DateTime(anchor.year, anchor.month - offset);
      final dir = p.join(aiUsagePath, 'sessions',
          dt.year.toString(), dt.month.toString().padLeft(2, '0'));
      candidates.add(dir);
    }
    for (final dir in candidates) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      // Recursive listing so the team subfolder (e.g. `agent-team/`) is
      // covered without hard-coding its name.
      for (final entry in d.listSync(followLinks: false, recursive: true)) {
        if (entry is File && p.basename(entry.path).contains(deploymentId)) {
          return entry;
        }
      }
    }
    return null;
  }
}

/// Function signature for [SessionService.processStartOverride].
typedef ProcessStartFn = Future<Process> Function(
    String executable, List<String> args);

/// Function signature for [SessionService.processKillOverride].
typedef ProcessKillFn = Future<bool> Function(int pid, ProcessSignal signal);