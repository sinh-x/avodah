/// Last-Writer-Wins Register (LWW-Register) CRDT implementation.
///
/// A register that stores a single value with an associated timestamp.
/// On merge, the value with the highest timestamp wins.
///
/// This is the simplest CRDT for storing mutable values and forms
/// the building block for more complex data structures.
library;

import 'hlc.dart';

/// A Last-Writer-Wins Register that stores a single value.
///
/// The register maintains a value and its associated timestamp.
/// When merging with another register, the value with the higher
/// timestamp is kept.
///
/// Usage:
/// ```dart
/// final clock = HybridLogicalClock(nodeId: 'node-1');
/// final register = LWWRegister<String>(clock: clock);
///
/// register.set('hello');
/// print(register.value); // 'hello'
///
/// // Merge with remote state
/// final remoteRegister = LWWRegister<String>.fromState(
///   value: 'world',
///   timestamp: remoteTimestamp,
///   clock: clock,
/// );
/// register.merge(remoteRegister);
/// ```
class LWWRegister<T> {
  /// The HLC used for generating timestamps.
  final HybridLogicalClock clock;

  /// Current value of the register.
  T? _value;

  /// Timestamp of the last write.
  HybridTimestamp? _timestamp;

  /// Creates an empty register.
  LWWRegister({required this.clock});

  /// Creates a register with initial state (for deserialization/merging).
  LWWRegister.fromState({
    required T? value,
    required HybridTimestamp? timestamp,
    required this.clock,
  })  : _value = value,
        _timestamp = timestamp;

  /// Returns the current value, or null if never set.
  T? get value => _value;

  /// Returns the timestamp of the last write, or null if never set.
  HybridTimestamp? get timestamp => _timestamp;

  /// Returns true if the register has been set at least once.
  bool get hasValue => _timestamp != null;

  /// Sets the value, generating a new timestamp.
  ///
  /// Returns the new timestamp.
  HybridTimestamp set(T value) {
    _timestamp = clock.now();
    _value = value;
    return _timestamp!;
  }

  /// Merges with another register, keeping the value with the higher timestamp.
  ///
  /// Returns true if this register's value was updated.
  bool merge(LWWRegister<T> other) {
    // If other has no value, nothing to merge
    if (other._timestamp == null) {
      return false;
    }

    // If we have no value, take other's
    if (_timestamp == null) {
      _value = other._value;
      _timestamp = other._timestamp;
      clock.receive(other._timestamp!);
      return true;
    }

    // Compare timestamps
    if (other._timestamp! > _timestamp!) {
      _value = other._value;
      _timestamp = other._timestamp;
      clock.receive(other._timestamp!);
      return true;
    }

    // Our timestamp is higher or equal, keep our value
    // But still update clock if other's timestamp is newer
    if (other._timestamp!.physicalTime > _timestamp!.physicalTime) {
      clock.receive(other._timestamp!);
    }
    return false;
  }

  /// Merges with raw state (value + timestamp).
  ///
  /// Useful when receiving data from storage or network.
  /// Returns true if this register's value was updated.
  bool mergeState({required T? value, required HybridTimestamp? timestamp}) {
    if (timestamp == null) {
      return false;
    }

    if (_timestamp == null || timestamp > _timestamp!) {
      _value = value;
      _timestamp = timestamp;
      clock.receive(timestamp);
      return true;
    }

    return false;
  }

  /// Creates a copy of this register's state.
  LWWRegister<T> copy() {
    return LWWRegister<T>.fromState(
      value: _value,
      timestamp: _timestamp,
      clock: clock,
    );
  }

  @override
  String toString() => 'LWWRegister($_value @ $_timestamp)';
}

/// A LWW Register that tracks multiple fields as a map.
///
/// Each field is independently versioned, allowing partial updates
/// and fine-grained conflict resolution.
///
/// Usage:
/// ```dart
/// final clock = HybridLogicalClock(nodeId: 'node-1');
/// final doc = LWWMap<String, dynamic>(clock: clock);
///
/// doc.set('title', 'My Task');
/// doc.set('done', false);
///
/// // Later...
/// doc.set('done', true);
/// ```
class LWWMap<K, V> {
  /// The HLC used for generating timestamps.
  final HybridLogicalClock clock;

  /// Map of field names to their LWW registers.
  final Map<K, LWWRegister<V>> _fields = {};

  /// Creates an empty LWW Map.
  LWWMap({required this.clock});

  /// Returns the value for [key], or null if not set.
  V? get(K key) => _fields[key]?.value;

  /// Returns the timestamp for [key], or null if not set.
  HybridTimestamp? getTimestamp(K key) => _fields[key]?.timestamp;

  /// Returns true if [key] has been set.
  bool containsKey(K key) => _fields[key]?.hasValue ?? false;

  /// Returns all keys that have been set.
  Iterable<K> get keys => _fields.keys.where((k) => _fields[k]!.hasValue);

  /// Sets the value for [key], generating a new timestamp.
  HybridTimestamp set(K key, V value) {
    _fields[key] ??= LWWRegister<V>(clock: clock);
    return _fields[key]!.set(value);
  }

  /// Merges a single field from remote state.
  ///
  /// Returns true if the field was updated.
  bool mergeField(K key, {required V? value, required HybridTimestamp? timestamp}) {
    if (timestamp == null) return false;

    _fields[key] ??= LWWRegister<V>(clock: clock);
    return _fields[key]!.mergeState(value: value, timestamp: timestamp);
  }

  /// Merges with another LWW Map.
  ///
  /// Returns list of keys that were updated.
  List<K> merge(LWWMap<K, V> other) {
    final updated = <K>[];

    for (final key in other._fields.keys) {
      final otherReg = other._fields[key]!;
      if (otherReg.hasValue) {
        _fields[key] ??= LWWRegister<V>(clock: clock);
        if (_fields[key]!.merge(otherReg)) {
          updated.add(key);
        }
      }
    }

    return updated;
  }

  /// Returns the state as a map of {key: {value, timestamp}}.
  Map<K, ({V? value, HybridTimestamp? timestamp})> toState() {
    return Map.fromEntries(
      _fields.entries.where((e) => e.value.hasValue).map(
            (e) => MapEntry(e.key, (value: e.value.value, timestamp: e.value.timestamp)),
          ),
    );
  }

  @override
  String toString() {
    final entries = _fields.entries
        .where((e) => e.value.hasValue)
        .map((e) => '${e.key}: ${e.value.value}')
        .join(', ');
    return 'LWWMap({$entries})';
  }
}
