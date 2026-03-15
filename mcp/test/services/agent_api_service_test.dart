/// Integration tests for AgentApiService — sinh-inputs folder interaction.
///
/// Tests cover Phase 7 acceptance criteria (AC1–AC12) and the new endpoints
/// added in phases 1–4 of the sinh-inputs full folder interaction feature.
///
/// Each test group spins up a real HttpServer bound to a random port using
/// a temp directory as aiUsagePath, then makes real HTTP requests and
/// verifies both the HTTP response and filesystem side-effects.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:avodah_mcp/services/agent_api_service.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

class TestServer {
  final HttpServer _server;
  final AgentApiService _service;
  final Directory tmpDir;

  TestServer._(this._server, this._service, this.tmpDir);

  int get port => _server.port;
  String get base => 'http://127.0.0.1:$port';
  String get aiUsagePath => _service.aiUsagePath;

  static Future<TestServer> start() async {
    final tmp = await Directory.systemTemp.createTemp('aat_');
    final service = AgentApiService(
      aiUsagePath: tmp.path,
      registryPath: p.join(tmp.path, 'deployments', 'registry.jsonl'),
    );
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final handled = await service.handleRequest(req);
      if (!handled) {
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found')
          ..close();
      }
    });
    return TestServer._(server, service, tmp);
  }

  Future<void> close() async {
    await _server.close(force: true);
    await tmpDir.delete(recursive: true);
  }

  /// Create a file at `<aiUsagePath>/sinh-inputs/<folder>/<filename>`.
  File createItem(String folder, String filename, String content) {
    final dir = Directory(p.join(aiUsagePath, 'sinh-inputs', folder));
    dir.createSync(recursive: true);
    final file = File(p.join(dir.path, filename));
    file.writeAsStringSync(content);
    return file;
  }

  bool fileExists(String folder, String filename) =>
      File(p.join(aiUsagePath, 'sinh-inputs', folder, filename)).existsSync();

  String readFile(String folder, String filename) =>
      File(p.join(aiUsagePath, 'sinh-inputs', folder, filename))
          .readAsStringSync();
}

Future<HttpClientResponse> get(int port, String path) async {
  final client = HttpClient();
  final req = await client.get('127.0.0.1', port, path);
  return req.close();
}

Future<Map<String, dynamic>> getJson(int port, String path) async {
  final resp = await get(port, path);
  final body = await resp.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<HttpClientResponse> post(
    int port, String path, Map<String, dynamic> body) async {
  final client = HttpClient();
  final req = await client.post('127.0.0.1', port, path);
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(body));
  return req.close();
}

Future<Map<String, dynamic>> postJson(
    int port, String path, Map<String, dynamic> body) async {
  final resp = await post(port, path, body);
  final bodyStr = await resp.transform(utf8.decoder).join();
  return jsonDecode(bodyStr) as Map<String, dynamic>;
}

// ---------------------------------------------------------------------------
// Sample markdown content for tests
// ---------------------------------------------------------------------------

const _approvedItem = '''---
human_feedback:
  action: approved
  by: Sinh
  at: 2026-03-14T10:00:00
---
# Review Request: Approved Feature

> **Date:** 2026-03-14
> **From:** requirements / analyst
> **Type:** review-request

## Content

Feature details here.
''';

const _rejectedItem = '''---
human_feedback:
  action: rejected
  by: Sinh
  at: 2026-03-14T11:00:00
  what_is_wrong: Missing specs
  what_to_fix: Add more detail
  priority: high
---
# Review Request: Rejected Draft

> **Date:** 2026-03-13
> **From:** requirements / analyst
> **Type:** review-request

## Content

Draft without enough detail.

## Human Review

**Action:** rejected
**What's wrong:** Missing specs
**What to fix:** Add more detail
**Priority:** High
''';

const _deferredItem = '''---
human_feedback:
  action: deferred
  by: Sinh
  at: 2026-03-14T09:00:00
  defer_reason: Q2 budget pending
  requeue_after: "2026-04-01"
---
# Review Request: Deferred Spec

> **Date:** 2026-03-12
> **From:** requirements / analyst
> **Type:** review-request

Content.
''';

const _plainItem = '''# Work Report: Builder Phase

> **Date:** 2026-03-10
> **From:** builder / team-manager
> **Type:** work-report

## What Was Done

- Built stuff.
''';

const _ideaItem = '''# Idea: Better logging system

> **Date:** 2026-03-14 08:30
> **Category:** infra
> **Status:** new
> **Effort:** M

## What
Better logging system

## Why
_(not specified)_

## Who
Sinh

## Notes
_(none)_

## Tags
(none yet)
''';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late TestServer ts;

  setUp(() async {
    ts = await TestServer.start();
  });

  tearDown(() async {
    await ts.close();
  });

  // -------------------------------------------------------------------------
  // GET /api/sinh-inputs/:folder — list items
  // -------------------------------------------------------------------------

  group('GET /api/sinh-inputs/:folder — list folder', () {
    test('returns empty list when folder does not exist', () async {
      final resp = await getJson(ts.port, '/api/sinh-inputs/approved');
      expect(resp['folder'], equals('approved'));
      expect(resp['items'], isEmpty);
    });

    test('returns items from folder', () async {
      ts.createItem('approved', '2026-03-14-feature-spec.md', _approvedItem);
      ts.createItem('approved', '2026-03-13-old-spec.md', _plainItem);

      final resp = await getJson(ts.port, '/api/sinh-inputs/approved');
      expect(resp['folder'], equals('approved'));
      final items = resp['items'] as List<dynamic>;
      expect(items, hasLength(2));
    });

    test('items sorted by date descending (newest first)', () async {
      ts.createItem('approved', '2026-03-13-old.md', _plainItem);
      ts.createItem('approved', '2026-03-14-new.md', _approvedItem);

      final resp = await getJson(ts.port, '/api/sinh-inputs/approved');
      final items = resp['items'] as List<dynamic>;
      expect(items.length, equals(2));
      expect(
          (items[0] as Map<String, dynamic>)['date'], equals('2026-03-14'));
      expect(
          (items[1] as Map<String, dynamic>)['date'], equals('2026-03-10'));
    });

    test('items include id, title, type fields', () async {
      ts.createItem('approved', '2026-03-14-feature.md', _approvedItem);

      final resp = await getJson(ts.port, '/api/sinh-inputs/approved');
      final item = (resp['items'] as List<dynamic>)[0] as Map<String, dynamic>;
      expect(item['id'], equals('2026-03-14-feature.md'));
      expect(item['title'], isNotEmpty);
      expect(item['type'], equals('review-request'));
    });

    test('deferred items surface requeue_after at top level', () async {
      ts.createItem('deferred', '2026-03-12-deferred-spec.md', _deferredItem);

      final resp = await getJson(ts.port, '/api/sinh-inputs/deferred');
      final item = (resp['items'] as List<dynamic>)[0] as Map<String, dynamic>;
      expect(item['requeue_after'], equals('2026-04-01'));
    });

    test('other folders do NOT include requeue_after at top level', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      final resp = await getJson(ts.port, '/api/sinh-inputs/approved');
      final item = (resp['items'] as List<dynamic>)[0] as Map<String, dynamic>;
      expect(item.containsKey('requeue_after'), isFalse);
    });

    test('returns 404 for unknown folder', () async {
      final resp = await get(ts.port, '/api/sinh-inputs/unknown');
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });

    test('rejects non-GET methods on folder listing (except ideas POST)', () async {
      final resp =
          await post(ts.port, '/api/sinh-inputs/approved', {'bad': true});
      expect(resp.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });

  // -------------------------------------------------------------------------
  // GET /api/sinh-inputs/done — pagination + search
  // -------------------------------------------------------------------------

  group('GET /api/sinh-inputs/done — pagination and search (F9, F10, NF2)', () {
    test('done folder: empty returns paginated structure', () async {
      final resp = await getJson(ts.port, '/api/sinh-inputs/done');
      expect(resp['folder'], equals('done'));
      expect(resp['items'], isEmpty);
      expect(resp['total'], equals(0));
      expect(resp['hasMore'], isFalse);
    });

    test('done folder: pagination with limit/offset', () async {
      for (var i = 1; i <= 5; i++) {
        ts.createItem('done', '2026-03-${i.toString().padLeft(2, '0')}-item-$i.md',
            '# Item $i\n\n> **Date:** 2026-03-${i.toString().padLeft(2, '0')}\n\nContent.\n');
      }

      final resp1 =
          await getJson(ts.port, '/api/sinh-inputs/done?limit=2&offset=0');
      expect(resp1['items'], hasLength(2));
      expect(resp1['total'], equals(5));
      expect(resp1['hasMore'], isTrue);

      final resp2 =
          await getJson(ts.port, '/api/sinh-inputs/done?limit=2&offset=4');
      expect(resp2['items'], hasLength(1));
      expect(resp2['hasMore'], isFalse);
    });

    test('done folder: search filters by title', () async {
      ts.createItem('done', '2026-03-14-alpha-feature.md',
          '# Alpha Feature\n\n> **Date:** 2026-03-14\n\nContent.\n');
      ts.createItem('done', '2026-03-13-beta-rollout.md',
          '# Beta Rollout\n\n> **Date:** 2026-03-13\n\nContent.\n');

      final resp = await getJson(ts.port, '/api/sinh-inputs/done?q=alpha');
      final items = resp['items'] as List<dynamic>;
      expect(items, hasLength(1));
      expect((items[0] as Map<String, dynamic>)['title'], contains('Alpha'));
    });

    test('done folder: search filters by filename', () async {
      ts.createItem('done', '2026-03-14-migration-report.md',
          '# Report\n\n> **Date:** 2026-03-14\n\nContent.\n');
      ts.createItem('done', '2026-03-13-something-else.md',
          '# Other\n\n> **Date:** 2026-03-13\n\nContent.\n');

      final resp =
          await getJson(ts.port, '/api/sinh-inputs/done?q=migration');
      expect((resp['items'] as List<dynamic>), hasLength(1));
    });

    test('done folder: empty search returns all items', () async {
      ts.createItem('done', '2026-03-14-one.md',
          '# One\n\n> **Date:** 2026-03-14\n\nContent.\n');
      ts.createItem('done', '2026-03-13-two.md',
          '# Two\n\n> **Date:** 2026-03-13\n\nContent.\n');

      final resp = await getJson(ts.port, '/api/sinh-inputs/done?q=');
      expect((resp['items'] as List<dynamic>), hasLength(2));
    });

    test('done folder: default limit is 20', () async {
      // Create 25 items
      for (var i = 1; i <= 25; i++) {
        ts.createItem('done',
            '2026-03-${(i % 28 + 1).toString().padLeft(2, '0')}-item-x$i.md',
            '# Item x$i\n\n> **Date:** 2026-03-${(i % 28 + 1).toString().padLeft(2, '0')}\n\nContent.\n');
      }

      final resp = await getJson(ts.port, '/api/sinh-inputs/done');
      expect((resp['items'] as List<dynamic>).length, lessThanOrEqualTo(20));
      expect(resp['total'], equals(25));
      expect(resp['hasMore'], isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // GET /api/sinh-inputs/:folder/:filename — read single item
  // -------------------------------------------------------------------------

  group('GET /api/sinh-inputs/:folder/:filename — read item', () {
    test('returns item with content', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      final resp =
          await getJson(ts.port, '/api/sinh-inputs/approved/2026-03-14-spec.md');
      expect(resp['id'], equals('2026-03-14-spec.md'));
      expect(resp['folder'], equals('approved'));
      expect(resp['content'], equals(_approvedItem));
    });

    test('returns 404 for missing file', () async {
      final resp =
          await get(ts.port, '/api/sinh-inputs/approved/nonexistent.md');
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 404 for unknown folder', () async {
      final resp =
          await get(ts.port, '/api/sinh-inputs/unknown/file.md');
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 403 for path traversal attempt', () async {
      final resp =
          await get(ts.port, '/api/sinh-inputs/approved/../inbox/secret.md');
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // -------------------------------------------------------------------------
  // POST /api/sinh-inputs/:folder/:filename/requeue — AC3
  // -------------------------------------------------------------------------

  group('POST requeue — move item to inbox (AC3, F12, F13)', () {
    test('moves file from approved to inbox', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      final resp = await postJson(
          ts.port, '/api/sinh-inputs/approved/2026-03-14-spec.md/requeue', {});

      expect(resp['status'], equals('requeued'));
      expect(resp['file'], equals('2026-03-14-spec.md'));
      expect(resp['from'], equals('approved'));
      expect(ts.fileExists('inbox', '2026-03-14-spec.md'), isTrue);
      expect(ts.fileExists('approved', '2026-03-14-spec.md'), isFalse);
    });

    test('adds requeued_from frontmatter key (AC3)', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      await postJson(
          ts.port, '/api/sinh-inputs/approved/2026-03-14-spec.md/requeue', {});

      final content = ts.readFile('inbox', '2026-03-14-spec.md');
      expect(content, contains('requeued_from: approved'));
    });

    test('preserves existing frontmatter on requeue (F13)', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      await postJson(
          ts.port, '/api/sinh-inputs/approved/2026-03-14-spec.md/requeue', {});

      final content = ts.readFile('inbox', '2026-03-14-spec.md');
      expect(content, contains('human_feedback:'));
      expect(content, contains('action: approved'));
      expect(content, contains('requeued_from: approved'));
    });

    test('requeue works on file without existing frontmatter', () async {
      ts.createItem('rejected', '2026-03-10-plain.md', _plainItem);

      await postJson(ts.port,
          '/api/sinh-inputs/rejected/2026-03-10-plain.md/requeue', {});

      final content = ts.readFile('inbox', '2026-03-10-plain.md');
      expect(content, contains('requeued_from: rejected'));
    });

    test('requeue from rejected folder moves to inbox', () async {
      ts.createItem('rejected', '2026-03-13-rejected.md', _rejectedItem);

      await postJson(ts.port,
          '/api/sinh-inputs/rejected/2026-03-13-rejected.md/requeue', {});

      expect(ts.fileExists('inbox', '2026-03-13-rejected.md'), isTrue);
      expect(ts.fileExists('rejected', '2026-03-13-rejected.md'), isFalse);
    });

    test('requeue from deferred folder', () async {
      ts.createItem('deferred', '2026-03-12-deferred.md', _deferredItem);

      await postJson(ts.port,
          '/api/sinh-inputs/deferred/2026-03-12-deferred.md/requeue', {});

      expect(ts.fileExists('inbox', '2026-03-12-deferred.md'), isTrue);
    });

    test('requeue from done folder', () async {
      ts.createItem('done', '2026-03-10-archived.md', _plainItem);

      await postJson(
          ts.port, '/api/sinh-inputs/done/2026-03-10-archived.md/requeue', {});

      expect(ts.fileExists('inbox', '2026-03-10-archived.md'), isTrue);
    });

    test('returns 404 when file does not exist', () async {
      final resp = await post(ts.port,
          '/api/sinh-inputs/approved/nonexistent.md/requeue', {});
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });
  });

  // -------------------------------------------------------------------------
  // POST /api/sinh-inputs/:folder/:filename/archive — F14
  // -------------------------------------------------------------------------

  group('POST archive — move item to done (F14)', () {
    test('moves file from approved to done', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      final resp = await postJson(ts.port,
          '/api/sinh-inputs/approved/2026-03-14-spec.md/archive', {});

      expect(resp['status'], equals('archived'));
      expect(resp['file'], equals('2026-03-14-spec.md'));
      expect(ts.fileExists('done', '2026-03-14-spec.md'), isTrue);
      expect(ts.fileExists('approved', '2026-03-14-spec.md'), isFalse);
    });

    test('moves file from rejected to done', () async {
      ts.createItem('rejected', '2026-03-13-rejected.md', _rejectedItem);

      await postJson(ts.port,
          '/api/sinh-inputs/rejected/2026-03-13-rejected.md/archive', {});

      expect(ts.fileExists('done', '2026-03-13-rejected.md'), isTrue);
    });

    test('moves file from ideas to done', () async {
      ts.createItem('ideas', '2026-03-14-idea.md', _ideaItem);

      await postJson(
          ts.port, '/api/sinh-inputs/ideas/2026-03-14-idea.md/archive', {});

      expect(ts.fileExists('done', '2026-03-14-idea.md'), isTrue);
      expect(ts.fileExists('ideas', '2026-03-14-idea.md'), isFalse);
    });

    test('returns 404 when file not found', () async {
      final resp = await post(
          ts.port, '/api/sinh-inputs/approved/nonexistent.md/archive', {});
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });
  });

  // -------------------------------------------------------------------------
  // POST /api/sinh-inputs/approved/:filename/save-for-later — AC3b, F14b
  // -------------------------------------------------------------------------

  group('POST save-for-later — approved only (AC3b, F14b, F28)', () {
    test('moves approved item to for-later', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      final resp = await postJson(ts.port,
          '/api/sinh-inputs/approved/2026-03-14-spec.md/save-for-later', {});

      expect(resp['status'], equals('saved-for-later'));
      expect(ts.fileExists('for-later', '2026-03-14-spec.md'), isTrue);
      expect(ts.fileExists('approved', '2026-03-14-spec.md'), isFalse);
    });

    test('adds saved_from: approved frontmatter (F28)', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      await postJson(ts.port,
          '/api/sinh-inputs/approved/2026-03-14-spec.md/save-for-later', {});

      final content = ts.readFile('for-later', '2026-03-14-spec.md');
      expect(content, contains('saved_from: approved'));
    });

    test('preserves existing frontmatter content when adding saved_from', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      await postJson(ts.port,
          '/api/sinh-inputs/approved/2026-03-14-spec.md/save-for-later', {});

      final content = ts.readFile('for-later', '2026-03-14-spec.md');
      expect(content, contains('human_feedback:'));
      expect(content, contains('action: approved'));
    });

    test('save-for-later is rejected for non-approved folders', () async {
      ts.createItem('rejected', '2026-03-13-rejected.md', _rejectedItem);

      final resp = await post(ts.port,
          '/api/sinh-inputs/rejected/2026-03-13-rejected.md/save-for-later',
          {});
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 404 when file not found', () async {
      final resp = await post(ts.port,
          '/api/sinh-inputs/approved/nonexistent.md/save-for-later', {});
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });
  });

  // -------------------------------------------------------------------------
  // POST /api/sinh-inputs/ideas — create idea (F17–F23, AC8, AC9)
  // -------------------------------------------------------------------------

  group('POST /api/sinh-inputs/ideas — create idea (AC8, AC9, F17-F23)', () {
    test('creates idea file in ideas/ folder (F23)', () async {
      final resp = await postJson(ts.port, '/api/sinh-inputs/ideas', {
        'title': 'Better logging',
        'category': 'infra',
        'effort': 'M',
        'what': 'Replace print with structured logs',
        'why': 'Easier debugging',
        'who': 'Sinh',
      });

      expect(resp['status'], equals('created'));
      expect(resp['file'], isNotEmpty);

      final filename = resp['file'] as String;
      expect(ts.fileExists('ideas', filename), isTrue);
    });

    test('generated filename matches YYYY-MM-DD-<slug>.md pattern (F19)', () async {
      final resp = await postJson(ts.port, '/api/sinh-inputs/ideas',
          {'title': 'My Great Idea'});

      final filename = resp['file'] as String;
      expect(filename,
          matches(RegExp(r'^\d{4}-\d{2}-\d{2}-my-great-idea\.md$')));
    });

    test('slugify: uppercase → lowercase, spaces → dashes (F19)', () async {
      final resp = await postJson(ts.port, '/api/sinh-inputs/ideas',
          {'title': 'Hello World CAPS'});

      final filename = resp['file'] as String;
      expect(filename, contains('hello-world-caps'));
    });

    test('slugify: special characters removed (F19)', () async {
      final resp = await postJson(ts.port, '/api/sinh-inputs/ideas',
          {'title': 'Add @feature! (urgent)'});

      final filename = resp['file'] as String;
      expect(filename, contains('add-feature-urgent'));
    });

    test('file format matches pa idea CLI output (AC9, F20)', () async {
      await postJson(ts.port, '/api/sinh-inputs/ideas', {
        'title': 'Test Idea',
        'category': 'work',
        'effort': 'S',
        'what': 'Do the thing',
        'why': 'Because reasons',
        'who': 'Sinh',
        'notes': 'Some notes here',
        'tags': ['flutter', 'testing'],
      });

      // Find the created file
      final dir = Directory(
          p.join(ts.aiUsagePath, 'sinh-inputs', 'ideas'));
      final files = dir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));

      final content = files.first.readAsStringSync();
      expect(content, contains('# Idea: Test Idea'));
      expect(content, contains('**Category:** work'));
      expect(content, contains('**Status:** new'));
      expect(content, contains('**Effort:** S'));
      expect(content, contains('## What'));
      expect(content, contains('Do the thing'));
      expect(content, contains('## Why'));
      expect(content, contains('Because reasons'));
      expect(content, contains('## Who'));
      expect(content, contains('Sinh'));
      expect(content, contains('## Notes'));
      expect(content, contains('Some notes here'));
      expect(content, contains('## Tags'));
      expect(content, contains('`flutter`'));
      expect(content, contains('`testing`'));
    });

    test('Status: new written to file but defaults correctly (AC9, F20)', () async {
      await postJson(ts.port, '/api/sinh-inputs/ideas', {'title': 'Status Check'});

      final dir = Directory(p.join(ts.aiUsagePath, 'sinh-inputs', 'ideas'));
      final files = dir.listSync().whereType<File>().toList();
      final content = files.first.readAsStringSync();
      expect(content, contains('**Status:** new'));
    });

    test('tags as space-separated string (F18)', () async {
      await postJson(ts.port, '/api/sinh-inputs/ideas',
          {'title': 'Tag Test', 'tags': 'dart flutter'});

      final dir = Directory(p.join(ts.aiUsagePath, 'sinh-inputs', 'ideas'));
      final files = dir.listSync().whereType<File>().toList();
      final content = files.first.readAsStringSync();
      expect(content, contains('`dart`'));
      expect(content, contains('`flutter`'));
    });

    test('empty tags produces (none yet) (F18)', () async {
      await postJson(ts.port, '/api/sinh-inputs/ideas',
          {'title': 'No Tags'});

      final dir = Directory(p.join(ts.aiUsagePath, 'sinh-inputs', 'ideas'));
      final files = dir.listSync().whereType<File>().toList();
      final content = files.first.readAsStringSync();
      expect(content, contains('(none yet)'));
    });

    test('defaults: category=personal, effort=M, who=Sinh', () async {
      await postJson(ts.port, '/api/sinh-inputs/ideas', {'title': 'Defaults'});

      final dir = Directory(p.join(ts.aiUsagePath, 'sinh-inputs', 'ideas'));
      final files = dir.listSync().whereType<File>().toList();
      final content = files.first.readAsStringSync();
      expect(content, contains('**Category:** personal'));
      expect(content, contains('**Effort:** M'));
      expect(content, contains('Sinh'));
    });

    test('collision: adds counter suffix (F19)', () async {
      // First creation
      final resp1 = await postJson(ts.port, '/api/sinh-inputs/ideas',
          {'title': 'Duplicate Idea'});
      final file1 = resp1['file'] as String;

      // Second creation with same title
      final resp2 = await postJson(ts.port, '/api/sinh-inputs/ideas',
          {'title': 'Duplicate Idea'});
      final file2 = resp2['file'] as String;

      expect(file1, isNot(equals(file2)));
      expect(file2, contains('-2'));
    });

    test('missing title returns 400 (F18)', () async {
      final resp =
          await post(ts.port, '/api/sinh-inputs/ideas', {'category': 'work'});
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });

    test('empty body returns 400', () async {
      final client = HttpClient();
      final req = await client.post('127.0.0.1', ts.port, '/api/sinh-inputs/ideas');
      req.headers.contentType = ContentType.json;
      req.write('');
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });

    test('null/empty title returns 400', () async {
      final resp =
          await post(ts.port, '/api/sinh-inputs/ideas', {'title': ''});
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });
  });

  // -------------------------------------------------------------------------
  // POST /api/sinh-inputs/:folder/:filename/append-section — F21, F22, AC10
  // -------------------------------------------------------------------------

  group('POST append-section — ideas append (F21, F22, AC10)', () {
    test('appends new section to idea file (AC10)', () async {
      ts.createItem('ideas', '2026-03-14-test-idea.md', _ideaItem);

      final resp = await postJson(ts.port,
          '/api/sinh-inputs/ideas/2026-03-14-test-idea.md/append-section', {
        'title': 'Research Notes',
        'content': 'Found some interesting papers on logging.'
      });

      expect(resp['status'], equals('section-appended'));

      final content = ts.readFile('ideas', '2026-03-14-test-idea.md');
      expect(content, contains('### Research Notes'));
      expect(content, contains('Found some interesting papers on logging.'));
    });

    test('section is appended at end of file', () async {
      ts.createItem('ideas', '2026-03-14-test-idea.md', _ideaItem);

      await postJson(ts.port,
          '/api/sinh-inputs/ideas/2026-03-14-test-idea.md/append-section', {
        'title': 'New Section',
        'content': 'Content here.'
      });

      final content = ts.readFile('ideas', '2026-03-14-test-idea.md');
      final ideaIdx = content.indexOf('# Idea:');
      final sectionIdx = content.indexOf('### New Section');
      expect(sectionIdx, greaterThan(ideaIdx));
    });

    test('returns 404 when file not found', () async {
      final resp = await post(ts.port,
          '/api/sinh-inputs/ideas/nonexistent.md/append-section',
          {'title': 'Test', 'content': 'Content'});
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });

    test('append-section also works on non-ideas folders', () async {
      ts.createItem('approved', '2026-03-14-spec.md', _approvedItem);

      final resp = await postJson(ts.port,
          '/api/sinh-inputs/approved/2026-03-14-spec.md/append-section', {
        'title': 'Follow-up',
        'content': 'Additional context.'
      });

      expect(resp['status'], equals('section-appended'));
    });
  });

  // -------------------------------------------------------------------------
  // Security tests — path traversal prevention
  // -------------------------------------------------------------------------

  group('Security — path traversal prevention', () {
    test('requeue rejects path traversal in filename', () async {
      final resp = await post(ts.port,
          '/api/sinh-inputs/approved/../inbox/secret.md/requeue', {});
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('list rejects unknown folder', () async {
      final resp = await get(ts.port, '/api/sinh-inputs/inbox');
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });

    test('empty folder segment returns 400', () async {
      final resp = await get(ts.port, '/api/sinh-inputs/');
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });
  });

  // -------------------------------------------------------------------------
  // Backward compatibility — AC11, AC12
  // -------------------------------------------------------------------------

  group('Backward compatibility — existing endpoints unchanged (AC11, AC12)', () {
    test('GET /api/inbox returns inbox items (AC12)', () async {
      final dir = Directory(
          p.join(ts.aiUsagePath, 'sinh-inputs', 'inbox'));
      dir.createSync(recursive: true);
      File(p.join(dir.path, '2026-03-14-item.md'))
          .writeAsStringSync('# Item\n\n> **Date:** 2026-03-14\n\nContent.\n');

      final resp = await getJson(ts.port, '/api/inbox');
      expect(resp['items'], isNotEmpty);
    });

    test('GET /api/for-later returns for-later items (AC12)', () async {
      final dir = Directory(
          p.join(ts.aiUsagePath, 'sinh-inputs', 'for-later'));
      dir.createSync(recursive: true);
      File(p.join(dir.path, '2026-03-14-saved.md'))
          .writeAsStringSync('# Saved\n\n> **Date:** 2026-03-14\n\nContent.\n');

      final resp = await getJson(ts.port, '/api/for-later');
      expect(resp['items'], isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // _insertFrontmatterKey / _dropFrontmatterKey logic — via HTTP integration
  // -------------------------------------------------------------------------

  group('Frontmatter insertion edge cases (via requeue endpoint)', () {
    test('file without frontmatter gets new block', () async {
      // _plainItem has no YAML frontmatter block
      ts.createItem('approved', '2026-03-10-plain.md', _plainItem);

      await postJson(
          ts.port, '/api/sinh-inputs/approved/2026-03-10-plain.md/requeue', {});

      final content = ts.readFile('inbox', '2026-03-10-plain.md');
      expect(content.startsWith('---\n'), isTrue);
      expect(content, contains('requeued_from: approved'));
    });

    test('existing key is replaced on second requeue', () async {
      // Simulate item already requeued once (has requeued_from in frontmatter)
      const alreadyRequeued = '''---
requeued_from: rejected
---
# Already Requeued

> **Date:** 2026-03-14

Content.
''';
      ts.createItem('approved', '2026-03-14-already.md', alreadyRequeued);

      await postJson(ts.port,
          '/api/sinh-inputs/approved/2026-03-14-already.md/requeue', {});

      final content = ts.readFile('inbox', '2026-03-14-already.md');
      // Should be 'approved' now, not 'rejected'
      expect(content, contains('requeued_from: approved'));
      // Only one occurrence of requeued_from
      expect(
          RegExp(r'requeued_from:').allMatches(content).length, equals(1));
    });
  });
}
