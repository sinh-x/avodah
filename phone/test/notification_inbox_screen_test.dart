import 'dart:convert';

import 'package:avodah_viewer/screens/notification_inbox_screen.dart';
import 'package:avodah_viewer/services/agent_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Map<String, dynamic> item;
  late bool offline;
  late bool conflict;
  late bool detailDenied;
  late List<http.Request> requests;
  late AgentApiClient api;
  setUp(() {
    item = {
      'id': 'n-1',
      'title': 'Build ready',
      'body': 'Review the build',
      'createdAt': '2026-11-24T11:00:00Z',
      'remarks': '',
      'revision': 1,
      'read': false,
      'handled': false,
    };
    offline = false;
    conflict = false;
    detailDenied = false;
    requests = [];
    api =
        AgentApiClient(
            baseUrl: 'https://example.test',
            client: MockClient((request) async {
              requests.add(request);
              if (offline) throw Exception('offline');
              if (request.method == 'GET' &&
                  request.url.path == '/api/notifications/n-1') {
                if (detailDenied) {
                  return http.Response('{"error":"Access revoked"}', 403);
                }
                return http.Response(jsonEncode({'item': item}), 200);
              }
              if (request.method == 'PATCH') {
                if (conflict) return http.Response('{"error":"Changed"}', 409);
                final body = jsonDecode(request.body) as Map<String, dynamic>;
                expect(body.remove('revision'), item['revision']);
                item.addAll(body);
                item['revision'] = (item['revision'] as int) + 1;
                return http.Response(jsonEncode({'item': item}), 200);
              }
              return http.Response(
                jsonEncode({
                  'items': [item],
                  'nextOffset': null,
                }),
                200,
              );
            }),
          )
          ..nodeId = 'paired-node'
          ..pairingToken = 'device-token';
  });
  tearDown(() => api.dispose());

  Future<void> open(WidgetTester tester, {String? selected}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationInboxScreen(
          apiClient: api,
          initialNotificationId: selected,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets(
    'notification tap fetches exact item from configured origin with pairing',
    (tester) async {
      await open(tester, selected: 'n-1');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        requests.last.url.toString(),
        'https://example.test/api/notifications/n-1',
      );
      expect(requests.last.headers['X-Av-Pair-Token'], 'device-token');
      expect(item['read'], false);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await close(tester);
    },
  );

  testWidgets('tap does not show private details when item access is denied', (
    tester,
  ) async {
    detailDenied = true;
    await open(tester, selected: 'n-1');
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.textContaining('selected notification is unavailable'),
      findsOneWidget,
    );
    expect(item['read'], false);
    await close(tester);
  });

  testWidgets('shares read/handled independently with paired auth', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Build ready'), findsOneWidget);
    await tester.tap(find.text('Mark handled'));
    await tester.pumpAndSettle();
    expect(item['handled'], true);
    expect(item['read'], false);
    await tester.tap(find.text('Mark read'));
    await tester.pumpAndSettle();
    expect(item['read'], true);
    expect(find.text('Mark unread'), findsOneWidget);
    expect(requests.first.headers['X-Av-Pair-Token'], 'device-token');
    expect(requests.first.headers.containsKey('Authorization'), false);
    await close(tester);
  });

  testWidgets('details do not implicitly mark read; remarks are persisted', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Details / remarks'));
    await tester.pumpAndSettle();
    expect(item['read'], false);
    await tester.enterText(find.byType(TextField), 'Followed up');
    await tester.tap(find.text('Save remarks'));
    await tester.pumpAndSettle();
    expect(item['remarks'], 'Followed up');
    await close(tester);
  });

  testWidgets('conflict preserves remarks draft and never overwrites', (
    tester,
  ) async {
    await open(tester);
    conflict = true;
    await tester.tap(find.text('Details / remarks'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    await tester.tap(find.text('Save remarks'));
    await tester.pumpAndSettle();
    expect(find.text('Remarks were not confirmed saved'), findsOneWidget);
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(item['remarks'], '');
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await close(tester);
  });

  testWidgets('polls other-device changes and disables stale edits offline', (
    tester,
  ) async {
    await open(tester);
    item['read'] = true;
    item['revision'] = 2;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Mark unread'), findsOneWidget);
    offline = true;
    await tester.tap(find.byTooltip('Refresh inbox'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-error')), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Mark unread'),
    );
    expect(button.onPressed, isNull);
    await close(tester);
  });
}
