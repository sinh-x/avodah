import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avodah_viewer/models/ticket.dart';
import 'package:avodah_viewer/services/agent_api_client.dart';
import 'package:avodah_viewer/services/capture_sync_service.dart';
import 'package:avodah_viewer/storage/phone_database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('CaptureSyncService', () {
    test(
      'normalizes legacy learning-management project before retry',
      () async {
        final db = PhoneDatabase(NativeDatabase.memory());
        final apiClient = _RecordingAgentApiClient();
        final service = CaptureSyncService(db: db, apiClient: apiClient);

        await _insertPendingCapture(db, project: 'learning-management');

        await service.syncPendingCaptures();

        expect(apiClient.createdTickets, hasLength(1));
        expect(apiClient.createdTickets.single['project'], 'learning');

        final captures = await db.select(db.pendingCaptures).get();
        expect(captures.single.synced, isTrue);

        await db.close();
      },
    );

    test('leaves legacy capture unsynced when ticket creation fails', () async {
      final db = PhoneDatabase(NativeDatabase.memory());
      final apiClient = _RecordingAgentApiClient(shouldFail: true);
      final service = CaptureSyncService(db: db, apiClient: apiClient);

      await _insertPendingCapture(db, project: 'learning-management');

      await service.syncPendingCaptures();

      expect(apiClient.createdTickets, hasLength(1));
      expect(apiClient.createdTickets.single['project'], 'learning');

      final captures = await db.select(db.pendingCaptures).get();
      expect(captures.single.synced, isFalse);

      await db.close();
    });
  });
}

Future<void> _insertPendingCapture(
  PhoneDatabase db, {
  required String project,
}) async {
  await db
      .into(db.pendingCaptures)
      .insert(
        PendingCapturesCompanion.insert(
          title: 'Shared learning link',
          url: const Value('https://example.com/article'),
          notes: const Value('Read later'),
          category: const Value('learning'),
          sharedText: const Value('https://example.com/article'),
          project: Value(project),
          createdAt: DateTime.utc(2026, 4, 30).millisecondsSinceEpoch,
        ),
      );
}

class _RecordingAgentApiClient extends AgentApiClient {
  _RecordingAgentApiClient({this.shouldFail = false})
    : super(baseUrl: 'http://localhost');

  final bool shouldFail;
  final List<Map<String, dynamic>> createdTickets = [];

  @override
  Future<Ticket> createTicket(Map<String, dynamic> data) async {
    createdTickets.add(Map<String, dynamic>.from(data));
    if (shouldFail) {
      throw AgentApiException(500, 'server unavailable');
    }

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
