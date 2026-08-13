import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:avodah_viewer/models/pa_team.dart';
import 'package:avodah_viewer/models/session_record.dart';
import 'package:avodah_viewer/screens/session_screen.dart';
import 'package:avodah_viewer/services/agent_api_client.dart';
import 'package:avodah_viewer/services/ws_session_client.dart';

/// Minimal fake [AgentApiClient] that returns canned data without network.
class _FakeApiClient extends AgentApiClient {
  _FakeApiClient()
      : super(baseUrl: 'http://localhost:9847');

  @override
  Future<List<PaTeam>> listPaTeams() async {
    return [
      const PaTeam(
        name: 'builder',
        description: 'Builder team',
        deployModes: [
          DeployMode(id: 'implement', label: 'Implement'),
          DeployMode(id: 'review', label: 'Review'),
        ],
      ),
      const PaTeam(
        name: 'requirements',
        description: 'Requirements team',
        deployModes: [
          DeployMode(id: 'research', label: 'Research'),
        ],
      ),
    ];
  }

  @override
  Future<List<SessionRecord>> listSessions() async {
    return [
      const SessionRecord(
        id: 's1234567890-1',
        deploymentId: 'd-abc123',
        status: 'running',
      ),
    ];
  }
}

/// A minimal fake [WebSocketChannel] for testing the live session flow
/// (Mn4). Uses a broadcast [StreamController] to simulate the
/// bidirectional stream/sink pair.
class _FakeWsChannel
    extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _sinkController =
      StreamController<dynamic>();

  final List<String> sentMessages = [];

  void serverSend(String json) {
    _streamController.add(json);
  }

  void serverClose() {
    _streamController.close();
  }

  @override
  Stream get stream => _streamController.stream;

  @override
  WebSocketSink get sink => _FakeWsSink(this);

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

class _FakeWsSink implements WebSocketSink {
  final _FakeWsChannel _channel;

  _FakeWsSink(this._channel);

  @override
  void add(dynamic event) {
    _channel.sentMessages.add(event as String);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream stream) async {
    await for (final item in stream) {
      add(item);
    }
  }

  @override
  Future close([int? closeCode, String? closeReason]) {
    _channel._sinkController.close();
    return Future.value();
  }

  @override
  Future get done => Future.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SessionScreen setup mode shows team selector and session list',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SessionScreen(apiClient: _FakeApiClient())),
      ),
    );
    // Let the async _loadSetupData complete.
    await tester.pumpAndSettle();

    // "New Session" section is present.
    expect(find.text('New Session'), findsOneWidget);
    // Team dropdown hint.
    expect(find.text('Select team'), findsOneWidget);
    // Existing session from the fake list is shown.
    expect(find.text('s1234567890-1'), findsOneWidget);
  });

  testWidgets('SessionScreen shows mode chips after team selection',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SessionScreen(apiClient: _FakeApiClient())),
      ),
    );
    await tester.pumpAndSettle();

    // Open the team dropdown and pick "builder".
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('builder').last);
    await tester.pumpAndSettle();

    // The builder team has two modes — "Implement" and "Review".
    expect(find.text('Implement'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('SessionScreen Start button disabled until team+mode+prompt set',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SessionScreen(apiClient: _FakeApiClient())),
      ),
    );
    await tester.pumpAndSettle();

    // The Start Session label is present (button is disabled — no team/mode).
    expect(find.text('Start Session'), findsOneWidget);
    // The prompt field hint is shown.
    expect(find.text('Type the initial prompt for the session'), findsOneWidget);
  });

  // -- Live flow tests (Mn4) -------------------------------------------------

  testWidgets('live flow: start → session-id → event → end → view-only',
      (tester) async {
    final fakeChannel = _FakeWsChannel();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: SessionScreen(
              apiClient: _FakeApiClient(),
              wsClientFactory: () =>
                  WsSessionClient.forTesting(fakeChannel),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select team "builder" via the dropdown
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('builder').last);
    await tester.pumpAndSettle();

    // Select mode "Implement" (tap the FilterChip, not just the label)
    final implementChip = find.ancestor(
        of: find.text('Implement'), matching: find.byType(FilterChip));
    await tester.tap(implementChip);
    await tester.pumpAndSettle();

    // Type a prompt — the prompt TextField has hint 'Type the initial prompt'.
    final promptFinder = find.byType(TextField).at(0);
    await tester.ensureVisible(promptFinder);
    await tester.enterText(promptFinder, 'Do something useful');
    await tester.pumpAndSettle();

    // Tap Start Session — use the button widget, not just the text.
    final startBtn = find.ancestor(
        of: find.byIcon(Icons.play_arrow),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    await tester.ensureVisible(startBtn);
    await tester.tap(startBtn);
    await tester.pump(const Duration(milliseconds: 200));

    // Verify a start message was sent over the WS.
    expect(fakeChannel.sentMessages, hasLength(1));
    final sentMsg = jsonDecode(fakeChannel.sentMessages[0])
        as Map<String, dynamic>;
    expect(sentMsg['type'], 'start');
    expect(sentMsg['prompt'], 'Do something useful');

    // Server sends session-id event
    fakeChannel.serverSend(jsonEncode({
      'type': 'session-id',
      'sessionId': 's-live-1',
      'timestamp': '2026-08-13T04:00:00Z',
    }));
    await tester.pump(const Duration(milliseconds: 200));

    // Should be in live mode now showing the session id.
    expect(find.textContaining('s-live-1'), findsWidgets);

    // Server sends an event
    fakeChannel.serverSend(jsonEncode({
      'type': 'event',
      'timestamp': '2026-08-13T04:00:01Z',
      'data': {'kind': 'output', 'body': 'Working on it…'},
    }));
    await tester.pump(const Duration(milliseconds: 200));

    // The event body should appear in the event list.
    expect(find.textContaining('Working on it'), findsOneWidget);

    // Server sends end event
    fakeChannel.serverSend(jsonEncode({
      'type': 'end',
      'timestamp': '2026-08-13T04:00:02Z',
      'data': {'reason': 'completed', 'exitCode': 0},
    }));
    await tester.pump(const Duration(milliseconds: 200));

    // Should transition to view-only mode.
    expect(find.text('Session ended — view-only'), findsOneWidget);
    expect(find.text('New Session'), findsWidgets);
  });

  testWidgets('live flow: connection failure shows error and stays in setup',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: SessionScreen(
              apiClient: _FakeApiClient(),
              wsClientFactory: () {
                throw WsSessionConnectException('pa-platform is not running');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select team and mode
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('builder').last);
    await tester.pumpAndSettle();
    final implementChip = find.ancestor(
        of: find.text('Implement'), matching: find.byType(FilterChip));
    await tester.tap(implementChip);
    await tester.pumpAndSettle();

    // Type prompt
    final promptFinder = find.byType(TextField).at(0);
    await tester.ensureVisible(promptFinder);
    await tester.enterText(promptFinder, 'Test prompt');
    await tester.pumpAndSettle();

    // Tap Start
    final startBtn = find.ancestor(
        of: find.byIcon(Icons.play_arrow),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    await tester.ensureVisible(startBtn);
    await tester.tap(startBtn);
    await tester.pumpAndSettle();

    // Should show error message (in setup warning area).
    expect(find.textContaining('pa-platform is not running'), findsWidgets);
    // Should still be in setup mode (not live).
    expect(find.text('Start Session'), findsOneWidget);
  });

  testWidgets('live flow: WS done without end transitions to view-only (Mn6)',
      (tester) async {
    final fakeChannel = _FakeWsChannel();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: SessionScreen(
              apiClient: _FakeApiClient(),
              wsClientFactory: () =>
                  WsSessionClient.forTesting(fakeChannel),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Setup: select team, mode, enter prompt, start
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('builder').last);
    await tester.pumpAndSettle();
    final implementChip = find.ancestor(
        of: find.text('Implement'), matching: find.byType(FilterChip));
    await tester.tap(implementChip);
    await tester.pumpAndSettle();
    final promptFinder = find.byType(TextField).at(0);
    await tester.ensureVisible(promptFinder);
    await tester.enterText(promptFinder, 'Test prompt');
    await tester.pumpAndSettle();
    final startBtn = find.ancestor(
        of: find.byIcon(Icons.play_arrow),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    await tester.ensureVisible(startBtn);
    await tester.tap(startBtn);
    await tester.ensureVisible(startBtn);
    await tester.tap(startBtn);
    await tester.pump(const Duration(milliseconds: 200));

    // Server sends session-id
    fakeChannel.serverSend(jsonEncode({
      'type': 'session-id',
      'sessionId': 's-drop-1',
      'timestamp': '2026-08-13T04:00:00Z',
    }));
    await tester.pump(const Duration(milliseconds: 200));

    // Should be live
    expect(find.textContaining('s-drop-1'), findsWidgets);

    // Server disconnects without sending end event
    fakeChannel.serverClose();
    await tester.pump(const Duration(milliseconds: 200));

    // Should transition to view-only (Mn6: consistent state on disconnect)
    expect(find.text('Session ended — view-only'), findsOneWidget);
  });
}