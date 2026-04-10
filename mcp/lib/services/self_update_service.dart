/// Self-update service for phone-triggered APK builds.
///
/// Provides endpoints:
/// - POST /api/self-update  — triggers async build via tool/deploy.sh oppo
/// - GET /api/self-update/status  — returns current build status + log tail
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Build status enum.
enum BuildStatus {
  idle,
  building,
  success,
  error,
}

/// Holds the current self-update state.
class SelfUpdateState {
  BuildStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> logLines;

  SelfUpdateState({
    this.status = BuildStatus.idle,
    this.startedAt,
    this.completedAt,
    this.logLines = const [],
  });

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'log': logLines,
      };

  SelfUpdateState copyWith({
    BuildStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? logLines,
  }) {
    return SelfUpdateState(
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      logLines: logLines ?? this.logLines,
    );
  }
}

/// Handles self-update build requests.
///
/// Runs tool/deploy.sh oppo asynchronously and captures stdout/stderr
/// into an in-memory log buffer (last 20 lines returned in status).
class SelfUpdateService {
  /// Hardcoded script path — no user input in shell command (NF2).
  static const String _deployScript = 'tool/deploy.sh';

  /// The device argument passed to the deploy script.
  static const String _deviceArg = 'oppo';

  /// Maximum log lines to retain.
  static const int _maxLogLines = 200;

  /// Current build state.
  SelfUpdateState _state = SelfUpdateState();

  /// Lock to prevent concurrent builds (F5).
  bool get _isBuilding => _state.status == BuildStatus.building;

  /// Triggers async build if not already running. Returns false if build
  /// is in progress (caller should return 409).
  bool triggerIfIdle() {
    if (_isBuilding) return false;

    _state = SelfUpdateState(
      status: BuildStatus.building,
      startedAt: DateTime.now(),
      logLines: ['Build started at ${_state.startedAt}'],
    );

    _runBuildAsync();
    return true;
  }

  /// Returns the current state as JSON.
  SelfUpdateState get state => _state;

  /// Runs the deploy script asynchronously.
  Future<void> _runBuildAsync() async {
    final logLines = <String>[];

    try {
      // Step 1: git pull to get latest code (F2)
      final repoRoot = _resolveRepoRoot();
      final pullResult = await Process.run(
        'git',
        ['pull'],
        workingDirectory: repoRoot,
      );

      logLines.add('[git pull] exit code: ${pullResult.exitCode}');
      if (pullResult.stdout.isNotEmpty) {
        for (final line in pullResult.stdout.toString().split('\n')) {
          if (line.isNotEmpty) logLines.add('[git pull] stdout: $line');
        }
      }
      if (pullResult.stderr.isNotEmpty) {
        for (final line in pullResult.stderr.toString().split('\n')) {
          if (line.isNotEmpty) logLines.add('[git pull] stderr: $line');
        }
      }

      // Step 2: Run deploy.sh oppo (F1)
      final deployPath = '$repoRoot/$_deployScript';
      logLines.add('Running: $deployPath $_deviceArg');

      final process = await Process.start(
        'bash',
        [deployPath, _deviceArg],
        workingDirectory: repoRoot,
      );

      // Capture stdout + stderr line by line
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (logLines.length < _maxLogLines) {
          logLines.add(line);
        }
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (logLines.length < _maxLogLines) {
          logLines.add('[stderr] $line');
        }
      });

      final exitCode = await process.exitCode;

      logLines.add('deploy.sh exited with code: $exitCode');

      _state = _state.copyWith(
        status: exitCode == 0 ? BuildStatus.success : BuildStatus.error,
        completedAt: DateTime.now(),
        logLines: logLines.length > 20
            ? logLines.sublist(logLines.length - 20)
            : logLines,
      );
    } catch (e, stack) {
      logLines.add('EXCEPTION: $e\n$stack');
      _state = _state.copyWith(
        status: BuildStatus.error,
        completedAt: DateTime.now(),
        logLines: logLines.length > 20
            ? logLines.sublist(logLines.length - 20)
            : logLines,
      );
    }
  }

  String _resolveRepoRoot() {
    // Use Platform.script to derive the repo root
    // Works when running from the avodah repo via dart run
    final script = Platform.script.toFilePath();
    // mcp/bin/sync_server.dart → repo root is two levels up from mcp/bin/
    final idx = script.indexOf('/mcp/bin/');
    if (idx != -1) {
      return script.substring(0, idx);
    }
    // Fallback: assume CWD is repo root
    return Directory.current.path;
  }
}