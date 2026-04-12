/// CRDT-backed CategoryChip document for conflict-free synchronization.
///
/// This document represents a category chip (e.g., "Working", "Learning")
/// with a category grouping, label, and sort order. Chips currently stored
/// in config.json are being migrated to SQLite for bidirectional sync.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../crdt/crdt.dart';
import '../storage/database.dart';

/// Field keys for CategoryChipDocument.
class CategoryChipFields {
  CategoryChipFields._();

  /// Category grouping for this chip (e.g., "Working", "Learning").
  static const String category = 'category';

  /// Display label for this chip.
  static const String label = 'label';

  /// Sort order within the category.
  static const String sortOrder = 'sortOrder';
}

/// A CRDT-backed category chip document.
///
/// All fields are tracked with individual timestamps for fine-grained
/// conflict resolution during P2P sync.
class CategoryChipDocument extends CrdtDocument<CategoryChipDocument> {
  /// Creates a new category chip document with a generated UUID.
  factory CategoryChipDocument.create({
    required HybridLogicalClock clock,
    required String category,
    required String label,
    int sortOrder = 0,
  }) {
    final doc = CategoryChipDocument(
      id: const Uuid().v4(),
      clock: clock,
    );
    doc.category = category;
    doc.label = label;
    doc.sortOrder = sortOrder;
    return doc;
  }

  /// Creates a category chip document with an existing ID.
  CategoryChipDocument({
    required super.id,
    required super.clock,
  });

  /// Creates a category chip document from existing CRDT state.
  CategoryChipDocument.fromState({
    required super.id,
    required super.clock,
    required super.state,
  }) : super.fromState();

  /// Creates a category chip document from a Drift CategoryChip entity.
  factory CategoryChipDocument.fromDrift({
    required CategoryChip chip,
    required HybridLogicalClock clock,
  }) {
    final state = CrdtDocument.stateFromCrdtState(chip.crdtState);

    final doc = CategoryChipDocument.fromState(
      id: chip.id,
      clock: clock,
      state: state,
    );

    if (state.isEmpty) {
      // No CRDT state at all — initialize everything from Drift fields
      doc._initializeFromDrift(chip);
    } else {
      // Backfill fields added in later schema versions that may be missing
      // from CRDT state.
      doc._backfillFromDrift(chip);
    }

    return doc;
  }

  /// Initializes fields from Drift entity when no CRDT state exists.
  void _initializeFromDrift(CategoryChip chip) {
    setString(CategoryChipFields.category, chip.category);
    setString(CategoryChipFields.label, chip.label);
    setInt(CategoryChipFields.sortOrder, chip.sortOrder);
  }

  /// Backfills fields from Drift columns when they are missing from CRDT
  /// state. This handles fields added in later schema versions.
  void _backfillFromDrift(CategoryChip chip) {
    final keys = fieldKeys.toSet();
    if (!keys.contains(CategoryChipFields.category)) {
      setString(CategoryChipFields.category, chip.category);
    }
    if (!keys.contains(CategoryChipFields.label)) {
      setString(CategoryChipFields.label, chip.label);
    }
    if (!keys.contains(CategoryChipFields.sortOrder)) {
      setInt(CategoryChipFields.sortOrder, chip.sortOrder);
    }
  }

  // ============================================================
  // Core Fields
  // ============================================================

  /// Category grouping for this chip (e.g., "Working", "Learning").
  String get category => getString(CategoryChipFields.category) ?? '';
  set category(String value) => setString(CategoryChipFields.category, value);

  /// Display label for this chip.
  String get label => getString(CategoryChipFields.label) ?? '';
  set label(String value) => setString(CategoryChipFields.label, value);

  /// Sort order within the category.
  int get sortOrder => getInt(CategoryChipFields.sortOrder) ?? 0;
  set sortOrder(int value) => setInt(CategoryChipFields.sortOrder, value);

  // ============================================================
  // Conversion
  // ============================================================

  /// Converts to a Drift CategoryChipsCompanion for insert/update.
  CategoryChipsCompanion toDriftCompanion() {
    return CategoryChipsCompanion(
      id: Value(id),
      category: Value(category),
      label: Value(label),
      sortOrder: Value(sortOrder),
      crdtClock: Value(clock.lastTimestamp.pack()),
      crdtState: Value(toCrdtState()),
    );
  }

  /// Converts to an immutable CategoryChip UI model.
  CategoryChipModel toModel() {
    return CategoryChipModel(
      id: id,
      category: category,
      label: label,
      sortOrder: sortOrder,
      isDeleted: isDeleted,
    );
  }

  @override
  CategoryChipDocument copyWith({String? id, HybridLogicalClock? clock}) {
    return CategoryChipDocument(
      id: id ?? this.id,
      clock: clock ?? this.clock,
    );
  }
}

/// Immutable category chip model for UI consumption.
///
/// This is a read-only snapshot of a chip's state, suitable for
/// use in widgets and state management.
class CategoryChipModel {
  final String id;
  final String? category;
  final String? label;
  final int sortOrder;
  final bool isDeleted;

  const CategoryChipModel({
    required this.id,
    this.category,
    this.label,
    required this.sortOrder,
    required this.isDeleted,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryChipModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryChipModel($id, "$category/$label", sortOrder: $sortOrder)';
}