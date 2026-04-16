import 'package:drift/drift.dart' hide Column;

import '../storage/phone_database.dart';

/// Model for a pending capture from Android share intent.
///
/// Mirror of [PendingCaptures] drift table for use in UI.
class PendingCaptureModel {
  final int? id;
  final String title;
  final String? url;
  final String? notes;
  final String category;
  final String? sharedText;
  final DateTime createdAt;
  final bool synced;

  const PendingCaptureModel({
    this.id,
    required this.title,
    this.url,
    this.notes,
    this.category = 'learning',
    this.sharedText,
    required this.createdAt,
    this.synced = false,
  });

  /// Create from Drift row.
  factory PendingCaptureModel.fromDrift(PendingCapture row) =>
      PendingCaptureModel(
        id: row.id,
        title: row.title,
        url: row.url,
        notes: row.notes,
        category: row.category,
        sharedText: row.sharedText,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        synced: row.synced,
      );

  /// Convert to Drift companion for insert.
  PendingCapturesCompanion toCompanion() => PendingCapturesCompanion.insert(
        title: title,
        url: Value(url),
        notes: Value(notes),
        category: Value(category),
        sharedText: Value(sharedText),
        createdAt: createdAt.millisecondsSinceEpoch,
        synced: Value(synced),
      );
}