import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

class NotificationProblem implements Exception {
  final int status;
  final String message;
  NotificationProblem(this.status, this.message);
  @override
  String toString() => message;
}

/// Server-authoritative inbox, deliberately separate from the CRDT database.
/// Synchronous transactions serialize revision checks and idempotent sends.
class NotificationStore {
  final Database _db;

  NotificationStore(String path) : _db = sqlite3.open(path) {
    final version = _db.select('PRAGMA user_version').first.values.first as int;
    if (version > 1) {
      _db.dispose();
      throw StateError('Unsupported notification database version');
    }
    if (version == 0) {
      // Preserve any existing database before applying schema changes.
      if (path != ':memory:' && File(path).lengthSync() > 0) {
        final backup =
            '$path.before-v1-${DateTime.now().microsecondsSinceEpoch}';
        if (File(backup).existsSync())
          throw StateError('Backup already exists');
        _db.execute('VACUUM INTO ?', [backup]);
      }
      _db.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL,
          created_at TEXT NOT NULL, revision INTEGER NOT NULL DEFAULT 1,
          is_read INTEGER NOT NULL DEFAULT 0,
          handled INTEGER NOT NULL DEFAULT 0, remarks TEXT NOT NULL DEFAULT '',
          deleted INTEGER NOT NULL DEFAULT 0
        );
        PRAGMA user_version = 1;
      ''');
    }
    _db.execute('PRAGMA busy_timeout = 5000');
    _db.execute('PRAGMA synchronous = FULL');
  }

  Map<String, dynamic> _record(Row row) => {
        'id': row['id'],
        'title': row['title'],
        'body': row['body'],
        'createdAt': row['created_at'],
        'revision': row['revision'],
        'read': row['is_read'] == 1,
        'handled': row['handled'] == 1,
        'remarks': row['remarks'],
      };

  List<Map<String, dynamic>> list({int offset = 0, int limit = 100}) => _db
      .select(
          'SELECT * FROM notifications WHERE deleted = 0 '
          'ORDER BY created_at DESC, id DESC LIMIT ? OFFSET ?',
          [limit, offset])
      .map(_record)
      .toList();

  Map<String, dynamic> get(String id) {
    final rows = _db.select(
        'SELECT * FROM notifications WHERE id = ? AND deleted = 0', [id]);
    if (rows.isEmpty) throw NotificationProblem(404, 'Notification not found');
    return _record(rows.first);
  }

  /// Reusing an ID with the same content is safe even after edits/deletion.
  /// A deleted ID is kept as a tombstone so retries cannot resurrect it.
  ({Map<String, dynamic> item, bool created}) send(
      String id, String title, String body) {
    _db.execute('BEGIN IMMEDIATE');
    try {
      final rows = _db.select('SELECT * FROM notifications WHERE id = ?', [id]);
      if (rows.isNotEmpty) {
        final row = rows.first;
        if (row['title'] != title || row['body'] != body) {
          throw NotificationProblem(
              409, 'ID already used for different content');
        }
        if (row['deleted'] == 1) {
          throw NotificationProblem(410, 'Notification was explicitly deleted');
        }
        _db.execute('COMMIT');
        return (item: _record(row), created: false);
      }
      _db.execute(
          'INSERT INTO notifications (id, title, body, created_at) '
          'VALUES (?, ?, ?, ?)',
          [id, title, body, DateTime.now().toUtc().toIso8601String()]);
      final item = get(id);
      _db.execute('COMMIT');
      return (item: item, created: true);
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  Map<String, dynamic> update(String id, int revision,
      {bool? read, bool? handled, String? remarks, bool delete = false}) {
    _db.execute('BEGIN IMMEDIATE');
    try {
      final current = get(id);
      if (current['revision'] != revision) {
        throw NotificationProblem(
            409, 'Notification changed; refresh before editing');
      }
      _db.execute(
          'UPDATE notifications SET is_read = ?, handled = ?, '
          'remarks = ?, deleted = ?, revision = revision + 1 WHERE id = ?',
          [
            (read ?? current['read'] as bool) ? 1 : 0,
            (handled ?? current['handled'] as bool) ? 1 : 0,
            remarks ?? current['remarks'],
            delete ? 1 : 0,
            id,
          ]);
      final item = delete ? <String, dynamic>{'deleted': true} : get(id);
      _db.execute('COMMIT');
      return item;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => _db.dispose();
}
