import 'dart:io';

import 'package:avodah/core/crdt/crdt.dart';
import 'package:avodah/features/integrations/models/jira_integration_document.dart';
import 'package:test/test.dart';

void main() {
  group('JiraIntegrationDocument', () {
    late HybridLogicalClock clock;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test-node');
    });

    group('creation', () {
      test('create() generates UUID and sets initial fields', () {
        final integration = JiraIntegrationDocument.create(
          clock: clock,
          baseUrl: 'https://company.atlassian.net',
          jiraProjectKey: 'PROJ',
          credentialsFilePath: '~/.config/avodah/jira-creds.json',
          projectId: 'project-1',
        );

        expect(integration.id, isNotEmpty);
        expect(integration.baseUrl, equals('https://company.atlassian.net'));
        expect(integration.jiraProjectKey, equals('PROJ'));
        expect(integration.credentialsFilePath, equals('~/.config/avodah/jira-creds.json'));
        expect(integration.projectId, equals('project-1'));
        expect(integration.syncEnabled, isTrue);
        expect(integration.syncSubtasks, isTrue);
        expect(integration.syncWorklogs, isFalse);
        expect(integration.syncIntervalMinutes, equals(15));
      });

      test('create() without projectId sets it to null', () {
        final integration = JiraIntegrationDocument.create(
          clock: clock,
          baseUrl: 'https://company.atlassian.net',
          jiraProjectKey: 'PROJ',
          credentialsFilePath: '/path/to/creds.json',
        );

        expect(integration.projectId, isNull);
      });

      test('constructor creates empty document', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        expect(integration.id, equals('jira-1'));
        expect(integration.baseUrl, isEmpty);
        expect(integration.jiraProjectKey, isEmpty);
      });
    });

    group('sync settings', () {
      test('syncEnabled can be toggled', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        integration.syncEnabled = false;
        expect(integration.syncEnabled, isFalse);

        integration.syncEnabled = true;
        expect(integration.syncEnabled, isTrue);
      });

      test('syncSubtasks can be toggled', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        integration.syncSubtasks = false;
        expect(integration.syncSubtasks, isFalse);
      });

      test('syncWorklogs can be toggled', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        integration.syncWorklogs = true;
        expect(integration.syncWorklogs, isTrue);
      });

      test('syncIntervalMinutes can be changed', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        integration.syncIntervalMinutes = 30;
        expect(integration.syncIntervalMinutes, equals(30));
      });

      test('jqlFilter can be set', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        integration.jqlFilter = 'assignee = currentUser()';
        expect(integration.jqlFilter, equals('assignee = currentUser()'));
      });
    });

    group('mappings', () {
      test('fieldMappings default to empty', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        expect(integration.fieldMappings, isEmpty);
      });

      test('fieldMappings can be set', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        integration.fieldMappings = {'summary': 'title', 'description': 'notes'};

        expect(integration.fieldMappings['summary'], equals('title'));
        expect(integration.fieldMappings['description'], equals('notes'));
      });

      test('statusMappings can be set', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        integration.statusMappings = {'Done': 'completed', 'In Progress': 'active'};

        expect(integration.statusMappings['Done'], equals('completed'));
      });
    });

    group('sync status', () {
      test('recordSyncSuccess updates lastSyncAt and clears error', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);
        integration.lastSyncError = 'Previous error';

        integration.recordSyncSuccess();

        expect(integration.lastSyncAt, isNotNull);
        expect(integration.lastSyncError, isNull);
        expect(integration.hasError, isFalse);
      });

      test('recordSyncError sets lastSyncError', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);

        integration.recordSyncError('Connection failed');

        expect(integration.lastSyncError, equals('Connection failed'));
        expect(integration.hasError, isTrue);
      });
    });

    group('URL helpers', () {
      test('issueUrl generates correct URL', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);
        integration.baseUrl = 'https://company.atlassian.net';

        expect(integration.issueUrl('PROJ-123'),
            equals('https://company.atlassian.net/browse/PROJ-123'));
      });

      test('issueUrl handles trailing slash', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);
        integration.baseUrl = 'https://company.atlassian.net/';

        expect(integration.issueUrl('PROJ-123'),
            equals('https://company.atlassian.net/browse/PROJ-123'));
      });

      test('apiUrl returns REST API base', () {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);
        integration.baseUrl = 'https://company.atlassian.net';

        expect(integration.apiUrl,
            equals('https://company.atlassian.net/rest/api/3'));
      });
    });

    group('credentials', () {
      test('credentialsExist returns false for empty path', () async {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);
        integration.credentialsFilePath = '';

        expect(await integration.credentialsExist(), isFalse);
      });

      test('credentialsExist returns false for non-existent file', () async {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);
        integration.credentialsFilePath = '/non/existent/path.json';

        expect(await integration.credentialsExist(), isFalse);
      });

      test('loadCredentials returns null for non-existent file', () async {
        final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);
        integration.credentialsFilePath = '/non/existent/path.json';

        expect(await integration.loadCredentials(), isNull);
      });

      test('loadCredentials reads from file', () async {
        // Create temp file
        final tempDir = Directory.systemTemp.createTempSync('jira_test_');
        final credFile = File('${tempDir.path}/creds.json');
        await credFile.writeAsString('{"email":"test@example.com","apiToken":"secret123"}');

        try {
          final integration = JiraIntegrationDocument(id: 'jira-1', clock: clock);
          integration.credentialsFilePath = credFile.path;

          final creds = await integration.loadCredentials();

          expect(creds, isNotNull);
          expect(creds!.email, equals('test@example.com'));
          expect(creds.apiToken, equals('secret123'));
        } finally {
          await tempDir.delete(recursive: true);
        }
      });
    });

    group('soft delete', () {
      test('delete() marks integration as deleted', () {
        final integration = JiraIntegrationDocument.create(
          clock: clock,
          baseUrl: 'https://company.atlassian.net',
          jiraProjectKey: 'PROJ',
          credentialsFilePath: '/path/to/creds.json',
        );

        expect(integration.isDeleted, isFalse);

        integration.delete();

        expect(integration.isDeleted, isTrue);
      });
    });

    group('toModel', () {
      test('converts to JiraIntegrationModel correctly', () {
        final integration = JiraIntegrationDocument.create(
          clock: clock,
          baseUrl: 'https://company.atlassian.net',
          jiraProjectKey: 'PROJ',
          credentialsFilePath: '/path/to/creds.json',
          projectId: 'project-1',
        );
        integration.recordSyncSuccess();

        final model = integration.toModel();

        expect(model.id, equals(integration.id));
        expect(model.baseUrl, equals('https://company.atlassian.net'));
        expect(model.jiraProjectKey, equals('PROJ'));
        expect(model.projectId, equals('project-1'));
        expect(model.syncEnabled, isTrue);
        expect(model.lastSyncAt, isNotNull);
        expect(model.hasError, isFalse);
        expect(model.displayName, equals('PROJ'));
      });
    });
  });

  group('JiraCredentials', () {
    test('fromJson parses correctly', () {
      final json = {'email': 'user@example.com', 'apiToken': 'token123'};

      final creds = JiraCredentials.fromJson(json);

      expect(creds.email, equals('user@example.com'));
      expect(creds.apiToken, equals('token123'));
    });

    test('basicAuth generates correct header', () {
      final creds = JiraCredentials(
        email: 'user@example.com',
        apiToken: 'token123',
      );

      // Base64 of "user@example.com:token123"
      expect(creds.basicAuth, isNotEmpty);
      expect(creds.basicAuth, contains('dXNlckBleGFtcGxlLmNvbTp0b2tlbjEyMw=='));
    });
  });
}
