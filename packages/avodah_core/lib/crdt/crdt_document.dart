/// CRDT Document base class for conflict-free replicated entities.
///
/// Provides the foundation for all domain entities that need to sync
/// across devices using CRDTs. Each document uses an [LWWMap] internally
/// to track per-field timestamps for fine-grained conflict resolution.
///
/// Usage:
/// ```dart
/// class TaskDocument extends CrdtDocument<TaskDocument> {
///   TaskDocument({required super.id, required super.clock});
///
///   String? get title => getString('title');
///   set title(String? value) => setString('title', value);
///
///   @override
///   TaskDocument copyWith({String? id, HybridLogicalClock? clock}) {
///     return TaskDocument(id: id ?? this.id, clock: clock ?? this.clock)
///       ..mergeFrom(this);
///   }
/// }
/// ```
library;

import 'dart:convert';

import 'hlc.dart';
import 'lww_register.dart';

/// Reserved field keys used by the document infrastructure.
class CrdtFields {
  CrdtFields._();

  /// Soft delete flag field key.
  static const String isDeleted = '_deleted';

  /// Document creation timestamp field key.
  static const String createdAt = '_createdAt';

  /// Document modification timestamp field key.
  static const String modifiedAt = '_modifiedAt';
}

/// Abstract base class for CRDT-backed documents.
///
/// Subclasses define typed getters/setters for their fields, while this
/// base class handles:
/// - Per-field timestamp tracking via [LWWMap]
/// - Merge operations
/// - JSON serialization
/// - Soft delete support
abstract class CrdtDocument<T extends CrdtDocument<T>> {
  /// Unique document identifier (UUID).
  final String id;

  /// The HLC used for generating timestamps.
  final HybridLogicalClock clock;

  /// Internal LWW Map storing all fields with timestamps.
  final LWWMap<String, Object?> _fields;

  /// Creates a new document with the given ID.
  CrdtDocument({
    required this.id,
    required this.clock,
  }) : _fields = LWWMap<String, Object?>(clock: clock);

  /// Creates a document from existing state (for deserialization).
  CrdtDocument.fromState({
    required this.id,
    required this.clock,
    required Map<String, CrdtFieldState> state,
  }) : _fields = LWWMap<String, Object?>(clock: clock) {
    for (final entry in state.entries) {
      _fields.mergeField(
        entry.key,
        value: entry.value.value,
        timestamp: entry.value.timestamp,
      );
    }
  }

  // ============================================================
  // Core Properties
  // ============================================================

  /// Returns true if this document has been soft-deleted.
  bool get isDeleted => getBool(CrdtFields.isDeleted) ?? false;

  /// Marks this document as deleted (soft delete).
  void delete() => setBool(CrdtFields.isDeleted, true);

  /// Restores a soft-deleted document.
  void restore() => setBool(CrdtFields.isDeleted, false);

  /// Returns the creation timestamp, or null if not set.
  DateTime? get createdAt {
    final ms = getInt(CrdtFields.createdAt);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Returns the last modification timestamp.
  HybridTimestamp? get modifiedAt => _fields.getTimestamp(CrdtFields.modifiedAt);

  /// Returns all field keys that have been set.
  Iterable<String> get fieldKeys => _fields.keys;

  // ============================================================
  // Field Accessors (Protected)
  // ============================================================

  /// Gets a string field value.
  String? getString(String key) => _fields.get(key) as String?;

  /// Sets a string field value.
  HybridTimestamp setString(String key, String? value) {
    final ts = _fields.set(key, value);
    _updateModified();
    return ts;
  }

  /// Gets an integer field value.
  int? getInt(String key) => _fields.get(key) as int?;

  /// Sets an integer field value.
  HybridTimestamp setInt(String key, int? value) {
    final ts = _fields.set(key, value);
    _updateModified();
    return ts;
  }

  /// Gets a double field value.
  double? getDouble(String key) => _fields.get(key) as double?;

  /// Sets a double field value.
  HybridTimestamp setDouble(String key, double? value) {
    final ts = _fields.set(key, value);
    _updateModified();
    return ts;
  }

  /// Gets a boolean field value.
  bool? getBool(String key) => _fields.get(key) as bool?;

  /// Sets a boolean field value.
  HybridTimestamp setBool(String key, bool? value) {
    final ts = _fields.set(key, value);
    _updateModified();
    return ts;
  }

  /// Gets a DateTime field value (stored as Unix milliseconds).
  DateTime? getDateTime(String key) {
    final ms = _fields.get(key) as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Sets a DateTime field value (stored as Unix milliseconds).
  HybridTimestamp setDateTime(String key, DateTime? value) {
    final ts = _fields.set(key, value?.millisecondsSinceEpoch);
    _updateModified();
    return ts;
  }

  /// Gets a list field value (stored as JSON-encoded string).
  List<E>? getList<E>(String key) {
    final json = _fields.get(key) as String?;
    if (json == null || json.isEmpty) return null;
    return (jsonDecode(json) as List).cast<E>();
  }

  /// Sets a list field value (stored as JSON-encoded string).
  HybridTimestamp setList<E>(String key, List<E>? value) {
    final ts = _fields.set(key, value != null ? jsonEncode(value) : null);
    _updateModified();
    return ts;
  }

  /// Gets a map field value (stored as JSON-encoded string).
  Map<String, E>? getMap<E>(String key) {
    final json = _fields.get(key) as String?;
    if (json == null || json.isEmpty) return null;
    return (jsonDecode(json) as Map<String, dynamic>).cast<String, E>();
  }

  /// Sets a map field value (stored as JSON-encoded string).
  HybridTimestamp setMap<E>(String key, Map<String, E>? value) {
    final ts = _fields.set(key, value != null ? jsonEncode(value) : null);
    _updateModified();
    return ts;
  }

  /// Gets a raw field value (for custom types).
  Object? getRaw(String key) => _fields.get(key);

  /// Sets a raw field value (for custom types).
  HybridTimestamp setRaw(String key, Object? value) {
    final ts = _fields.set(key, value);
    _updateModified();
    return ts;
  }

  /// Gets the timestamp for a specific field.
  HybridTimestamp? getFieldTimestamp(String key) => _fields.getTimestamp(key);

  /// Updates the modifiedAt timestamp.
  void _updateModified() {
    _fields.set(CrdtFields.modifiedAt, DateTime.now().millisecondsSinceEpoch);
  }

  // ============================================================
  // Merge Operations
  // ============================================================

  /// Merges another document's state into this one.
  ///
  /// For each field, the value with the higher timestamp wins.
  /// Returns the list of field keys that were updated.
  List<String> merge(T other) {
    if (other.id != id) {
      throw ArgumentError('Cannot merge documents with different IDs: $id vs ${other.id}');
    }
    return _fields.merge(other._fields);
  }

  /// Merges state from another document (copies all fields).
  ///
  /// Used for creating copies with inherited state.
  void mergeFrom(CrdtDocument other) {
    for (final key in other._fields.keys) {
      _fields.mergeField(
        key,
        value: other._fields.get(key),
        timestamp: other._fields.getTimestamp(key),
      );
    }
  }

  /// Merges a single field from raw state.
  ///
  /// Returns true if the field was updated.
  bool mergeField(String key, {required Object? value, required HybridTimestamp? timestamp}) {
    return _fields.mergeField(key, value: value, timestamp: timestamp);
  }

  // ============================================================
  // Serialization
  // ============================================================

  /// Converts the document to a JSON-serializable map.
  ///
  /// Format:
  /// ```json
  /// {
  ///   "id": "uuid",
  ///   "fields": {
  ///     "fieldName": {
  ///       "v": <value>,
  ///       "t": "timestamp-packed"
  ///     }
  ///   }
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    final fieldsJson = <String, dynamic>{};

    for (final key in _fields.keys) {
      final value = _fields.get(key);
      final timestamp = _fields.getTimestamp(key);

      fieldsJson[key] = {
        'v': value,
        't': timestamp?.pack(),
      };
    }

    return {
      'id': id,
      'fields': fieldsJson,
    };
  }

  /// Extracts field state from JSON for use with [fromState] constructor.
  static Map<String, CrdtFieldState> stateFromJson(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>? ?? {};
    final state = <String, CrdtFieldState>{};

    for (final entry in fields.entries) {
      final field = entry.value as Map<String, dynamic>;
      final timestampStr = field['t'] as String?;

      state[entry.key] = CrdtFieldState(
        value: field['v'],
        timestamp: timestampStr != null ? HybridTimestamp.parse(timestampStr) : null,
      );
    }

    return state;
  }

  /// Converts the document state to a compact format for Drift storage.
  ///
  /// Returns a JSON string containing all field states.
  String toCrdtState() {
    return jsonEncode(toJson()['fields']);
  }

  /// Creates field state map from Drift storage format.
  static Map<String, CrdtFieldState> stateFromCrdtState(String crdtState) {
    if (crdtState.isEmpty || crdtState == '{}') {
      return {};
    }

    final fields = jsonDecode(crdtState) as Map<String, dynamic>;
    final state = <String, CrdtFieldState>{};

    for (final entry in fields.entries) {
      final field = entry.value as Map<String, dynamic>;
      final timestampStr = field['t'] as String?;

      state[entry.key] = CrdtFieldState(
        value: field['v'],
        timestamp: timestampStr != null ? HybridTimestamp.parse(timestampStr) : null,
      );
    }

    return state;
  }

  /// Creates a copy of this document.
  ///
  /// Subclasses must implement this to return the correct type.
  T copyWith({String? id, HybridLogicalClock? clock});

  // ============================================================
  // Equality & Debug
  // ============================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrdtDocument && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType($id)';
}

/// Represents the state of a single CRDT field.
class CrdtFieldState {
  /// The field value.
  final Object? value;

  /// The timestamp when this value was set.
  final HybridTimestamp? timestamp;

  const CrdtFieldState({
    required this.value,
    required this.timestamp,
  });

  @override
  String toString() => 'CrdtFieldState($value @ $timestamp)';
}

/// Extension methods for working with CRDT documents.
extension CrdtDocumentExtensions<T extends CrdtDocument<T>> on T {
  /// Creates a clone of this document with a new ID.
  T duplicate(String newId) {
    final copy = copyWith(id: newId);
    copy.mergeFrom(this);
    // Reset the creation timestamp
    copy.setInt(CrdtFields.createdAt, DateTime.now().millisecondsSinceEpoch);
    return copy;
  }
}
