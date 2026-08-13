import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avodah_mcp/services/session_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Fake `opa` subprocess used to exercise [SessionService.startSession] without
/// spawning a real process. Emits a deployment id line on stdout, then keeps
/// running until the test kills it.
class _FakeProcess implements Process {
  final int _pid;
  final String _firstLine;
  final StreamController<List<int>> _stdout =
      StreamController<List<int>>();
  final StreamController<List<int>> _stderr =
      StreamController<List<int>>();
  final Completer<int> _exit = Completer<int>();

  _FakeProcess(this._pid, this._firstLine) {
    // Emit the deployment id on stdout, then leave the stream open so the
    // service's first-line listener can complete.
    _stdout.add(utf8.encode('$_firstLine\n'));
  }

  @override
  int get pid => _pid;

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  IOSink get stdin => throw UnimplementedError();

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
    tmpDir = Directory.systemTemp.createTempSync('session_service_test_');
    aiUsagePath = p.join(tmpDir.path, 'ai-usage');
    final deploymentsDir = p.join(aiUsagePath, 'deployments');
    Directory(deploymentsDir).createSync(recursive: true);
    registryPath = p.join(deploymentsDir, 'registry.jsonl');
    File(registryPath).writeAsStringSync('');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  /// Append a registry event line.
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

  group('listSessions', () {
    test('returns empty when registry missing', () {
      final service = SessionService(
        registryPath: p.join(tmpDir.path, 'nope.jsonl'),
        aiUsagePath: aiUsagePath,
      );
      expect(service.listSessions(), isEmpty);
    });

    test('returns empty when registry empty', () {
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      expect(service.listSessions(), isEmpty);
    });

    test('lists running deployment with pid', () {
      emit('d-aaaaaa', 'builder', 'started');
      emit('d-aaaaaa', 'builder', 'pid', pid: 12345);
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final sessions = service.listSessions();
      expect(sessions, hasLength(1));
      final s = sessions.single;
      expect(s.deploymentId, 'd-aaaaaa');
      expect(s.team, 'builder');
      expect(s.status, 'running');
      expect(s.pid, 12345);
    });

    test('completed status reflects completion event', () {
      emit('d-bbbbbb', 'builder', 'started');
      emit('d-bbbbbb', 'builder', 'pid', pid: 99);
      emit('d-bbbbbb', 'builder', 'completed', ts: '2026-08-02T05:00:00Z');
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final s = service.listSessions().single;
      expect(s.status, 'success');
    });

    test('crashed status reflects crashed event', () {
      emit('d-cccccc', 'builder', 'started');
      emit('d-cccccc', 'builder', 'pid', pid: 1);
      emit('d-cccccc', 'builder', 'crashed');
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      expect(service.listSessions().single.status, 'crashed');
    });

    test('sorts newest first', () {
      emit('d-oldold', 'builder', 'started', ts: '2026-08-01T00:00:00Z');
      emit('d-newnew', 'builder', 'started', ts: '2026-08-02T00:00:00Z');
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final ids = service.listSessions().map((s) => s.deploymentId).toList();
      expect(ids, ['d-newnew', 'd-oldold']);
    });
  });

  group('findSession', () {
    test('returns null for unknown deployment id', () {
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      expect(service.findSession('d-zzzzzz'), isNull);
    });

    test('returns handle with activity log path under deployments dir', () {
      emit('d-aaaaaa', 'builder', 'started');
      emit('d-aaaaaa', 'builder', 'pid', pid: 55);
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final handle = service.findSession('d-aaaaaa');
      expect(handle, isNotNull);
      expect(handle!.pid, 55);
      expect(handle.status, 'running');
      expect(handle.activityLogPath,
          p.join(aiUsagePath, 'deployments', 'd-aaaaaa', 'activity.jsonl'));
    });
  });

  group('stopSession', () {
    test('returns false when deployment unknown', () async {
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final r = await service.stopSession('d-zzzzzz');
      expect(r.signalSent, isFalse);
      expect(r.error, isNotNull);
    });

    test('returns false when no pid recorded', () async {
      emit('d-aaaaaa', 'builder', 'started');
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final r = await service.stopSession('d-aaaaaa');
      expect(r.signalSent, isFalse);
      expect(r.error, contains('no recorded pid'));
    });

    test('sends SIGTERM via kill override', () async {
      emit('d-aaaaaa', 'builder', 'started');
      emit('d-aaaaaa', 'builder', 'pid', pid: 1234);
      var signaledPid = -1;
      var signalCount = 0;
      final service = SessionService(
          registryPath: registryPath,
          aiUsagePath: aiUsagePath,
          processKillOverride: (pid, sig) async {
            signaledPid = pid;
            signalCount++;
            return true;
          });
      final r = await service.stopSession('d-aaaaaa');
      expect(r.signalSent, isTrue);
      expect(signaledPid, 1234);
      expect(signalCount, 1);
    });

    test('returns false when kill override throws', () async {
      emit('d-aaaaaa', 'builder', 'started');
      emit('d-aaaaaa', 'builder', 'pid', pid: 1234);
      final service = SessionService(
          registryPath: registryPath,
          aiUsagePath: aiUsagePath,
          processKillOverride: (pid, sig) async {
            throw StateError('boom');
          });
      final r = await service.stopSession('d-aaaaaa');
      expect(r.signalSent, isFalse);
      expect(r.error, contains('boom'));
    });
  });

  group('startSession', () {
    test('returns deployment id and pid on success', () async {
      final fake = _FakeProcess(4242, 'Deployment: d-abcdef');
      final service = SessionService(
          registryPath: registryPath,
          aiUsagePath: aiUsagePath,
          processStartOverride: (exe, args) async => fake);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isTrue);
      expect(r.deploymentId, 'd-abcdef');
      expect(r.pid, 4242);
      expect(r.process, same(fake));
      // Broadcast streams must be exposed so attach mode can subscribe
      // alongside the service's drain listener (OPS-2).
      expect(r.stdoutStream, isNotNull);
      expect(r.stderrStream, isNotNull);
      fake.close();
    });

    test('returns failure when no deployment id in output', () async {
      final fake = _FakeProcess(99, 'totally unrelated output');
      final service = SessionService(
          registryPath: registryPath,
          aiUsagePath: aiUsagePath,
          processStartOverride: (exe, args) async => fake);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.deploymentId, isEmpty);
      expect(r.pid, 99);
      expect(r.error, isNotNull);
      fake.close();
    });

    test('returns failure when start override throws', () async {
      final service = SessionService(
          registryPath: registryPath,
          aiUsagePath: aiUsagePath,
          processStartOverride: (exe, args) async {
            throw StateError('no opa binary');
          });
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.error, contains('Failed to start opa deploy'));
    });

    test('forwards extraArgs and mode into process args', () async {
      String? capturedExe;
      List<String>? capturedArgs;
      final fake = _FakeProcess(7, 'Deployment: d-feedfa');
      final service = SessionService(
          registryPath: registryPath,
          aiUsagePath: aiUsagePath,
          processStartOverride: (exe, args) async {
            capturedExe = exe;
            capturedArgs = args;
            return fake;
          });
      await service.startSession('builder', 'analyze',
          extraArgs: ['--ticket', 'AVO-1']);
      expect(capturedExe, isNotNull);
      expect(capturedArgs, contains('deploy'));
      expect(capturedArgs, contains('builder'));
      expect(capturedArgs, contains('--mode'));
      expect(capturedArgs, contains('analyze'));
      expect(capturedArgs, contains('--ticket'));
      expect(capturedArgs, contains('AVO-1'));
      fake.close();
    });
  });

  group('getSessionLog', () {
    test('returns null when no log exists for deployment id', () {
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      expect(service.getSessionLog('d-zzzzzz', atReference: DateTime(2026, 8, 2)),
          isNull);
    });

    test('finds log in current month', () {
      final anchor = DateTime(2026, 8, 2);
      final sessionsDir = p.join(
          aiUsagePath, 'sessions', '2026', '08', 'agent-team');
      Directory(sessionsDir).createSync(recursive: true);
      final logPath = p.join(
          sessionsDir, '2026-08-02-d-feedfa-builder.md');
      File(logPath).writeAsStringSync('# log');
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final found = service.getSessionLog('d-feedfa', atReference: anchor);
      expect(found, isNotNull);
      expect(found!.path, logPath);
    });

    test('finds log in previous month', () {
      // Anchor in September, log in August.
      final anchor = DateTime(2026, 9, 5);
      final sessionsDir = p.join(
          aiUsagePath, 'sessions', '2026', '08', 'agent-team');
      Directory(sessionsDir).createSync(recursive: true);
      final logPath = p.join(
          sessionsDir, '2026-08-02-d-feedfa-builder.md');
      File(logPath).writeAsStringSync('# log');
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final found = service.getSessionLog('d-feedfa', atReference: anchor);
      expect(found, isNotNull);
      expect(found!.path, logPath);
    });

    test('handles year boundary (December -> November)', () {
      final anchor = DateTime(2026, 1, 10);
      final sessionsDir = p.join(
          aiUsagePath, 'sessions', '2025', '12', 'agent-team');
      Directory(sessionsDir).createSync(recursive: true);
      final logPath = p.join(
          sessionsDir, '2025-12-31-d-feedfa-builder.md');
      File(logPath).writeAsStringSync('# log');
      final service = SessionService(
          registryPath: registryPath, aiUsagePath: aiUsagePath);
      final found = service.getSessionLog('d-feedfa', atReference: anchor);
      expect(found, isNotNull);
    });
  });
}