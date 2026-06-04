/// Sync status and diagnostics commands.
library;

import 'package:args/command_runner.dart';
import 'package:avodah_core/avodah_core.dart';

import '../services/sync_api_service.dart';
import 'format.dart' show sectionHeader, kvRow, formatTimestamp;

/// Sync management command group.
class SyncCommand extends Command<void> {
  final AppDatabase db;
  final HybridLogicalClock clock;

  SyncCommand({required this.db, required this.clock}) {
    addSubcommand(SyncStatusCommand(db: db, clock: clock));
    addSubcommand(SyncDiffCommand(db: db, clock: clock));
  }

  @override
  String get name => 'sync';

  @override
  String get description => 'CRDT sync status and diagnostics (status, diff)';
}

/// Shows current sync state, watermarks, and local document counts.
class SyncStatusCommand extends Command<void> {
  final AppDatabase db;
  final HybridLogicalClock clock;

  SyncStatusCommand({required this.db, required this.clock});

  @override
  String get name => 'status';

  @override
  String get description => 'Show sync state, watermarks, and document counts';

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
    final lastPhoneSync =
        formatTimestamp(diagnostics['lastPhoneSync'] as int?);
    print(kvRow('Phone watermark:', phoneWatermark));
    print(kvRow('Last phone sync:', lastPhoneSync));

    // Desktop clock
    print(kvRow('Desktop node:', clock.nodeId));
    print(kvRow('Desktop HLC:', clock.now().pack()));

    print('');
    print('  Local document counts (not pending sync):');
    final counts = diagnostics['deltaCounts'] as Map<String, int>;
    print(kvRow('  dailyPlan:', '${counts['dailyPlan'] ?? 0}'));
    print(kvRow('  dayPlanTask:', '${counts['dayPlanTask'] ?? 0}'));
    print(kvRow('  task:', '${counts['task'] ?? 0}'));
    print(kvRow('  worklog:', '${counts['worklog'] ?? 0}'));
    print(kvRow('  timer:', '${counts['timer'] ?? 0}'));
    print(kvRow('  project:', '${counts['project'] ?? 0}'));
  }

}

/// Shows sync diff: watermarks, timer state, and pending delta counts.
class SyncDiffCommand extends Command<void> {
  final AppDatabase db;
  final HybridLogicalClock clock;

  SyncDiffCommand({required this.db, required this.clock});

  @override
  String get name => 'diff';

  @override
  String get description =>
      'Show sync gaps: watermarks, timer state, pending delta counts';

  @override
  String get invocation => 'avo sync diff';

  @override
  Future<void> run() async {
    final syncApi = SyncApiService(db: db, clock: clock);
    final diagnostics = await syncApi.syncDiagnostics();

    print(sectionHeader('SYNC DIFF'));
    print('');

    final desktopWatermark =
        diagnostics['desktopWatermark'] as String? ?? '?';
    final phoneWatermark = diagnostics['phoneWatermark'] as String? ?? '0';
    final lastPhoneSync = diagnostics['lastPhoneSync'] as int?;
    final desktopTimer =
        diagnostics['desktopTimer'] as Map<String, dynamic>?;
    final pendingDeltas =
        diagnostics['pendingDeltas'] as Map<String, dynamic>? ?? {};

    print(kvRow('Desktop watermark:', desktopWatermark));
    print(kvRow('Phone watermark:', phoneWatermark == '0' ? '0 (never synced)' : phoneWatermark));
    print(kvRow('Last phone sync:', formatTimestamp(lastPhoneSync)));
    print(kvRow('Desktop node:', clock.nodeId));

    print('');
    print('  Timer state:');
    if (desktopTimer != null) {
      print(kvRow('  desktop:', 'RUNNING'));
      final startedAt = desktopTimer['startedAtMs'] as int?;
      final taskTitle = desktopTimer['taskTitle'] as String?;
      if (startedAt != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(startedAt);
        final now = DateTime.now();
        final elapsed = now.difference(dt);
        final h = elapsed.inHours;
        final m = elapsed.inMinutes.remainder(60);
        print(kvRow('  started:', '${formatTimestamp(startedAt)}'));
        print(kvRow('  elapsed:', '${h}h ${m}m'));
      }
      if (taskTitle != null) {
        print(kvRow('  task:', taskTitle));
      }

      // Gap between desktop timer start and last phone sync
      if (startedAt != null && lastPhoneSync != null && lastPhoneSync > 0) {
        final gapMs = (startedAt - lastPhoneSync).abs();
        final gapH = gapMs ~/ (3600000);
        final gapM = (gapMs % 3600000) ~/ 60000;
        print(kvRow('  timer/sync gap:', '${gapH}h ${gapM}m'));
      }
    } else {
      print('  desktop: idle');
    }

    // Phone timer state is not directly reachable (local queries only per NFR3)
    print('  phone: unknown (local queries only)');

    print('');
    print('  Pending deltas (desktop docs after phone watermark):');
    final types = ['task', 'worklog', 'timer', 'project', 'dailyPlan', 'dayPlanTask'];
    var any = false;
    for (final type in types) {
      final count = (pendingDeltas[type] as int?) ?? 0;
      if (count > 0) any = true;
      print(kvRow('  $type:', '$count'));
    }
    if (!any) {
      print('  (none \u2014 desktop and phone are in sync)');
    }
  }
}
