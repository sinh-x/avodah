import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:avodah_core/avodah_core.dart';

/// Opens the Avodah database on the phone using Flutter's path_provider.
///
/// Uses [sqlite3_flutter_libs] for Android SQLite bindings.
/// Database file: `<app_documents>/avodah_phone.db`
///
/// On Linux desktop (debug), falls back to `~/.local/share/avodah/`
/// when path_provider cannot resolve XDG directories.
Future<AppDatabase> openPhoneDatabase() async {
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
  final file = File(p.join(dbFolder.path, 'avodah_phone.db'));
  final executor = NativeDatabase.createInBackground(file);
  return AppDatabase(executor);
}
