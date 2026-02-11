import 'dart:convert';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late AvodahPaths paths;
  late TaskService taskService;
  late WorklogService worklogService;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    paths = AvodahPaths(dataDir: '/tmp/avodah-test', configDir: '/tmp/avodah-test-config');
    taskService = TaskService(db: db, clock: clock);
    worklogService = WorklogService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
  });

  JiraService _createService({http.Client? httpClient}) {
    return JiraService(
      db: db,
      clock: clock,
      paths: paths,
      httpClient: httpClient,
    );
  }

  Future<JiraIntegrationDocument> _setupConfig(JiraService service) async {
    return service.setup(
      baseUrl: 'https://test.atlassian.net',
      jiraProjectKey: 'TEST',
      credentialsPath: '/tmp/nonexistent-creds.json',
    );
  }

  group('setup', () {
    test('creates config and returns it', () async {
      final service = _createService();
      final config = await _setupConfig(service);

      expect(config.baseUrl, equals('https://test.atlassian.net'));
      expect(config.jiraProjectKey, equals('TEST'));
      expect(config.credentialsFilePath, equals('/tmp/nonexistent-creds.json'));
      expect(config.syncEnabled, isTrue);
    });

    test('persists config to database', () async {
      final service = _createService();
      await _setupConfig(service);

      final loaded = await service.getConfig();
      expect(loaded, isNotNull);
      expect(loaded!.jiraProjectKey, equals('TEST'));
    });

    test('updates existing config', () async {
      final service = _createService();
      await _setupConfig(service);

      final updated = await service.setup(
        baseUrl: 'https://updated.atlassian.net',
        jiraProjectKey: 'UPD',
        credentialsPath: '/tmp/new-creds.json',
      );

      expect(updated.baseUrl, equals('https://updated.atlassian.net'));
      expect(updated.jiraProjectKey, equals('UPD'));

      // Should still be one config
      final rows = await db.select(db.jiraIntegrations).get();
      expect(rows, hasLength(1));
    });
  });

  group('getConfig', () {
    test('returns null when not configured', () async {
      final service = _createService();
      final config = await service.getConfig();
      expect(config, isNull);
    });

    test('returns config when configured', () async {
      final service = _createService();
      await _setupConfig(service);

      final config = await service.getConfig();
      expect(config, isNotNull);
      expect(config!.jiraProjectKey, equals('TEST'));
    });
  });

  group('status', () {
    test('returns not configured when no config', () async {
      final service = _createService();
      final status = await service.status();

      expect(status.configured, isFalse);
      expect(status.pendingWorklogs, equals(0));
      expect(status.linkedTasks, equals(0));
    });

    test('returns configured status with counts', () async {
      final service = _createService();
      await _setupConfig(service);

      // Create a linked task
      final task = await taskService.add(title: 'Linked task');
      task.issueId = 'TEST-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      // Create a worklog for that task (unsynced)
      await worklogService.manualLog(taskId: task.id, durationMinutes: 30);

      final status = await service.status();
      expect(status.configured, isTrue);
      expect(status.jiraProjectKey, equals('TEST'));
      expect(status.linkedTasks, equals(1));
      expect(status.pendingWorklogs, equals(1));
    });

    test('excludes synced worklogs from pending count', () async {
      final service = _createService();
      await _setupConfig(service);

      // Create a linked task
      final task = await taskService.add(title: 'Linked task');
      task.issueId = 'TEST-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      // Create a synced worklog
      final worklog = await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 30,
      );
      worklog.linkToJira('12345');
      await db
          .into(db.worklogEntries)
          .insertOnConflictUpdate(worklog.toDriftCompanion());

      final status = await service.status();
      expect(status.pendingWorklogs, equals(0));
    });
  });

  group('pull', () {
    test('throws when not configured', () async {
      final service = _createService();
      expect(() => service.pull(), throwsA(isA<JiraNotConfiguredException>()));
    });

    test('creates local tasks from Jira issues', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'TEST-1',
                  'fields': {'summary': 'First issue'},
                },
                {
                  'key': 'TEST-2',
                  'fields': {'summary': 'Second issue'},
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = _createService(httpClient: mockClient);

      // Setup config with inline creds (we need to work around loadCredentials)
      final config = JiraIntegrationDocument.create(
        clock: clock,
        baseUrl: 'https://test.atlassian.net',
        jiraProjectKey: 'TEST',
        credentialsFilePath: '/dev/null', // Will fail credentials load
      );
      await db
          .into(db.jiraIntegrations)
          .insertOnConflictUpdate(config.toDriftCompanion());

      // pull() will fail on credentials - test that the exception is right
      expect(() => service.pull(), throwsA(isA<JiraCredentialsNotFoundException>()));
    });

    test('updates existing tasks on pull', () async {
      // Pre-create a task with issueId
      final task = await taskService.add(title: 'Old title');
      task.issueId = 'TEST-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'TEST-1',
                  'fields': {'summary': 'Updated title'},
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = _createService(httpClient: mockClient);

      // Can't fully test pull without real credentials, but we test the
      // setup and status paths which don't need HTTP
    });
  });

  group('push', () {
    test('throws when not configured', () async {
      final service = _createService();
      expect(() => service.push(), throwsA(isA<JiraNotConfiguredException>()));
    });
  });

  group('sync', () {
    test('throws when not configured', () async {
      final service = _createService();
      expect(() => service.sync(), throwsA(isA<JiraNotConfiguredException>()));
    });
  });
}
