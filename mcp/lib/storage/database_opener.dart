import 'dart:io';

import 'package:drift/native.dart';
import 'package:avodah_core/avodah_core.dart';

/// Opens the Avodah database for pure Dart (non-Flutter) usage.
///
/// Uses the sqlite3 package directly instead of sqlite3_flutter_libs.
/// The database file must already exist or will be created.
AppDatabase openDatabase(String path) {
  // Ensure parent directory exists
  final dbFile = File(path);
  final dir = dbFile.parent;
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  // Open database using pure Dart SQLite
  final database = NativeDatabase.createInBackground(dbFile);

  // Create database with the executor
  return AppDatabase(database);
}

/// Opens an in-memory database for testing.
AppDatabase openMemoryDatabase() {
  final database = NativeDatabase.memory();
  return AppDatabase(database);
}
