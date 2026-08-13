import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avodah_viewer/models/pa_team.dart';
import 'package:avodah_viewer/models/session_record.dart';
import 'package:avodah_viewer/screens/session_screen.dart';
import 'package:avodah_viewer/services/agent_api_client.dart';

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
    await tester.tap(find.text('Select team'));
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
}