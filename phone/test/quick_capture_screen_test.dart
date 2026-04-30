import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avodah_viewer/models/ticket.dart';
import 'package:avodah_viewer/screens/quick_capture_screen.dart';
import 'package:avodah_viewer/services/agent_api_client.dart';
import 'package:avodah_viewer/services/capture_sync_service.dart';
import 'package:avodah_viewer/storage/phone_database.dart';

void main() {
  group('QuickCaptureScreen', () {
    testWidgets('defaults to learning and saves pending capture project', (
      tester,
    ) async {
      final db = PhoneDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final apiClient = _QuickCaptureAgentApiClient();
      final syncService = CaptureSyncService(db: db, apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: QuickCaptureScreen(
            sharedText: 'Read this later',
            sharedUrl: 'https://example.com/article',
            captureSyncService: syncService,
            apiClient: apiClient,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final projectDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).first,
      );
      expect(projectDropdown.initialValue, 'learning');

      await tester.tap(find.text('Save Capture'));
      await tester.pumpAndSettle();

      final captures = await db.select(db.pendingCaptures).get();
      expect(captures.single.project, 'learning');
      expect(apiClient.createdTickets.single['project'], 'learning');
    });
  });
}

class _QuickCaptureAgentApiClient extends AgentApiClient {
  _QuickCaptureAgentApiClient() : super(baseUrl: 'http://localhost');

  final List<Map<String, dynamic>> createdTickets = [];

  @override
  Future<List<TicketProject>> getProjects() async {
    return const [
      TicketProject(key: 'learning', activeTicketCount: 1),
      TicketProject(key: 'avodah', activeTicketCount: 1),
    ];
  }

  @override
  Future<Ticket> createTicket(Map<String, dynamic> data) async {
    createdTickets.add(Map<String, dynamic>.from(data));
    final now = DateTime.utc(2026, 4, 30);
    return Ticket(
      id: 'LM-001',
      project: data['project'] as String,
      title: data['title'] as String,
      status: 'idea',
      priority: 'medium',
      type: 'idea',
      estimate: 'XS',
      tags: const [],
      blockedBy: const [],
      docRefs: const [],
      comments: const [],
      subTickets: const [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
