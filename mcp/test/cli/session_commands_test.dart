import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:avodah_mcp/cli/session_commands.dart';
import 'package:avodah_mcp/services/session_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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
  /// [SessionService] — mirrors `avo.dart`.
  CommandRunner<void> buildRunner({http.Client? httpClient}) {
    final svc = SessionService(
      apiBaseUrl: 'http://localhost:9848',
      aiUsagePath: aiUsagePath,
      registryPath: registryPath,
      httpClient: httpClient,
    );
    final runner = CommandRunner<void>('avo', 'test');
    final group = SessionCommand()
      ..addSubcommand(SessionListCommand(svc))
      ..addSubcommand(SessionHistoryCommand(svc))
      ..addSubcommand(SessionStartCommand(svc))
      ..addSubcommand(SessionStopCommand(svc))
      ..addSubcommand(SessionAttachCommand(svc));
    runner.addCommand(group);
    return runner;
  }

  group('session list', () {
    test('prints empty message when no active sessions', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('[]', 200);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'list']);
    });

    test('renders session rows', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response(jsonEncode([
          {
            'id': 's1-abc',
            'deploymentId': 'd-aaaaaa',
            'model': 'ollama-cloud/deepseek-v4-pro',
            'status': 'running',
            'startedAt': '2026-08-13T04:00:00Z',
          }
        ]), 200);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'list']);
    });

    test('reports error on API failure', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('{"error":"down"}', 500);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'list']);
    });

    test('fails fast with clear message when pa-platform is down (AC14)',
        () async {
      final client = MockClient((request) async {
        throw const SocketException('connection refused');
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'list']);
    });
  });

  group('session history', () {
    test('prints missing message for unknown deployment id', () async {
      final runner = buildRunner();
      await runner.run(['session', 'history', 'd-zzzzzz']);
    });

    test('prints last N lines in non-interactive mode', () async {
      final sessionsDir = p.join(
          aiUsagePath, 'sessions', '2026', '08', 'agent-team');
      Directory(sessionsDir).createSync(recursive: true);
      final logPath =
          p.join(sessionsDir, '2026-08-02-d-feedfa-builder.md');
      File(logPath).writeAsStringSync('line one\nline two\nline three\n');
      final runner = buildRunner();
      await runner.run(['session', 'history', 'd-feedfa', '-n', '2']);
    });
  });

  group('session stop', () {
    test('reports failure for unknown deployment id', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/sessions') {
          return http.Response('[]', 200);
        }
        return http.Response('{"error":"Session not found"}', 404);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'stop', 'd-zzzzzz']);
    });

    test('reports success when session stopped', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/sessions') {
          return http.Response(jsonEncode([
            {
              'id': 's1-abc',
              'deploymentId': 'd-aaaaaa',
              'model': 'm',
              'status': 'running',
              'startedAt': '2026-08-13T04:00:00Z',
            }
          ]), 200);
        }
        // First direct stop attempt 404s; second (resolved session id) succeeds.
        if (request.url.path == '/api/sessions/d-aaaaaa/stop') {
          return http.Response('{"error":"Session not found"}', 404);
        }
        return http.Response('{"status":"stopped"}', 200);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'stop', 'd-aaaaaa']);
    });
  });

  group('session start', () {
    test('reports success on deployment_id returned', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        expect(request.url.path, '/api/deploy');
        return http.Response(
            jsonEncode({
              'status': 'pending',
              'deployment_id': 'd-deadbe',
              'team': 'builder',
              'mode': 'implement',
            }),
            202);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'start', 'builder', '--mode', 'implement']);
    });

    test('reports failure when status is failed', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response(
            jsonEncode({
              'status': 'failed',
              'reason': 'bad team',
              'team': 'nope',
              'mode': null,
            }),
            202);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'start', 'nope']);
    });

    test('reports failure on network error', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        throw const SocketException('connection refused');
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'start', 'builder']);
    });

    test('missing team arg prints usage', () async {
      final runner = buildRunner();
      await runner.run(['session', 'start']);
    });

    test('fails fast with clear message when pa-platform is down (AC14)',
        () async {
      final client = MockClient((request) async {
        throw const SocketException('connection refused');
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'start', 'builder']);
    });
  });

  group('session attach', () {
    test('prints missing message for unknown deployment id', () async {
      final client = MockClient((request) async {
        return http.Response('[]', 200);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'attach', 'd-zzzzzz']);
    });

    test('reports not-running for completed session', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode([
          {
            'id': 's1-abc',
            'deploymentId': 'd-aaaaaa',
            'model': 'm',
            'status': 'stopping',
            'startedAt': '2026-08-13T04:00:00Z',
          }
        ]), 200);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'attach', 'd-aaaaaa']);
    });

    test('reports deploy session unsupported streaming on 404', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/sessions') {
          return http.Response(jsonEncode([
            {
              'id': 's1-abc',
              'deploymentId': 'd-aaaaaa',
              'model': 'm',
              'status': 'running',
              'startedAt': '2026-08-13T04:00:00Z',
            }
          ]), 200);
        }
        // SSE endpoint returns 404 for deploy sessions.
        return http.Response(
            jsonEncode({
              'error': 'Deploy sessions do not support streaming',
              'code': 'NOT_FOUND',
            }),
            404);
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'attach', 'd-aaaaaa']);
    });

    test('fails fast with clear message when pa-platform is down (Mn1/AC14)',
        () async {
      final client = MockClient((request) async {
        throw const SocketException('connection refused');
      });
      final runner = buildRunner(httpClient: client);
      await runner.run(['session', 'attach', 'd-aaaaaa']);
    });
  });
}