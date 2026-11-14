import 'dart:convert';
import 'dart:io';
import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  for (final mode in [
    'disabled',
    'enabled',
    'empty-credentials',
    'missing-credentials',
    'upstream-error'
  ]) {
    test('synthetic worklog gate: $mode; no real Jira client', () async {
      final dir = await Directory.systemTemp.createTemp('avo-jira-gate-');
      final paths = AvodahPaths(configDir: dir.path, dataDir: dir.path);
      final db = openMemoryDatabase();
      final clock = HybridLogicalClock(nodeId: 'fixture-server');
      var posts = 0;
      final jira = JiraService(
          db: db,
          clock: clock,
          paths: paths,
          httpClient: MockClient((r) async {
            expect(r.url.host, 'jira.invalid');
            expect(r.headers['authorization'], isNotNull);
            if (r.method == 'POST') {
              posts++;
              return http.Response('{"id":"synthetic-jira-worklog"}',
                  mode == 'upstream-error' ? 503 : 201);
            }
            return http.Response('{}', 200);
          }));
      try {
        await File(paths.jiraCredentialsPath).writeAsString(jsonEncode({
          'jira_profiles': {
            'fixture': {
              'base_url': 'https://jira.invalid',
              'username': 'synthetic',
              'api_token': mode == 'empty-credentials' ? '' : 'synthetic-token'
            }
          },
          'default_profiles': {'jira': 'fixture'}
        }));
        await jira.setup();
        if (mode == 'missing-credentials')
          await File(paths.jiraCredentialsPath).delete();
        final task = TaskDocument.create(clock: clock, title: 'synthetic')
          ..issueId = 'FIX-1';
        await db.into(db.tasks).insert(task.toDriftCompanion());
        final log = WorklogDocument.create(
            clock: clock,
            taskId: task.id,
            start: 1700000000000,
            end: 1700000060000);
        final delta = {...log.toJson(), 'type': 'worklog'};
        final sync = SyncApiService(
            db: db,
            clock: clock,
            jiraService: mode == 'disabled' ? null : jira);
        final result = await sync
            .mergePushBatch(remoteNode: 'fixture-phone', deltas: [delta]);
        expect(result.errors, isEmpty);
        await sync.pendingJiraPush;
        expect(posts, mode == 'enabled' || mode == 'upstream-error' ? 1 : 0);
        if (mode == 'enabled') {
          await Future.wait([
            sync.mergePushBatch(remoteNode: 'fixture-phone', deltas: [delta]),
            sync.mergePushBatch(remoteNode: 'fixture-phone', deltas: [delta]),
          ]);
          await sync.pendingJiraPush;
          expect(posts, 1,
              reason:
                  'replay/concurrent push must not duplicate acknowledged worklogs');
        }
        expect(await db.select(db.worklogEntries).get(), hasLength(1));
      } finally {
        jira.close();
        await db.close();
        await dir.delete(recursive: true);
      }
    });
  }
}
