import 'package:drift/drift.dart';

/// Stub for conditional import.
///
/// This file is used when neither dart:io nor dart:js_interop is available,
/// which should not happen in normal operation. Platform-specific implementations
/// are selected via conditional imports:
/// - database_native.dart for native platforms (dart:io)
/// - database_web.dart for web platforms (dart:js_interop)
QueryExecutor openDatabase() {
  throw UnsupportedError(
    'No database implementation available for this platform.',
  );
}
