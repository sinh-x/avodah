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

    test('re-setup same profile updates existing row', () async {
      await writeProfileConfig();
      final service = createService();
      await service.setup(profileName: 'work');
      await service.setup(profileName: 'work');

      // Same profile → should still be one config row
      final rows = await db.select(db.jiraIntegrations).get();
      expect(rows, hasLength(1));
    });

    test('setup different profiles creates separate rows', () async {
      await writeProfileConfig();
      final service = createService();
      await service.setup(profileName: 'work');
      await service.setup(profileName: 'personal');

      // Different profiles → two config rows
      final rows = await db.select(db.jiraIntegrations).get();
      expect(rows, hasLength(2));
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

      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(jsonEncode({'issues': []}), 200);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      final result = await service.pull();

      expect(capturedBody, isNotNull);
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['jql'], contains('project in (AG, ABDE)'));
      expect(result.created, equals(0));
      expect(result.updated, equals(0));
    });

    test('generates single-project JQL for single-key profile', () async {
      await writeProfileConfig();

      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(jsonEncode({'issues': []}), 200);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'personal');

      final result = await service.pull();

      expect(capturedBody, isNotNull);
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['jql'], contains('project=HOME'));
      expect(result.created, equals(0));
    });

    test('generates single-issue JQL when issueKey given', () async {
      await writeProfileConfig();

      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(jsonEncode({'issues': []}), 200);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      await service.pull(issueKey: 'AG-123');

      expect(capturedBody, isNotNull);
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['jql'], equals('key = AG-123'));
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
        if (request.url.path.contains('/myself')) {
          return http.Response(
            jsonEncode({'accountId': 'user-123'}),
            200,
          );
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(
            jsonEncode({'worklogs': []}),
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
      expect(result.worklogsCreated, equals(0));

      // Verify tasks exist (list excludes done tasks by default)
      final tasks = await taskService.list();
      expect(tasks.length, greaterThanOrEqualTo(2));
    });

    test('pull syncs duedate from Jira to local dueDay', () async {
      await writeProfileConfig();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-1',
                  'fields': {
                    'summary': 'Issue with due date',
                    'duedate': '2026-03-15',
                  },
                },
                {
                  'key': 'AG-2',
                  'fields': {
                    'summary': 'Issue without due date',
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(
            jsonEncode({'accountId': 'user-123'}),
            200,
          );
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(
            jsonEncode({'worklogs': []}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      await service.pull();

      final tasks = await taskService.list();
      final withDue = tasks.firstWhere((t) => t.issueId == 'AG-1');
      final withoutDue = tasks.firstWhere((t) => t.issueId == 'AG-2');
      expect(withDue.dueDay, equals('2026-03-15'));
      expect(withoutDue.dueDay, isNull);
    });

    test('pull updates duedate on existing task', () async {
      await writeProfileConfig();

      // Create an existing task with no due date
      final task = await taskService.add(title: 'Existing task');
      task.issueId = 'AG-5';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-5',
                  'fields': {
                    'summary': 'Existing task',
                    'duedate': '2026-04-01',
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(
            jsonEncode({'accountId': 'user-123'}),
            200,
          );
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(
            jsonEncode({'worklogs': []}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      final result = await service.pull();
      expect(result.updated, equals(1));

      final tasks = await taskService.list();
      final updated = tasks.firstWhere((t) => t.issueId == 'AG-5');
      expect(updated.dueDay, equals('2026-04-01'));
    });

    test('pull marks local task done when Jira issue is done', () async {
      await writeProfileConfig();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-10',
                  'fields': {
                    'summary': 'Done issue',
                    'status': {
                      'name': 'Done',
                      'statusCategory': {'key': 'done'},
                    },
                  },
                },
                {
                  'key': 'AG-11',
                  'fields': {
                    'summary': 'Open issue',
                    'status': {
                      'name': 'In Progress',
                      'statusCategory': {'key': 'indeterminate'},
                    },
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(
            jsonEncode({'accountId': 'user-123'}),
            200,
          );
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(
            jsonEncode({'worklogs': []}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      await service.pull();

      // list() excludes done tasks by default
      final openTasks = await taskService.list();
      expect(openTasks.length, equals(1));
      expect(openTasks.first.title, equals('Open issue'));

      // list with includeCompleted shows the done task
      final allTasks = await taskService.list(includeCompleted: true);
      final doneTasks = allTasks.where((t) => t.isDone).toList();
      expect(doneTasks.length, equals(1));
      expect(doneTasks.first.title, equals('Done issue'));
    });

    test('pull reopens local task when Jira issue is reopened', () async {
      await writeProfileConfig();

      // First pull: issue is done
      var mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-20',
                  'fields': {
                    'summary': 'Reopened issue',
                    'status': {
                      'name': 'Done',
                      'statusCategory': {'key': 'done'},
                    },
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({'worklogs': []}), 200);
        }
        return http.Response('Not found', 404);
      });

      var service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');
      await service.pull();

      // Verify task is done
      var allTasks = await taskService.list(includeCompleted: true);
      var task = allTasks.firstWhere((t) => t.issueId == 'AG-20');
      expect(task.isDone, isTrue);

      // Second pull: issue is reopened
      mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-20',
                  'fields': {
                    'summary': 'Reopened issue',
                    'status': {
                      'name': 'To Do',
                      'statusCategory': {'key': 'new'},
                    },
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({'worklogs': []}), 200);
        }
        return http.Response('Not found', 404);
      });

      service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');
      await service.pull();

      // Verify task is reopened
      allTasks = await taskService.list(includeCompleted: true);
      task = allTasks.firstWhere((t) => t.issueId == 'AG-20');
      expect(task.isDone, isFalse);
    });

    test('pulls worklogs for current user only', () async {
      await writeProfileConfig();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-1',
                  'fields': {'summary': 'Issue with worklogs'},
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(
            jsonEncode({'accountId': 'user-123'}),
            200,
          );
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(
            jsonEncode({
              'worklogs': [
                {
                  'id': '1001',
                  'author': {'accountId': 'user-123'},
                  'timeSpentSeconds': 3600,
                  'started': '2026-02-10T09:00:00.000+0000',
                  'created': '2026-02-10T09:00:00.000+0000',
                  'comment': {
                    'type': 'doc',
                    'content': [
                      {
                        'type': 'paragraph',
                        'content': [
                          {'type': 'text', 'text': 'My worklog'},
                        ],
                      },
                    ],
                  },
                },
                {
                  'id': '1002',
                  'author': {'accountId': 'other-user'},
                  'timeSpentSeconds': 1800,
                  'started': '2026-02-10T10:00:00.000+0000',
                  'created': '2026-02-10T10:00:00.000+0000',
                },
                {
                  'id': '1003',
                  'author': {'accountId': 'user-123'},
                  'timeSpentSeconds': 7200,
                  'started': '2026-02-10T14:00:00.000+0000',
                  'created': '2026-02-10T14:00:00.000+0000',
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
      expect(result.created, equals(1));
      expect(result.worklogsCreated, equals(2)); // only user-123's worklogs

      // Verify worklogs were saved
      final worklogs = await db.select(db.worklogEntries).get();
      expect(worklogs.length, equals(2));

      // Verify jiraWorklogId is set
      for (final w in worklogs) {
        expect(w.jiraWorklogId, isNotNull);
      }
      final jiraIds = worklogs.map((w) => w.jiraWorklogId).toSet();
      expect(jiraIds, containsAll(['1001', '1003']));

      // Verify comment extracted
      final wlWithComment = worklogs.firstWhere((w) => w.jiraWorklogId == '1001');
      expect(wlWithComment.comment, equals('My worklog'));
    });

    test('deduplicates worklogs on second pull', () async {
      await writeProfileConfig();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-1',
                  'fields': {'summary': 'Issue one'},
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(
            jsonEncode({'accountId': 'user-123'}),
            200,
          );
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(
            jsonEncode({
              'worklogs': [
                {
                  'id': '2001',
                  'author': {'accountId': 'user-123'},
                  'timeSpentSeconds': 1800,
                  'started': '2026-02-10T09:00:00.000+0000',
                  'created': '2026-02-10T09:00:00.000+0000',
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

      // First pull
      final result1 = await service.pull();
      expect(result1.worklogsCreated, equals(1));

      // Second pull — same worklog should be skipped
      final result2 = await service.pull();
      expect(result2.worklogsCreated, equals(0));
      expect(result2.updated, equals(1)); // task was updated

      // Still only 1 worklog in DB
      final worklogs = await db.select(db.worklogEntries).get();
      expect(worklogs.length, equals(1));
    });

    test('handles worklog without comment', () async {
      await writeProfileConfig();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search')) {
          return http.Response(
            jsonEncode({
              'issues': [
                {
                  'key': 'AG-1',
                  'fields': {'summary': 'No comment issue'},
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(
            jsonEncode({'accountId': 'user-123'}),
            200,
          );
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(
            jsonEncode({
              'worklogs': [
                {
                  'id': '3001',
                  'author': {'accountId': 'user-123'},
                  'timeSpentSeconds': 900,
                  'started': '2026-02-10T11:00:00.000+0000',
                  'created': '2026-02-10T11:00:00.000+0000',
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
      expect(result.worklogsCreated, equals(1));

      final worklogs = await db.select(db.worklogEntries).get();
      expect(worklogs.first.comment, isNull);
    });
  });

  group('updateWorklog', () {
    test('updates a synced worklog via PUT', () async {
      await writeProfileConfig();

      // Create a linked task + synced worklog
      final task = await taskService.add(title: 'Update worklog task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 60,
        comment: 'Original comment',
      );
      worklog.linkToJira('5001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      String? capturedMethod;
      String? capturedPath;
      String? capturedBody;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/worklog')) {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedBody = request.body;
          return http.Response(jsonEncode({
            'id': '5001',
            'timeSpentSeconds': 3600,
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      final result = await service.updateWorklog(worklog.id);
      expect(result, isTrue);
      expect(capturedMethod, equals('PUT'));
      expect(capturedPath, contains('/issue/AG-1/worklog/5001'));

      // Verify body contains correct fields
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['timeSpentSeconds'], equals(3600));
      expect(body, contains('comment'));
    });

    test('skips worklog not synced to Jira', () async {
      await writeProfileConfig();

      // Create a linked task + unsynced worklog
      final task = await taskService.add(title: 'Unsynced worklog task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 30,
      );

      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      final result = await service.updateWorklog(worklog.id);
      expect(result, isFalse);
      expect(requestMade, isFalse);
    });

    test('returns false on HTTP error', () async {
      await writeProfileConfig();

      final task = await taskService.add(title: 'HTTP error task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 45,
      );
      worklog.linkToJira('6001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/worklog')) {
          return http.Response('Server Error', 500);
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      final result = await service.updateWorklog(worklog.id);
      expect(result, isFalse);
    });

    test('reconciles duration from Jira response', () async {
      await writeProfileConfig();

      final task = await taskService.add(title: 'Reconcile update task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      // 91 minutes = 5460 seconds
      final worklog = await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 91,
      );
      worklog.linkToJira('7001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/worklog')) {
          // Jira rounds to 90 minutes = 5400 seconds
          return http.Response(jsonEncode({
            'id': '7001',
            'timeSpentSeconds': 5400,
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      final result = await service.updateWorklog(worklog.id);
      expect(result, isTrue);

      // Verify duration was reconciled
      final worklogs = await db.select(db.worklogEntries).get();
      final updated = worklogs.firstWhere((w) => w.jiraWorklogId == '7001');
      expect(updated.duration, equals(5400000)); // 5400s * 1000
    });
  });

    test('appends updated filter when updatedSinceDays given', () async {
      await writeProfileConfig();

      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(jsonEncode({'issues': []}), 200);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      await service.pull(updatedSinceDays: 7);

      expect(capturedBody, isNotNull);
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['jql'], contains("updated >= '-7d'"));
      expect(body['jql'], contains('project in (AG, ABDE)'));
    });

    test('ignores updatedSinceDays when issueKey is given', () async {
      await writeProfileConfig();

      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(jsonEncode({'issues': []}), 200);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      await service.pull(issueKey: 'AG-123', updatedSinceDays: 7);

      expect(capturedBody, isNotNull);
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['jql'], equals('key = AG-123'));
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

      String? capturedBody;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          capturedBody = request.body;
          return http.Response(jsonEncode({'issues': []}), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: mockClient);
      await service.setup(profileName: 'work');

      await service.sync(issueKey: 'AG-42');
      expect(capturedBody, isNotNull);
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['jql'], equals('key = AG-42'));
    });
  });

  // ============================================================
  // computeSyncPreview tests
  // ============================================================

  group('computeSyncPreview', () {
    /// Helper: build a mock client for preview tests.
    MockClient buildPreviewClient({
      List<Map<String, dynamic>> issues = const [],
      Map<String, List<Map<String, dynamic>>> worklogsByIssue = const {},
      String accountId = 'user-123',
    }) {
      return MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({'issues': issues}), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': accountId}), 200);
        }
        // Match /issue/{key}/worklog
        final wlMatch = RegExp(r'/issue/([^/]+)/worklog').firstMatch(request.url.path);
        if (wlMatch != null) {
          final key = wlMatch.group(1)!;
          final wls = worklogsByIssue[key] ?? [];
          return http.Response(jsonEncode({'worklogs': wls}), 200);
        }
        return http.Response('Not found', 404);
      });
    }

    test('detects new remote issues', () async {
      await writeProfileConfig();
      final client = buildPreviewClient(issues: [
        {'key': 'AG-1', 'fields': {'summary': 'New issue'}},
        {'key': 'AG-2', 'fields': {'summary': 'Another issue'}},
      ]);
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.newRemoteIssues, hasLength(2));
      expect(ctx.preview.upToDateTasks, equals(0));
    });

    test('detects new local worklogs (unsynced)', () async {
      await writeProfileConfig();

      // Create a linked task + unsynced worklog first
      final task = await taskService.add(title: 'Linked task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());
      await worklogService.manualLog(taskId: task.id, durationMinutes: 30);

      final client = buildPreviewClient(issues: [
        {'key': 'AG-1', 'fields': {'summary': 'Linked task'}},
      ]);
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.newLocalWorklogs, hasLength(1));
      expect(ctx.preview.newRemoteIssues, isEmpty);
      expect(ctx.preview.upToDateTasks, equals(1));
    });

    test('detects new remote worklogs', () async {
      await writeProfileConfig();

      // Create a linked task with no local worklogs
      final task = await taskService.add(title: 'Task with remote worklogs');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final client = buildPreviewClient(
        issues: [
          {'key': 'AG-1', 'fields': {'summary': 'Task with remote worklogs'}},
        ],
        worklogsByIssue: {
          'AG-1': [
            {
              'id': '5001',
              'author': {'accountId': 'user-123'},
              'timeSpentSeconds': 3600,
              'started': '2026-02-10T09:00:00.000+0000',
              'created': '2026-02-10T09:00:00.000+0000',
            },
          ],
        },
      );
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.newRemoteWorklogs, hasLength(1));
      expect(ctx.preview.newRemoteWorklogs.first.jiraWorklogId, equals('5001'));
    });

    test('detects duration mismatch', () async {
      await writeProfileConfig();

      // Create linked task + synced worklog with different duration
      final task = await taskService.add(title: 'Mismatched task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = await worklogService.manualLog(
        taskId: task.id,
        durationMinutes: 90, // 1h 30m = 5400 seconds locally
      );
      worklog.linkToJira('6001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final client = buildPreviewClient(
        issues: [
          {'key': 'AG-1', 'fields': {'summary': 'Mismatched task'}},
        ],
        worklogsByIssue: {
          'AG-1': [
            {
              'id': '6001',
              'author': {'accountId': 'user-123'},
              'timeSpentSeconds': 3600, // 1h — differs from local 1h30m
              'started': '2026-02-10T09:00:00.000+0000',
              'created': '2026-02-10T09:00:00.000+0000',
            },
          ],
        },
      );
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.worklogMismatches, hasLength(1));
      expect(ctx.preview.worklogMismatches.first.durationDiffers, isTrue);
      expect(ctx.preview.worklogMismatches.first.commentDiffers, isFalse);
    });

    test('detects comment mismatch', () async {
      await writeProfileConfig();

      final task = await taskService.add(title: 'Comment task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
        end: DateTime(2026, 2, 10, 10).millisecondsSinceEpoch,
        comment: 'Review PR',
      );
      worklog.linkToJira('7001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final client = buildPreviewClient(
        issues: [
          {'key': 'AG-1', 'fields': {'summary': 'Comment task'}},
        ],
        worklogsByIssue: {
          'AG-1': [
            {
              'id': '7001',
              'author': {'accountId': 'user-123'},
              'timeSpentSeconds': 3600,
              'started': '2026-02-10T09:00:00.000+0000',
              'created': '2026-02-10T09:00:00.000+0000',
              'comment': {
                'type': 'doc',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'Code review'},
                    ],
                  },
                ],
              },
            },
          ],
        },
      );
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.worklogMismatches, hasLength(1));
      expect(ctx.preview.worklogMismatches.first.commentDiffers, isTrue);
      expect(ctx.preview.worklogMismatches.first.durationDiffers, isFalse);
    });

    test('detects start time mismatch', () async {
      await writeProfileConfig();

      final task = await taskService.add(title: 'Start time task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
        end: DateTime(2026, 2, 10, 10).millisecondsSinceEpoch,
      );
      worklog.linkToJira('7501');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final client = buildPreviewClient(
        issues: [
          {'key': 'AG-1', 'fields': {'summary': 'Start time task'}},
        ],
        worklogsByIssue: {
          'AG-1': [
            {
              'id': '7501',
              'author': {'accountId': 'user-123'},
              'timeSpentSeconds': 3600, // same duration
              'started': '2026-02-10T14:00:00.000+0000', // different start
              'created': '2026-02-10T09:00:00.000+0000',
            },
          ],
        },
      );
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.worklogMismatches, hasLength(1));
      expect(ctx.preview.worklogMismatches.first.startTimeDiffers, isTrue);
      expect(ctx.preview.worklogMismatches.first.durationDiffers, isFalse);
      expect(ctx.preview.worklogMismatches.first.commentDiffers, isFalse);
    });

    test('ignores matching start times', () async {
      await writeProfileConfig();

      final task = await taskService.add(title: 'Matching start task');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: DateTime.utc(2026, 2, 10, 9).millisecondsSinceEpoch,
        end: DateTime.utc(2026, 2, 10, 10).millisecondsSinceEpoch,
      );
      worklog.linkToJira('7502');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final client = buildPreviewClient(
        issues: [
          {'key': 'AG-1', 'fields': {'summary': 'Matching start task'}},
        ],
        worklogsByIssue: {
          'AG-1': [
            {
              'id': '7502',
              'author': {'accountId': 'user-123'},
              'timeSpentSeconds': 7200, // different duration
              'started': '2026-02-10T09:00:00.000+0000', // same start
              'created': '2026-02-10T09:00:00.000+0000',
            },
          ],
        },
      );
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.worklogMismatches, hasLength(1));
      expect(ctx.preview.worklogMismatches.first.durationDiffers, isTrue);
      expect(ctx.preview.worklogMismatches.first.startTimeDiffers, isFalse);
    });

    test('detects title mismatch', () async {
      await writeProfileConfig();

      final task = await taskService.add(title: 'Fix bug');
      task.issueId = 'AG-456';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final client = buildPreviewClient(issues: [
        {'key': 'AG-456', 'fields': {'summary': 'Fix authentication bug'}},
      ]);
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.titleMismatches, hasLength(1));
      expect(ctx.preview.titleMismatches.first.remoteTitle, equals('Fix authentication bug'));
      expect(ctx.preview.titleMismatches.first.localTask.title, equals('Fix bug'));
    });

    test('returns empty preview when all in sync', () async {
      await writeProfileConfig();

      final task = await taskService.add(title: 'Up to date');
      task.issueId = 'AG-1';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: DateTime.utc(2026, 2, 10, 9).millisecondsSinceEpoch,
        end: DateTime.utc(2026, 2, 10, 10).millisecondsSinceEpoch,
      );
      worklog.linkToJira('8001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final client = buildPreviewClient(
        issues: [
          {'key': 'AG-1', 'fields': {'summary': 'Up to date'}},
        ],
        worklogsByIssue: {
          'AG-1': [
            {
              'id': '8001',
              'author': {'accountId': 'user-123'},
              'timeSpentSeconds': 3600,
              'started': '2026-02-10T09:00:00.000+0000',
              'created': '2026-02-10T09:00:00.000+0000',
            },
          ],
        },
      );
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.hasChanges, isFalse);
      expect(ctx.preview.hasMismatches, isFalse);
      expect(ctx.preview.upToDateTasks, equals(1));
    });

    test('passes updatedSinceDays filter through to JQL', () async {
      await writeProfileConfig();

      String? capturedJql;
      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          capturedJql = body['jql'] as String?;
          return http.Response(jsonEncode({'issues': []}), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');

      await service.computeSyncPreview(updatedSinceDays: 14);

      expect(capturedJql, isNotNull);
      expect(capturedJql, contains("updated >= '-14d'"));
      expect(capturedJql, contains('project in (AG, ABDE)'));
    });
  });

  // ============================================================
  // executeSyncPlan tests
  // ============================================================

  group('executeSyncPlan', () {
    /// Helper to set up config and return a service with a custom mock client.
    Future<JiraService> setupService(MockClient client) async {
      await writeProfileConfig();
      final service = createService(httpClient: client);
      await service.setup(profileName: 'work');
      return service;
    }

    test('creates tasks for new remote issues', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-10', 'fields': {'summary': 'New task from Jira'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({'worklogs': []}), 200);
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.newRemoteIssues, hasLength(1));

      final result = await service.executeSyncPlan(ctx);
      expect(result.tasksCreated, equals(1));

      final tasks = await taskService.list();
      expect(tasks.any((t) => t.issueId == 'AG-10'), isTrue);
    });

    test('creates tasks with dueDay from executeSyncPlan', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {
                'key': 'AG-15',
                'fields': {
                  'summary': 'Task with due',
                  'duedate': '2026-06-01',
                  'timeoriginalestimate': 7200,
                },
              },
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({'worklogs': []}), 200);
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.newRemoteIssues, hasLength(1));

      final result = await service.executeSyncPlan(ctx);
      expect(result.tasksCreated, equals(1));

      final tasks = await taskService.list();
      final created = tasks.firstWhere((t) => t.issueId == 'AG-15');
      expect(created.dueDay, equals('2026-06-01'));
      expect(created.timeEstimate, equals(7200000));
    });

    test('pushes new local worklogs and reconciles duration', () async {
      // Create linked task + unsynced worklog
      final task = await taskService.add(title: 'Push worklog task');
      task.issueId = 'AG-20';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());
      await worklogService.manualLog(taskId: task.id, durationMinutes: 91); // 91 min = 5460 seconds

      String? capturedMethod;
      String? capturedPath;
      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-20', 'fields': {'summary': 'Push worklog task'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          if (request.method == 'GET') {
            return http.Response(jsonEncode({'worklogs': []}), 200);
          }
          if (request.method == 'POST') {
            capturedMethod = request.method;
            capturedPath = request.url.path;
            // Jira rounds 91 min (5460s) to 5460s (no rounding in this case)
            // Simulate Jira rounding to 90 min (5400s)
            return http.Response(jsonEncode({
              'id': '9001',
              'timeSpentSeconds': 5400,
            }), 201);
          }
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.newLocalWorklogs, hasLength(1));

      final result = await service.executeSyncPlan(ctx);
      expect(result.worklogsPushed, equals(1));
      expect(capturedMethod, equals('POST'));
      expect(capturedPath, contains('/issue/AG-20/worklog'));

      // Verify duration was reconciled
      final worklogs = await db.select(db.worklogEntries).get();
      final pushed = worklogs.firstWhere((w) => w.jiraWorklogId == '9001');
      expect(pushed.duration, equals(5400000)); // 5400s * 1000
    });

    test('pulls new remote worklogs with jiraWorklogId set', () async {
      final task = await taskService.add(title: 'Pull worklog task');
      task.issueId = 'AG-30';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-30', 'fields': {'summary': 'Pull worklog task'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({
            'worklogs': [
              {
                'id': '10001',
                'author': {'accountId': 'user-123'},
                'timeSpentSeconds': 1800,
                'started': '2026-02-10T14:00:00.000+0000',
                'created': '2026-02-10T14:00:00.000+0000',
                'comment': {
                  'type': 'doc',
                  'content': [
                    {
                      'type': 'paragraph',
                      'content': [
                        {'type': 'text', 'text': 'Remote log'},
                      ],
                    },
                  ],
                },
              },
            ],
          }), 200);
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.newRemoteWorklogs, hasLength(1));

      final result = await service.executeSyncPlan(ctx);
      expect(result.worklogsPulled, equals(1));

      final worklogs = await db.select(db.worklogEntries).get();
      expect(worklogs.any((w) => w.jiraWorklogId == '10001'), isTrue);
      final pulled = worklogs.firstWhere((w) => w.jiraWorklogId == '10001');
      expect(pulled.comment, equals('Remote log'));
      expect(pulled.duration, equals(1800000));
    });

    test('pushes worklog mismatch (captures PUT, reconciles)', () async {
      final task = await taskService.add(title: 'Mismatch push task');
      task.issueId = 'AG-40';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
        end: DateTime(2026, 2, 10, 10, 30).millisecondsSinceEpoch,
        comment: 'My comment',
      );
      worklog.linkToJira('11001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      String? capturedMethod;
      String? capturedPath;
      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-40', 'fields': {'summary': 'Mismatch push task'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          if (request.method == 'GET') {
            return http.Response(jsonEncode({
              'worklogs': [
                {
                  'id': '11001',
                  'author': {'accountId': 'user-123'},
                  'timeSpentSeconds': 3600, // 1h — differs from local 1h30m
                  'started': '2026-02-10T09:00:00.000+0000',
                  'created': '2026-02-10T09:00:00.000+0000',
                },
              ],
            }), 200);
          }
          if (request.method == 'PUT') {
            capturedMethod = request.method;
            capturedPath = request.url.path;
            return http.Response(jsonEncode({
              'id': '11001',
              'timeSpentSeconds': 5400, // reconciled
            }), 200);
          }
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.worklogMismatches, hasLength(1));

      // Resolve as push
      ctx.preview.worklogMismatches.first.resolution = SyncDirection.push;

      final result = await service.executeSyncPlan(ctx);
      expect(result.mismatchesPushed, equals(1));
      expect(capturedMethod, equals('PUT'));
      expect(capturedPath, contains('/issue/AG-40/worklog/11001'));
    });

    test('pulls worklog mismatch (updates local duration/comment)', () async {
      final task = await taskService.add(title: 'Mismatch pull task');
      task.issueId = 'AG-50';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
        end: DateTime(2026, 2, 10, 10).millisecondsSinceEpoch,
        comment: 'Old comment',
      );
      worklog.linkToJira('12001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-50', 'fields': {'summary': 'Mismatch pull task'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({
            'worklogs': [
              {
                'id': '12001',
                'author': {'accountId': 'user-123'},
                'timeSpentSeconds': 7200, // 2h — differs from local 1h
                'started': '2026-02-10T09:00:00.000+0000',
                'created': '2026-02-10T09:00:00.000+0000',
                'comment': {
                  'type': 'doc',
                  'content': [
                    {
                      'type': 'paragraph',
                      'content': [
                        {'type': 'text', 'text': 'Updated comment'},
                      ],
                    },
                  ],
                },
              },
            ],
          }), 200);
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.worklogMismatches, hasLength(1));

      ctx.preview.worklogMismatches.first.resolution = SyncDirection.pull;

      final result = await service.executeSyncPlan(ctx);
      expect(result.mismatchesPulled, equals(1));

      final worklogs = await db.select(db.worklogEntries).get();
      final updated = worklogs.firstWhere((w) => w.jiraWorklogId == '12001');
      expect(updated.duration, equals(7200000)); // 2h in ms
      expect(updated.comment, equals('Updated comment'));
    });

    test('pulls start time from remote worklog mismatch', () async {
      final task = await taskService.add(title: 'Start time pull task');
      task.issueId = 'AG-51';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
        end: DateTime(2026, 2, 10, 10).millisecondsSinceEpoch,
      );
      worklog.linkToJira('12101');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-51', 'fields': {'summary': 'Start time pull task'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({
            'worklogs': [
              {
                'id': '12101',
                'author': {'accountId': 'user-123'},
                'timeSpentSeconds': 3600, // same 1h duration
                'started': '2026-02-10T14:00:00.000+0000', // different start
                'created': '2026-02-10T09:00:00.000+0000',
              },
            ],
          }), 200);
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.worklogMismatches, hasLength(1));
      expect(ctx.preview.worklogMismatches.first.startTimeDiffers, isTrue);

      ctx.preview.worklogMismatches.first.resolution = SyncDirection.pull;

      final result = await service.executeSyncPlan(ctx);
      expect(result.mismatchesPulled, equals(1));

      final worklogs = await db.select(db.worklogEntries).get();
      final updated = worklogs.firstWhere((w) => w.jiraWorklogId == '12101');
      final expectedStart = DateTime.parse('2026-02-10T14:00:00.000+0000').millisecondsSinceEpoch;
      expect(updated.start, equals(expectedStart));
      expect(updated.duration, equals(3600000)); // 1h in ms
    });

    test('skips worklog mismatch (no HTTP, no DB change)', () async {
      final task = await taskService.add(title: 'Mismatch skip task');
      task.issueId = 'AG-60';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
        end: DateTime(2026, 2, 10, 10).millisecondsSinceEpoch,
        comment: 'Original',
      );
      worklog.linkToJira('13001');
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      var putCalled = false;
      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-60', 'fields': {'summary': 'Mismatch skip task'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          if (request.method == 'PUT') { putCalled = true; }
          if (request.method == 'GET') {
            return http.Response(jsonEncode({
              'worklogs': [
                {
                  'id': '13001',
                  'author': {'accountId': 'user-123'},
                  'timeSpentSeconds': 7200,
                  'started': '2026-02-10T09:00:00.000+0000',
                  'created': '2026-02-10T09:00:00.000+0000',
                  'comment': {
                    'type': 'doc',
                    'content': [
                      {
                        'type': 'paragraph',
                        'content': [
                          {'type': 'text', 'text': 'Different'},
                        ],
                      },
                    ],
                  },
                },
              ],
            }), 200);
          }
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.worklogMismatches, hasLength(1));

      // Default resolution is skip
      final result = await service.executeSyncPlan(ctx);
      expect(result.mismatchesPushed, equals(0));
      expect(result.mismatchesPulled, equals(0));
      expect(putCalled, isFalse);

      // Verify local data unchanged
      final worklogs = await db.select(db.worklogEntries).get();
      final unchanged = worklogs.firstWhere((w) => w.jiraWorklogId == '13001');
      expect(unchanged.comment, equals('Original'));
      expect(unchanged.duration, equals(3600000));
    });

    test('pushes title mismatch (captures PUT)', () async {
      final task = await taskService.add(title: 'Local title');
      task.issueId = 'AG-70';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      String? capturedMethod;
      String? capturedPath;
      String? capturedBody;
      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-70', 'fields': {'summary': 'Remote title'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({'worklogs': []}), 200);
        }
        // Title update PUT
        if (request.method == 'PUT' && request.url.path.contains('/issue/AG-70') && !request.url.path.contains('/worklog')) {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedBody = request.body;
          return http.Response('', 204);
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.titleMismatches, hasLength(1));

      ctx.preview.titleMismatches.first.resolution = SyncDirection.push;

      final result = await service.executeSyncPlan(ctx);
      expect(result.titlesPushed, equals(1));
      expect(capturedMethod, equals('PUT'));
      expect(capturedPath, contains('/issue/AG-70'));
      final bodyMap = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect((bodyMap['fields'] as Map)['summary'], equals('Local title'));
    });

    test('pulls title mismatch (updates local task title)', () async {
      final task = await taskService.add(title: 'Old title');
      task.issueId = 'AG-80';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-80', 'fields': {'summary': 'New Jira title'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          return http.Response(jsonEncode({'worklogs': []}), 200);
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.titleMismatches, hasLength(1));

      ctx.preview.titleMismatches.first.resolution = SyncDirection.pull;

      final result = await service.executeSyncPlan(ctx);
      expect(result.titlesPulled, equals(1));

      final tasks = await taskService.list();
      final updated = tasks.firstWhere((t) => t.issueId == 'AG-80');
      expect(updated.title, equals('New Jira title'));
    });

    test('duration reconciliation rounds correctly', () async {
      final task = await taskService.add(title: 'Reconcile task');
      task.issueId = 'AG-90';
      task.issueType = IssueType.jira;
      await db.into(db.tasks).insertOnConflictUpdate(task.toDriftCompanion());

      // Create worklog with 5432100ms duration (5432.1 seconds)
      final start = DateTime(2026, 2, 10, 9).millisecondsSinceEpoch;
      final worklog = WorklogDocument.create(
        clock: clock,
        taskId: task.id,
        start: start,
        end: start + 5432100,
      );
      await db.into(db.worklogEntries).insertOnConflictUpdate(worklog.toDriftCompanion());

      final client = MockClient((request) async {
        if (request.url.path.contains('/search/jql')) {
          return http.Response(jsonEncode({
            'issues': [
              {'key': 'AG-90', 'fields': {'summary': 'Reconcile task'}},
            ],
          }), 200);
        }
        if (request.url.path.contains('/myself')) {
          return http.Response(jsonEncode({'accountId': 'user-123'}), 200);
        }
        if (request.url.path.contains('/worklog')) {
          if (request.method == 'GET') {
            return http.Response(jsonEncode({'worklogs': []}), 200);
          }
          if (request.method == 'POST') {
            // Jira rounds to 5432 seconds (truncates sub-second)
            return http.Response(jsonEncode({
              'id': '14001',
              'timeSpentSeconds': 5432,
            }), 201);
          }
        }
        return http.Response('Not found', 404);
      });
      final service = await setupService(client);

      final ctx = await service.computeSyncPreview();
      expect(ctx.preview.newLocalWorklogs, hasLength(1));

      final result = await service.executeSyncPlan(ctx);
      expect(result.worklogsPushed, equals(1));

      // Verify reconciliation: 5432100ms → 5432000ms
      final worklogs = await db.select(db.worklogEntries).get();
      final reconciled = worklogs.firstWhere((w) => w.jiraWorklogId == '14001');
      expect(reconciled.duration, equals(5432000)); // 5432 * 1000
    });
  });
}
