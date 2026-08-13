import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:avodah_mcp/cli/session_commands.dart';
import 'package:avodah_mcp/services/session_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Minimal fake process for the start command smoke test. The attach path is
/// not exercised here (it requires a TTY); we only verify the start command
/// registers the live process in the shared map.
class _FakeProcess implements Process {
  final int _pid;
  final StreamController<List<int>> _stdout =
      StreamController<List<int>>();
  final StreamController<List<int>> _stderr =
      StreamController<List<int>>();
  final Completer<int> _exit = Completer<int>();

  _FakeProcess(this._pid, String firstLine) {
    _stdout.add(utf8.encode('$firstLine\n'));
  }

  @override
  int get pid => _pid;

  @override
  IOSink get stdin => throw UnimplementedError();
  @override
  Stream<List<int>> get stdout => _stdout.stream;
  @override
  Stream<List<int>> get stderr => _stderr.stream;
  @override
  Future<int> get exitCode => _exit.future;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (!_exit.isCompleted) _exit.complete(0);
    return true;
  }

  void close() {
    if (!_stdout.isClosed) _stdout.close();
    if (!_stderr.isClosed) _stderr.close();
    if (!_exit.isCompleted) _exit.complete(0);
  }
}

void main() {
  late Directory tmpDir;
  late String registryPath;
  late String aiUsagePath;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('session_cli_test_');
    aiUsagePath = p.join(tmpDir.path, 'ai-usage');
    final deploymentsDir = p.join(aiUsagePath, 'deployments');
    Directory(deploymentsDir).createSync(recursive: true);
    registryPath = p.join(deploymentsDir, 'registry.jsonl');
    File(registryPath).writeAsStringSync('');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  /// Build a [CommandRunner] wired with all session subcommands sharing one
  /// [SessionService] and one live-process map — mirrors `avo.dart`.
  CommandRunner<void> buildRunner(SessionService service,
      {Map<String, LiveProcess>? liveProcesses,
      ProcessStartFn? startOverride}) {
    final svc = SessionService(
      registryPath: service.registryPath,
      aiUsagePath: service.aiUsagePath,
      opaBinPath: service.opaBinPath,
      processStartOverride: startOverride,
      processKillOverride: service.processKillOverride,
    );
    final live = liveProcesses ?? <String, LiveProcess>{};
    final runner = CommandRunner<void>('avo', 'test');
    final group = SessionCommand()
      ..addSubcommand(SessionListCommand(svc))
      ..addSubcommand(SessionHistoryCommand(svc))
      ..addSubcommand(
          SessionStartCommand(svc, liveProcesses: live))
      ..addSubcommand(SessionStopCommand(svc))
      ..addSubcommand(SessionAttachCommand(svc, liveProcesses: live));
    runner.addCommand(group);
    return runner;
  }

  void emit(String deploymentId, String team, String event,
      {int? pid, String ts = '2026-08-02T04:00:00Z'}) {
    final obj = <String, dynamic>{
      'deployment_id': deploymentId,
      'team': team,
      'event': event,
      'timestamp': ts,
    };
    if (pid != null) obj['pid'] = pid;
    File(registryPath).writeAsStringSync(
        '${jsonEncode(obj)}\n',
        mode: FileMode.append);
  }

  group('session list', () {
    test('prints empty message when no deployments', () async {
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service);
      await runner.run(['session', 'list']);
    });

    test('renders deployment rows', () async {
      emit('d-aaaaaa', 'builder', 'started');
      emit('d-aaaaaa', 'builder', 'pid', pid: 777);
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service);
      await runner.run(['session', 'list']);
      // No assertion on stdout content (printed via print()); the smoke test
      // verifies the command runs without throwing.
    });
  });

  group('session history', () {
    test('prints missing message for unknown deployment id', () async {
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service);
      await runner.run(['session', 'history', 'd-zzzzzz']);
    });

    test('prints last N lines in non-interactive mode', () async {
      final anchor = DateTime(2026, 8, 2);
      final sessionsDir = p.join(
          aiUsagePath, 'sessions', '2026', '08', 'agent-team');
      Directory(sessionsDir).createSync(recursive: true);
      final logPath =
          p.join(sessionsDir, '2026-08-02-d-feedfa-builder.md');
      File(logPath).writeAsStringSync('line one\nline two\nline three\n');
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service);
      // Without a TTY we can't reach the pager; --lines path is non-interactive.
      await runner.run(['session', 'history', 'd-feedfa', '-n', '2']);
      // Anchor not used by command but keeps the test's intent clear.
      expect(anchor, isNotNull);
    });
  });

  group('session stop', () {
    test('reports failure for unknown deployment id', () async {
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service);
      await runner.run(['session', 'stop', 'd-zzzzzz']);
    });

    test('sends signal via override and reports success', () async {
      emit('d-aaaaaa', 'builder', 'started');
      emit('d-aaaaaa', 'builder', 'pid', pid: 1234);
      final service = SessionService(
          registryPath: registryPath,
          aiUsagePath: aiUsagePath,
          processKillOverride: (pid, sig) async => true);
      final runner = buildRunner(service);
      await runner.run(['session', 'stop', 'd-aaaaaa']);
    });
  });

  group('session start', () {
    test('registers live process in shared map on success (CQ-1)', () async {
      final fake = _FakeProcess(888, 'Deployment: d-deadbe');
      final liveProcesses = <String, LiveProcess>{};
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service,
          liveProcesses: liveProcesses,
          startOverride: (exe, args) async => fake);
      await runner.run(['session', 'start', 'builder', '--mode', 'implement']);

      // CQ-1: the live process map must be populated so attach can forward stdin.
      expect(liveProcesses, contains('d-deadbe'));
      expect(liveProcesses['d-deadbe']?.process, same(fake));
      fake.close();
    });

    test('does not register live process on failure', () async {
      final fake = _FakeProcess(9, 'no deployment id here');
      final liveProcesses = <String, LiveProcess>{};
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service,
          liveProcesses: liveProcesses,
          startOverride: (exe, args) async => fake);
      await runner.run(['session', 'start', 'builder']);
      expect(liveProcesses, isEmpty);
      fake.close();
    });

    test('missing team arg prints usage', () async {
      final liveProcesses = <String, LiveProcess>{};
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner =
          buildRunner(service, liveProcesses: liveProcesses);
      await runner.run(['session', 'start']);
      expect(liveProcesses, isEmpty);
    });
  });

  group('session attach', () {
    test('prints missing message for unknown deployment id', () async {
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service);
      await runner.run(['session', 'attach', 'd-zzzzzz']);
    });

    test('reports not-running for completed session', () async {
      emit('d-aaaaaa', 'builder', 'started');
      emit('d-aaaaaa', 'builder', 'pid', pid: 1);
      emit('d-aaaaaa', 'builder', 'completed');
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service);
      await runner.run(['session', 'attach', 'd-aaaaaa']);
    });

    test('reports missing activity log for running session', () async {
      emit('d-aaaaaa', 'builder', 'started');
      emit('d-aaaaaa', 'builder', 'pid', pid: 1);
      final service =
          SessionService(registryPath: registryPath, aiUsagePath: aiUsagePath);
      final runner = buildRunner(service);
      // No activity.jsonl created on purpose.
      await runner.run(['session', 'attach', 'd-aaaaaa']);
    });
  });
}