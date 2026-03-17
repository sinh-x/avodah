import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:avodah_core/avodah_core.dart';

/// Opens the Avodah database on the phone using Flutter's path_provider.
///
/// Uses [sqlite3_flutter_libs] for Android SQLite bindings.
/// Database file: `<app_documents>/avodah_phone.db`
Future<AppDatabase> openPhoneDatabase() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'avodah_phone.db'));
  final executor = NativeDatabase.createInBackground(file);
  return AppDatabase(executor);
}
