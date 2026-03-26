/// Tests for AvoConfig categoryChips and the /api/config/category-chips endpoint.
library;

import 'dart:convert';
import 'dart:io';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/avo_config.dart';
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/sync_api_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  group('AvoConfig categoryChips', () {
    test('fromJson parses categoryChips correctly', () {
      final json = {
        'categories': ['Working', 'Learning'],
        'sync': {'port': 9847, 'intervalSeconds': 30},
        'categoryChips': {
          'Working': ['standup', 'code review', 'debugging'],
          'Learning': ['reading', 'course'],
        },
      };

      final config = AvoConfig.fromJson(json);

      expect(config.categories, equals(['Working', 'Learning']));
      expect(config.syncPort, equals(9847));
      expect(config.syncInterval, equals(30));
      expect(config.categoryChips, hasLength(2));
      expect(config.categoryChips['Working'], equals(['standup', 'code review', 'debugging']));
      expect(config.categoryChips['Learning'], equals(['reading', 'course']));
    });

    test('toJson serializes categoryChips correctly', () {
      const config = AvoConfig(
        categories: ['Working'],
        syncPort: 9847,
        syncInterval: 30,
        categoryChips: {
          'Working': ['standup', 'debugging'],
        },
      );

      final json = config.toJson();

      expect(json['categories'], equals(['Working']));
      expect(json['sync'], equals({'port': 9847, 'intervalSeconds': 30}));
      expect(json['categoryChips'], equals({'Working': ['standup', 'debugging']}));
    });

    test('load/save round-trip preserves categoryChips', () async {
      // Create a temp directory for the config
      final tmp = await Directory.systemTemp.createTemp('avo_config_test_');
      final paths = AvodahPaths(configDir: tmp.path);

      final originalConfig = AvoConfig(
        categories: ['Working', 'Learning'],
        syncPort: 9848,
        syncInterval: 60,
        categoryChips: {
          'Working': ['standup', 'code review', 'debugging'],
          'Learning': ['reading', 'course', 'practice'],
        },
      );

      // Save the config
      await originalConfig.save(paths);

      // Load the config
      final loadedConfig = await AvoConfig.load(paths);

      expect(loadedConfig.categories, equals(['Working', 'Learning']));
      expect(loadedConfig.syncPort, equals(9848));
      expect(loadedConfig.syncInterval, equals(60));
      expect(loadedConfig.categoryChips, equals({
        'Working': ['standup', 'code review', 'debugging'],
        'Learning': ['reading', 'course', 'practice'],
      }));

      // Cleanup
      await tmp.delete(recursive: true);
    });

    test('load returns default config when file does not exist', () async {
      final tmp = await Directory.systemTemp.createTemp('avo_config_test_');
      final paths = AvodahPaths(configDir: tmp.path);

      final config = await AvoConfig.load(paths);

      expect(config.categories, isEmpty);
      expect(config.categoryChips, isEmpty);
      expect(config.effectiveCategories, equals(AvoConfig.defaultCategories));

      // Cleanup
      await tmp.delete(recursive: true);
    });

    test('load handles malformed JSON gracefully', () async {
      final tmp = await Directory.systemTemp.createTemp('avo_config_test_');
      final paths = AvodahPaths(configDir: tmp.path);

      // Write malformed JSON
      final configFile = File('${tmp.path}/config.json');
      await configFile.writeAsString('not valid json {{{');

      final config = await AvoConfig.load(paths);

      // Should return default config
      expect(config.categories, isEmpty);
      expect(config.categoryChips, isEmpty);

      // Cleanup
      await tmp.delete(recursive: true);
    });
  });

  group('SyncApiService /api/config/category-chips', () {
    late AppDatabase db;
    late HybridLogicalClock clock;
    late SyncApiService syncApi;

    setUp(() {
      db = openMemoryDatabase();
      clock = HybridLogicalClock(nodeId: 'desktop-1');
    });

    tearDown(() async {
      await db.close();
    });

    test('GET /api/config/category-chips returns all chips when no category specified', () async {
      final config = AvoConfig(
        categoryChips: {
          'Working': ['standup', 'code review'],
          'Learning': ['reading'],
        },
      );
      syncApi = SyncApiService(db: db, clock: clock, config: config);

      final server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((req) async {
        final handled = await syncApi.handleRequest(req);
        if (!handled) {
          req.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });

      final port = server.port;
      final client = HttpClient();
      final req = await client.get('127.0.0.1', port, '/api/config/category-chips');
      final resp = await req.close();

      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['categoryChips'], hasLength(2));
      expect(json['categoryChips']['Working'], equals(['standup', 'code review']));
      expect(json['categoryChips']['Learning'], equals(['reading']));

      client.close();
      await server.close();
    });

    test('GET /api/config/category-chips?category=Working returns chips for specific category', () async {
      final config = AvoConfig(
        categoryChips: {
          'Working': ['standup', 'code review', 'debugging'],
          'Learning': ['reading'],
        },
      );
      syncApi = SyncApiService(db: db, clock: clock, config: config);

      final server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((req) async {
        final handled = await syncApi.handleRequest(req);
        if (!handled) {
          req.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });

      final port = server.port;
      final client = HttpClient();
      final req = await client.get('127.0.0.1', port, '/api/config/category-chips?category=Working');
      final resp = await req.close();

      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['category'], equals('Working'));
      expect(json['chips'], equals(['standup', 'code review', 'debugging']));

      client.close();
      await server.close();
    });

    test('GET /api/config/category-chips?category=Unknown returns empty chips', () async {
      final config = AvoConfig(
        categoryChips: {
          'Working': ['standup'],
        },
      );
      syncApi = SyncApiService(db: db, clock: clock, config: config);

      final server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((req) async {
        final handled = await syncApi.handleRequest(req);
        if (!handled) {
          req.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });

      final port = server.port;
      final client = HttpClient();
      final req = await client.get('127.0.0.1', port, '/api/config/category-chips?category=Unknown');
      final resp = await req.close();

      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['category'], equals('Unknown'));
      expect(json['chips'], isEmpty);

      client.close();
      await server.close();
    });

    test('GET /api/config/category-chips returns empty when no config', () async {
      syncApi = SyncApiService(db: db, clock: clock, config: null);

      final server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((req) async {
        final handled = await syncApi.handleRequest(req);
        if (!handled) {
          req.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });

      final port = server.port;
      final client = HttpClient();
      final req = await client.get('127.0.0.1', port, '/api/config/category-chips');
      final resp = await req.close();

      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['categoryChips'], isEmpty);

      client.close();
      await server.close();
    });

    test('POST /api/config/category-chips returns service unavailable when no config', () async {
      syncApi = SyncApiService(db: db, clock: clock);

      final server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((req) async {
        final handled = await syncApi.handleRequest(req);
        if (!handled) {
          req.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });

      final port = server.port;
      final client = HttpClient();
      final req = await client.post('127.0.0.1', port, '/api/config/category-chips');
      final resp = await req.close();

      expect(resp.statusCode, equals(HttpStatus.serviceUnavailable));

      client.close();
      await server.close();
    });
  });
}