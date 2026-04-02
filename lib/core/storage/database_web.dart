import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens the web database using WasmDatabase.
///
/// Uses Drift's WASM implementation for browser-based SQLite.
/// Database is stored in OPFS (Origin Private File System) when available,
/// with IndexedDB as a fallback.
///
/// COOP/COEP headers must be set by the server for OPFS support:
/// - Cross-Origin-Opener-Policy: same-origin
/// - Cross-Origin-Embedder-Policy: require-corp
///
/// The sqlite3.wasm and drift_worker.js files must be served from the web/ directory.
Future<QueryExecutor> openDatabase() async {
  final result = await WasmDatabase.open(
    databaseName: 'avodah_db',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );

  if (result.missingFeatures.isNotEmpty) {
    // Log missing features but continue - IndexedDB fallback should work
    // ignore: avoid_print
    print('Web database missing features: ${result.missingFeatures}');
  }

  return result.resolvedExecutor;
}
