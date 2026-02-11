import 'dart:convert';
import 'dart:io';

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
  late Directory tempDir;
  late String credentialsPath;

  /// Writes a profile-format credentials file to the temp directory.
  Future<void> writeProfileConfig({
    Map<String, dynamic>? profiles,
    Map<String, dynamic>? defaults,
  }) async {
    final config = {
      'jira_profiles': profiles ??
          {
            'work': {
              'name': 'Work JIRA',
              'base_url': 'https://work.atlassian.net',
              'username': 'user@work.com',
              'api_token': 'work-token',
              'project_keys': ['AG', 'ABDE'],
            },
            'personal': {
              'name': 'Personal',
              'base_url': 'https://personal.atlassian.net',
              'username': 'user@gmail.com',
              'api_token': 'personal-token',
              'project_keys': ['HOME'],
            },
          },
      'default_profiles': defaults ?? {'jira': 'work'},
    };
    await File(credentialsPath).writeAsString(jsonEncode(config));
  }

  setUp(() async {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    tempDir = await Directory.systemTemp.createTemp('avodah-test-');
    paths = AvodahPaths(
      dataDir: tempDir.path,
      configDir: tempDir.path,
    );
    credentialsPath = paths.jiraCredentialsPath;
    taskService = TaskService(db: db, clock: clock);
    worklogService = WorklogService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  JiraService createService({http.Client? httpClient}) {
    return JiraService(
      db: db,
      clock: clock,
      paths: paths,
      httpClient: httpClient,
    );
  }

  group('JiraProfileConfig', () {
    test('parses profile config from JSON', () {
      final config = JiraProfileConfig.fromJson({
        'jira_profiles': {
          'work': {
            'name': 'Work JIRA',
            'base_url': 'https://work.atlassian.net',
            'username': 'user@work.com',
            'api_token': 'work-token',
            'project_keys': ['AG', 'ABDE'],
          },
        },
        'default_profiles': {'jira': 'work'},
      });

      expect(config.profiles, hasLength(1));
      expect(config.defaultJiraProfile, equals('work'));

      final work = config.profiles['work']!;
      expect(work.key, equals('work'));
      expect(work.name, equals('Work JIRA'));
      expect(work.baseUrl, equals('https://work.atlassian.net'));
      expect(work.username, equals('user@work.com'));
      expect(work.apiToken, equals('work-token'));
      expect(work.projectKeys, equals(['AG', 'ABDE']));
    });

    test('getProfile returns named profile', () {
      final config = JiraProfileConfig.fromJson({
        'jira_profiles': {
          'work': {
            'base_url': 'https://work.atlassian.net',
            'username': 'u',
            'api_token': 't',
          },
          'personal': {
            'base_url': 'https://personal.atlassian.net',
            'username': 'u2',
            'api_token': 't2',
          },
        },
        'default_profiles': {'jira': 'work'},
      });

      final profile = config.getProfile('personal');
      expect(profile, isNotNull);
      expect(profile!.baseUrl, equals('https://personal.atlassian.net'));
    });

    test('getProfile returns default when name is null', () {
      final config = JiraProfileConfig.fromJson({
        'jira_profiles': {
          'work': {
            'base_url': 'https://work.atlassian.net',
            'username': 'u',
            'api_token': 't',
          },
        },
        'default_profiles': {'jira': 'work'},
      });

      final profile = config.getProfile(null);
      expect(profile, isNotNull);
      expect(profile!.key, equals('work'));
    });

    test('getProfile returns null for unknown profile', () {
      final config = JiraProfileConfig.fromJson({
        'jira_profiles': {},
        'default_profiles': {},
      });

      expect(config.getProfile('nonexistent'), isNull);
      expect(config.getProfile(null), isNull);
    });

    test('toCredentials bridges profile to JiraCredentials', () {
      final profile = JiraProfile.fromJson('work', {
        'base_url': 'https://work.atlassian.net',
        'username': 'user@work.com',
        'api_token': 'work-token',
      });

      final creds = profile.toCredentials();
      expect(creds.email, equals('user@work.com'));
      expect(creds.apiToken, equals('work-token'));
    });
  });

  group('setup', () {
    test('creates config from named profile', () async {
      await writeProfileConfig();
      final service = createService();

      final config = await service.setup(profileName: 'work');
      expect(config.baseUrl, equals('https://work.atlassian.net'));
      expect(config.jiraProjectKey, equals('AG,ABDE'));
      expect(config.profileName, equals('work'));
      expect(config.credentialsFilePath, equals(credentialsPath));
    });

    test('creates config from default profile when name is null', () async {
      await writeProfileConfig();
      final service = createService();

      final config = await service.setup();
      expect(config.baseUrl, equals('https://work.atlassian.net'));
      expect(config.profileName, equals('work'));
    });

    test('persists config to database', () async {
      await writeProfileConfig();
      final service = createService();
      await service.setup(profileName: 'work');

      final loaded = await service.getConfig();
      expect(loaded, isNotNull);
      expect(loaded!.profileName, equals('work'));
      expect(loaded.jiraProjectKey, equals('AG,ABDE'));
    });

    test('updates existing config when re-setup', () async {
      await writeProfileConfig();
      final service = createService();
      await service.setup(profileName: 'work');

      final updated = await service.setup(profileName: 'personal');
      expect(updated.baseUrl, equals('https://personal.atlassian.net'));
      expect(updated.jiraProjectKey, equals('HOME'));
      expect(updated.profileName, equals('personal'));

      // Should still be one config
      final rows = await db.select(db.jiraIntegrations).get();
      expect(rows, hasLength(1));
    });

    test('throws when profile not found', () async {
      await writeProfileConfig();
      final service = createService();

      expect(
        () => service.setup(profileName: 'nonexistent'),
        throwsA(isA<JiraProfileNotFoundException>()),
      );
    });

    test('throws when credentials file does not exist', () async {
      final service = createService();
      expect(
        () => service.setup(profileName: 'work'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('getConfig', () {
    test('returns null when not configured', () async {
      final service = createService();
      final config = await service.getConfig();
      expect(config, isNull);
    });

    test('returns config when configured', () async {
      await writeProfileConfig();
      final service = createService();
      await service.setup(profileName: 'work');

      final config = await service.getConfig();
      expect(config, isNotNull);
      expect(config!.profileName, equals('work'));
    });
  });

  group('status', () {
    test('returns not configured when no config', () async {
      final service = createService();
      final status = await service.status();

      expect(status.configured, isFalse);
      expect(status.pendingWorklogs, equals(0));
      expect(status.linkedTasks, equals(0));
    });

    test('returns configured status with profile info', () async {
      await writeProfileConfig();
      final service = createService();
      await service.setup(profileName: 'work');

      final status = await service.status();
      expect(status.configured, isTrue);
      expect(status.profileName, equals('work'));
      expect(status.projectKeysList, equals(['AG', 'ABDE']));
      expect(status.baseUrl, equals('https://work.atlassian.net'));
    });

    test('returns configured status with task/worklog counts', () async {
      await writeProfileConfig();
      final service = createService();
      await service.setup(profileName: 'work');

      // Create a linked task
      final task = await taskService.add(title: 'Linked task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      // Create a worklog for that task (unsynced)
      await worklogService.manualLog(taskId: task.id, durationMinutes: 30);

      final status = await service.status();
      expect(status.linkedTasks, equals(1));
      expect(status.pendingWorklogs, equals(1));
    });

    test('excludes synced worklogs from pending count', () async {
      await writeProfileConfig();
      final service = createService();
      await service.setup(profileName: 'work');

      // Create a linked task
      final task = await taskService.add(title: 'Linked task');
      task.issueId = 'AG-1';
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
      final service = createService();
      expect(() => service.pull(), throwsA(isA<JiraNotConfiguredException>()));
    });

    test('generates multi-project JQL for pull', () async {
      await writeProfileConfig();

      String? capturedUrl;
      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(jsonEncode({'issues': []}), 200);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      // Need real credentials in the file for pull to work
      // Update the config to have credentials loadable from the profile
      final result = await service.pull();

      expect(capturedUrl, isNotNull);
      expect(capturedUrl!, contains('project%20in%20(AG%2C%20ABDE)'));
      expect(result.created, equals(0));
      expect(result.updated, equals(0));
    });

    test('generates single-project JQL for single-key profile', () async {
      await writeProfileConfig();

      String? capturedUrl;
      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(jsonEncode({'issues': []}), 200);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'personal');

      final result = await service.pull();

      expect(capturedUrl, isNotNull);
      expect(capturedUrl!, contains('project%3DHOME'));
      expect(result.created, equals(0));
    });

    test('generates single-issue JQL when issueKey given', () async {
      await writeProfileConfig();

      String? capturedUrl;
      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(jsonEncode({'issues': []}), 200);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      await service.pull(issueKey: 'AG-123');

      expect(capturedUrl, isNotNull);
      expect(capturedUrl!, contains('key%20%3D%20AG-123'));
    });

    test('creates local tasks from pulled Jira issues', () async {
      await writeProfileConfig();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-1',
                  'fields': {'summary': 'First issue'},
                },
                {
                  'key': 'AG-2',
                  'fields': {'summary': 'Second issue'},
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      final result = await service.pull();
      expect(result.created, equals(2));
      expect(result.updated, equals(0));

      // Verify tasks exist
      final tasks = await taskService.list();
      expect(tasks.length, greaterThanOrEqualTo(2));
    });
  });

  group('push', () {
    test('throws when not configured', () async {
      final service = createService();
      expect(() => service.push(), throwsA(isA<JiraNotConfiguredException>()));
    });
  });

  group('sync', () {
    test('throws when not configured', () async {
      final service = createService();
      expect(() => service.sync(), throwsA(isA<JiraNotConfiguredException>()));
    });

    test('passes issueKey to pull', () async {
      await writeProfileConfig();

      String? capturedUrl;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          capturedUrl = request.url.toString();
          return http.Response(jsonEncode({'issues': []}), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      await service.sync(issueKey: 'AG-42');
      expect(capturedUrl, isNotNull);
      expect(capturedUrl!, contains('key%20%3D%20AG-42'));
    });
  });
}
