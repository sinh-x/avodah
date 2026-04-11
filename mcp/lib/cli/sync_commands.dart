/// Sync status and diagnostics commands.
library;

import 'package:args/command_runner.dart';
import 'package:avodah_core/avodah_core.dart';

import '../services/sync_api_service.dart';
import 'format.dart' show sectionHeader, kvRow;

/// Sync management command group.
class SyncCommand extends Command<void> {
  final AppDatabase db;
  final HybridLogicalClock clock;

  SyncCommand({required this.db, required this.clock}) {
    addSubcommand(SyncStatusCommand(db: db, clock: clock));
  }

  @override
  String get name => 'sync';

  @override
  String get description =>
      'CRDT sync status and diagnostics (status)';
}

/// Shows current sync state, watermarks, and per-document delta counts.
class SyncStatusCommand extends Command<void> {
  final AppDatabase db;
  final HybridLogicalClock clock;

  SyncStatusCommand({required this.db, required this.clock});

  @override
  String get name => 'status';

  @override
  String get description => 'Show sync state, watermarks, and delta counts';

  @override
  String get invocation => 'avo sync status';

  @override
  Future<void> run() async {
    final syncApi = SyncApiService(db: db, clock: clock);
    final diagnostics = await syncApi.syncDiagnostics();

    print(sectionHeader('SYNC STATUS'));
    print('');

    // Connection state — desktop runs the server locally
    print(kvRow('Mode:', 'desktop (server)'));
    print(kvRow('Server:', 'running on port 9847'));

    // Last sync from phone (received)
    final phoneWatermark = diagnostics['phoneWatermark'] as String? ?? '0';
    final lastPhoneSync = _formatTimestamp(diagnostics['lastPhoneSync'] as int?);
    print(kvRow('Phone watermark:', phoneWatermark));
    print(kvRow('Last phone sync:', lastPhoneSync));

    // Desktop clock
    print(kvRow('Desktop node:', clock.nodeId));
    print(kvRow('Desktop HLC:', clock.now().pack()));

    print('');
    print('  Per-document delta counts:');
    final counts = diagnostics['deltaCounts'] as Map<String, int>;
    print(kvRow('  dailyPlan:', '${counts['dailyPlan'] ?? 0}'));
    print(kvRow('  dayPlanTask:', '${counts['dayPlanTask'] ?? 0}'));
    print(kvRow('  task:', '${counts['task'] ?? 0}'));
    print(kvRow('  worklog:', '${counts['worklog'] ?? 0}'));
    print(kvRow('  timer:', '${counts['timer'] ?? 0}'));
    print(kvRow('  project:', '${counts['project'] ?? 0}'));
  }

  String _formatTimestamp(int? millis) {
    if (millis == null || millis == 0) return 'never';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
