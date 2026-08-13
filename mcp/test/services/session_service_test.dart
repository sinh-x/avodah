import 'dart:convert';
import 'dart:io';

import 'package:avodah_mcp/services/session_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmpDir;
  late String aiUsagePath;
  late String registryPath;

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

  SessionService buildService({
    http.Client? httpClient,
  }) {
    return SessionService(
      apiBaseUrl: 'http://localhost:9848',
      aiUsagePath: aiUsagePath,
      registryPath: registryPath,
      httpClient: httpClient,
    );
  }

  group('listSessions', () {
    test('returns empty when API returns empty array', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/sessions');
        return http.Response('[]', 200);
      });
      final service = buildService(httpClient: client);
      expect(await service.listSessions(), isEmpty);
    });

    test('parses SessionRecord array from API', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode([
          {
            'id': 's1-abc',
            'deploymentId': 'd-aaaaaa',
            'model': 'ollama-cloud/deepseek-v4-pro',
            'status': 'running',
            'startedAt': '2026-08-13T04:00:00Z',
          },
          {
            'id': 's2-def',
            'deploymentId': 'd-bbbbbb',
            'model': 'minimax/abacus',
            'status': 'stopping',
            'startedAt': '2026-08-13T03:00:00Z',
          },
        ]), 200);
      });
      final service = buildService(httpClient: client);
      final sessions = await service.listSessions();
      expect(sessions, hasLength(2));
      expect(sessions[0].sessionId, 's1-abc');
      expect(sessions[0].deploymentId, 'd-aaaaaa');
      expect(sessions[0].model, 'ollama-cloud/deepseek-v4-pro');
      expect(sessions[0].status, 'running');
      expect(sessions[1].sessionId, 's2-def');
      expect(sessions[1].status, 'stopping');
    });

    test('handles {"sessions": [...]} wrapped response', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({
          'sessions': [
            {
              'id': 's1',
              'deploymentId': 'd-aaaaaa',
              'model': 'm',
              'status': 'running',
              'startedAt': '2026-08-13T04:00:00Z',
            }
          ]
        }), 200);
      });
      final service = buildService(httpClient: client);
      final sessions = await service.listSessions();
      expect(sessions, hasLength(1));
      expect(sessions.single.sessionId, 's1');
    });

    test('throws on non-200 response', () async {
      final client = MockClient((request) async {
        return http.Response('{"error":"down"}', 500);
      });
      final service = buildService(httpClient: client);
      expect(() async => await service.listSessions(), throwsException);
    });

    test('throws PaPlatformUnavailableException on network error', () async {
      final client = MockClient((request) async {
        throw const SocketException('connection refused');
      });
      final service = buildService(httpClient: client);
      expect(
        () async => await service.listSessions(),
        throwsA(isA<PaPlatformUnavailableException>()),
      );
    });
  });

  group('checkHealth', () {
    test('returns true when API reports ok', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/health');
        return http.Response('{"status":"ok"}', 200);
      });
      final service = buildService(httpClient: client);
      expect(await service.checkHealth(), isTrue);
    });

    test('returns false on non-200 response', () async {
      final client = MockClient((request) async {
        return http.Response('{"error":"down"}', 503);
      });
      final service = buildService(httpClient: client);
      expect(await service.checkHealth(), isFalse);
    });

    test('returns false on network error', () async {
      final client = MockClient((request) async {
        throw const SocketException('connection refused');
      });
      final service = buildService(httpClient: client);
      expect(await service.checkHealth(), isFalse);
    });
  });

  group('startSession', () {
    test('returns deployment id on success', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/deploy');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['team'], 'builder');
        expect(body['mode'], 'implement');
        return http.Response(
            jsonEncode({
              'team': 'builder',
              'mode': 'implement',
              'status': 'pending',
              'deployment_id': 'd-abcdef',
            }),
            202);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isTrue);
      expect(r.deploymentId, 'd-abcdef');
      expect(r.status, 'pending');
    });

    test('returns failure when status is failed', () async {
      final client = MockClient((request) async {
        return http.Response(
            jsonEncode({
              'status': 'failed',
              'reason': 'bad team',
              'team': 'nope',
              'mode': null,
            }),
            202);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('nope', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.deploymentId, isEmpty);
      expect(r.error, 'bad team');
    });

    test('returns failure when deployment_id missing', () async {
      final client = MockClient((request) async {
        return http.Response(
            jsonEncode({'status': 'pending', 'team': 'builder'}),
            202);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.error, isNotNull);
    });

    test('returns failure on network error', () async {
      final client = MockClient((request) async {
        throw const SocketException('connection refused');
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.error, contains('pa-platform is not running'));
    });

    test('returns failed on non-JSON 500 response body (AC9)', () async {
      final client = MockClient((request) async {
        return http.Response('<html>500 Internal Server Error</html>', 500);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.status, 'failed');
      expect(r.deploymentId, isEmpty);
      // Error should mention HTTP status; no stack trace surfaced.
      expect(r.error, contains('HTTP 500'));
    });

    test('returns failed on non-JSON 500 body with JSON error', () async {
      final client = MockClient((request) async {
        return http.Response(
            jsonEncode({'error': 'deploy service crashed'}), 500);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.status, 'failed');
      expect(r.error, 'deploy service crashed');
    });

    test('returns failed on empty 200 body (non-JSON)', () async {
      final client = MockClient((request) async {
        return http.Response('', 200);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.status, 'failed');
      expect(r.deploymentId, isEmpty);
      expect(r.error, contains('non-JSON'));
    });

    test('returns failed on non-JSON 200 body', () async {
      final client = MockClient((request) async {
        return http.Response('not json at all', 200);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.status, 'failed');
      expect(r.error, contains('non-JSON'));
    });

    test('returns failed on JSON array 200 body (wrong shape)', () async {
      final client = MockClient((request) async {
        return http.Response('[1, 2, 3]', 200);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isFalse);
      expect(r.status, 'failed');
      expect(r.error, contains('non-JSON'));
    });

    test('forwards extraArgs --ticket and --objective into body', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
            jsonEncode({
              'status': 'pending',
              'deployment_id': 'd-feedfa',
              'team': 'builder',
              'mode': 'analyze',
            }),
            202);
      });
      final service = buildService(httpClient: client);
      await service.startSession('builder', 'analyze',
          extraArgs: ['--ticket', 'AVO-1', '--objective', 'do thing']);
      expect(capturedBody, isNotNull);
      expect(capturedBody!['team'], 'builder');
      expect(capturedBody!['mode'], 'analyze');
      expect(capturedBody!['ticket'], 'AVO-1');
      expect(capturedBody!['objective'], 'do thing');
    });

    test('forwards --repo and --provider into body', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
            jsonEncode({
              'status': 'pending',
              'deployment_id': 'd-feedfa',
              'team': 'builder',
              'mode': 'analyze',
            }),
            202);
      });
      final service = buildService(httpClient: client);
      await service.startSession('builder', 'analyze',
          extraArgs: ['--repo', 'avodah', '--provider', 'minimax']);
      expect(capturedBody!['repo'], 'avodah');
      expect(capturedBody!['provider'], 'minimax');
    });
  });

  group('extractDeploymentId (key normalization helper — Mn2/AC15)', () {
    test('reads snake_case deployment_id (canonical key)', () {
      expect(SessionService.extractDeploymentId(
          {'deployment_id': 'd-abcdef', 'status': 'pending'}),
          'd-abcdef');
    });

    test('falls back to camelCase deploymentId', () {
      expect(SessionService.extractDeploymentId(
          {'deploymentId': 'd-abcdef', 'status': 'pending'}),
          'd-abcdef');
    });

    test('returns empty string when neither key present', () {
      expect(SessionService.extractDeploymentId({'status': 'pending'}),
          '');
    });

    test('returns empty string when value is not a string', () {
      expect(SessionService.extractDeploymentId({'deployment_id': 123}),
          '');
    });

    test('returns empty string when value is empty', () {
      expect(SessionService.extractDeploymentId({'deployment_id': ''}),
          '');
    });

    test('prefers snake_case over camelCase', () {
      expect(SessionService.extractDeploymentId(
          {'deployment_id': 'd-snake', 'deploymentId': 'd-camel'}),
          'd-snake');
    });

    test('startSession succeeds with camelCase deploymentId key', () async {
      final client = MockClient((request) async {
        return http.Response(
            jsonEncode({
              'status': 'pending',
              'deploymentId': 'd-camel123',
              'team': 'builder',
              'mode': 'implement',
            }),
            202);
      });
      final service = buildService(httpClient: client);
      final r = await service.startSession('builder', 'implement');
      expect(r.succeeded, isTrue);
      expect(r.deploymentId, 'd-camel123');
    });
  });

  group('SessionSummary.fromJson key normalization (Mn3/AC15)', () {
    test('reads camelCase deploymentId (canonical key)', () {
      final s = SessionSummary.fromJson({
        'id': 's1',
        'deploymentId': 'd-abcdef',
        'model': 'm',
        'status': 'running',
        'startedAt': '2026-08-13T04:00:00Z',
      });
      expect(s.deploymentId, 'd-abcdef');
    });

    test('falls back to snake_case deployment_id', () {
      final s = SessionSummary.fromJson({
        'id': 's1',
        'deployment_id': 'd-snake123',
        'model': 'm',
        'status': 'running',
        'startedAt': '2026-08-13T04:00:00Z',
      });
      expect(s.deploymentId, 'd-snake123');
    });

    test('prefers snake_case over camelCase (matches extractDeploymentId)', () {
      final s = SessionSummary.fromJson({
        'id': 's1',
        'deployment_id': 'd-snake',
        'deploymentId': 'd-camel',
        'model': 'm',
        'status': 'running',
        'startedAt': '2026-08-13T04:00:00Z',
      });
      expect(s.deploymentId, 'd-snake');
    });

    test('returns empty string when neither key present', () {
      final s = SessionSummary.fromJson({
        'id': 's1',
        'model': 'm',
        'status': 'running',
        'startedAt': '',
      });
      expect(s.deploymentId, '');
    });
  });

  group('stopSession', () {
    test('stops directly when id is a session id', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/sessions') {
          return http.Response('[]', 200);
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/api/sessions/s1-abc/stop');
        return http.Response('{"status":"stopped"}', 200);
      });
      final service = buildService(httpClient: client);
      final r = await service.stopSession('s1-abc');
      expect(r.stopped, isTrue);
    });

    test('resolves deployment id to session id via listSessions', () async {
      var stopCalled = false;
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
        // First stop attempt (direct by deployment id) returns 404.
        if (request.url.path == '/api/sessions/d-aaaaaa/stop') {
          return http.Response('{"error":"Session not found"}', 404);
        }
        // Second stop attempt (by resolved session id) succeeds.
        expect(request.url.path, '/api/sessions/s1-abc/stop');
        stopCalled = true;
        return http.Response('{"status":"stopped"}', 200);
      });
      final service = buildService(httpClient: client);
      final r = await service.stopSession('d-aaaaaa');
      expect(r.stopped, isTrue);
      expect(stopCalled, isTrue);
    });

    test('returns false when session not found', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/sessions') {
          return http.Response('[]', 200);
        }
        // Direct stop attempt returns 404.
        return http.Response('{"error":"Session not found"}', 404);
      });
      final service = buildService(httpClient: client);
      final r = await service.stopSession('d-zzzzzz');
      expect(r.stopped, isFalse);
      expect(r.error, isNotNull);
    });

    test('returns false on network error', () async {
      final client = MockClient((request) async {
        throw const SocketException('connection refused');
      });
      final service = buildService(httpClient: client);
      final r = await service.stopSession('d-zzzzzz');
      expect(r.stopped, isFalse);
      expect(r.error, contains('pa-platform is not running'));
    });
  });

  group('findSession', () {
    test('returns null for unknown deployment id', () async {
      final client = MockClient((request) async {
        return http.Response('[]', 200);
      });
      final service = buildService(httpClient: client);
      expect(await service.findSession('d-zzzzzz'), isNull);
    });

    test('returns handle with activity log path under deployments dir',
        () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode([
          {
            'id': 's1-abc',
            'deploymentId': 'd-aaaaaa',
            'model': 'm',
            'status': 'running',
            'startedAt': '2026-08-13T04:00:00Z',
          }
        ]), 200);
      });
      final service = buildService(httpClient: client);
      final handle = await service.findSession('d-aaaaaa');
      expect(handle, isNotNull);
      expect(handle!.sessionId, 's1-abc');
      expect(handle.status, 'running');
      expect(handle.activityLogPath,
          p.join(aiUsagePath, 'deployments', 'd-aaaaaa', 'activity.jsonl'));
    });
  });

  group('getSessionLog', () {
    test('returns null when no log exists for deployment id', () {
      final service = buildService();
      expect(
          service.getSessionLog('d-zzzzzz', atReference: DateTime(2026, 8, 2)),
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
      final service = buildService();
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
      final service = buildService();
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
      final service = buildService();
      final found = service.getSessionLog('d-feedfa', atReference: anchor);
      expect(found, isNotNull);
    });
  });
}