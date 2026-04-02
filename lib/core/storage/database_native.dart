import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Opens the native database using NativeDatabase.
///
/// Uses [sqlite3_flutter_libs] for SQLite bindings on Android/Linux.
/// Database file: `<app_documents>/avodah.db`
///
/// On Linux desktop (debug), falls back to `~/.local/share/avodah/`
/// when path_provider cannot resolve XDG directories.
QueryExecutor openDatabase() {
  return LazyDatabase(() async {
    Directory dbFolder;
    try {
      dbFolder = await getApplicationDocumentsDirectory();
    } on MissingPlatformDirectoryException {
      // Fallback for Linux desktop debugging (NixOS without XDG dirs)
      final home = Platform.environment['HOME'] ?? '/tmp';
      dbFolder = Directory(p.join(home, '.local', 'share', 'avodah'));
      if (!dbFolder.existsSync()) {
        dbFolder.createSync(recursive: true);
      }
    }
    final file = File(p.join(dbFolder.path, 'avodah.db'));
    return NativeDatabase.createInBackground(file);
  });
}
