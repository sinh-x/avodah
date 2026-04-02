import 'package:drift/wasm.dart';
import 'package:avodah_core/avodah_core.dart';

/// Opens the Avodah database on web platforms using WasmDatabase.
///
/// Uses IndexedDB via OPFS (Origin Private File System) for storage.
/// Requires COOP/COEP headers for cross-origin isolation support.
Future<AppDatabase> openPhoneDatabase() async {
  final result = await WasmDatabase.open(
    databaseName: 'avodah_phone',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );

  if (result.missingFeatures.isNotEmpty) {
    // Log missing features but continue - some are non-critical
    // ignore: avoid_print
    print('WebDB: Missing features: ${result.missingFeatures}');
  }

  final executor = result.resolvedExecutor;
  return AppDatabase(executor);
}
