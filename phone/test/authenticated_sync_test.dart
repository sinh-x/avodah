import 'dart:convert';
import 'package:avodah_core/avodah_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avodah_viewer/services/agent_api_client.dart';
import 'package:avodah_viewer/services/crdt_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'persistent node identity is independent for each normalized server',
    () async {
      SharedPreferences.setMockInitialValues({});
      final a = await CrdtSyncService.getOrCreateNodeId(
        scope: 'https://test/avodah/',
      );
      expect(
        await CrdtSyncService.getOrCreateNodeId(scope: 'https://test/avodah'),
        a,
      );
      expect(
        await CrdtSyncService.getOrCreateNodeId(scope: 'https://other/avodah'),
        isNot(a),
      );
    },
  );
  test(
    'REST consumers use current credential after rotation and forget',
    () async {
      String? token = 'first';
      final seen = <String?>[];
      final api =
          AgentApiClient(
              baseUrl: 'https://test/avodah',
              client: MockClient((r) async {
                seen.add(r.headers['X-Av-Pair-Token']);
                expect(r.headers['X-Av-Node-Id'], 'browser');
                return http.Response('{"categories":[]}', 200);
              }),
            )
            ..nodeId = 'browser'
            ..pairingTokenProvider = (() => token);
      await api.getCategories();
      token = 'second';
      await api.getCategories();
      token = null;
      await api.getCategories();
      expect(seen, ['first', 'second', null]);
      api.dispose();
    },
  );
  test(
    'seven families replay without duplicate records and partial merge retains watermark',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final clock = HybridLogicalClock(nodeId: 'browser');
      final stamp = HybridLogicalClock(nodeId: 'server').now().pack();
      final types = [
        'task',
        'worklog',
        'timer',
        'project',
        'dailyPlan',
        'dayPlanTask',
        'categoryChip',
      ];
      var deltas = [
        for (final type in types)
          {
            'type': type,
            'id': type == 'timer' ? 'active-timer' : 'fixture-$type',
            'fields': {
              for (final field in [
                'title',
                'taskTitle',
                'name',
                'date',
                'category',
                'label',
              ])
                field: {'v': 'synthetic', 't': stamp},
            },
          },
      ];
      var rejectPush = false;
      final sync = CrdtSyncService(
        baseUrl: 'https://test/avodah',
        db: db,
        clock: clock,
        nodeId: 'browser',
        client: MockClient((r) async {
          if (r.method == 'POST') {
            final body = jsonDecode(r.body) as Map;
            expect(body['node'], 'browser');
            final sent = body['deltas'] as List;
            expect(sent.map((d) => d['type']).toSet(), types.toSet());
            return http.Response(
              jsonEncode({
                'merged': rejectPush ? 0 : sent.length,
                'errors': rejectPush ? ['failed'] : [],
                'watermark': stamp,
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({'deltas': deltas, 'watermark': stamp}),
            200,
          );
        }),
      );
      expect(await sync.pullFromDesktop(), 7);
      expect(await sync.pullFromDesktop(), 7);
      expect(await db.select(db.tasks).get(), hasLength(1));
      expect(await db.select(db.categoryChips).get(), hasLength(1));
      expect(await sync.forceFullSync(), 7);
      final before = (await db.select(db.syncWatermarks).get()).first.lastHlc;
      deltas = [
        {'type': 'invalid', 'id': 'bad', 'fields': {}},
      ];
      await expectLater(sync.pullFromDesktop(), throwsStateError);
      expect((await db.select(db.syncWatermarks).get()).first.lastHlc, before);
      rejectPush = true;
      await expectLater(sync.forceFullSync(), throwsStateError);
      sync.dispose();
      await db.close();
    },
  );
}
