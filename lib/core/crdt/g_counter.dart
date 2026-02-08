/// Grow-only Counter (G-Counter) CRDT implementation.
///
/// A distributed counter where each node maintains its own count.
/// The total value is the sum of all node counts.
/// Merge takes the maximum of each node's count.
///
/// This counter can only be incremented, never decremented.
/// For a counter that supports both, see PN-Counter.
library;

import 'dart:math';

/// A Grow-only Counter that supports distributed increments.
///
/// Each node in the system has its own counter, and the total
/// value is the sum of all node counters. This ensures that
/// concurrent increments from different nodes are never lost.
///
/// Usage:
/// ```dart
/// final counter = GCounter(nodeId: 'node-1');
///
/// counter.increment();
/// counter.increment(5);
/// print(counter.value); // 6
///
/// // Merge with remote counter
/// counter.merge(remoteCounter);
/// ```
class GCounter {
  /// Unique identifier for this node.
  final String nodeId;

  /// Map of node IDs to their counts.
  final Map<String, int> _counts;

  /// Creates a new G-Counter for the given node.
  GCounter({required this.nodeId}) : _counts = {nodeId: 0};

  /// Creates a G-Counter from existing state (for deserialization).
  GCounter.fromState({
    required this.nodeId,
    required Map<String, int> state,
  }) : _counts = Map.from(state) {
    // Ensure this node has an entry
    _counts[nodeId] ??= 0;
  }

  /// Returns the total value (sum of all node counts).
  int get value => _counts.values.fold(0, (a, b) => a + b);

  /// Returns this node's contribution to the counter.
  int get localValue => _counts[nodeId] ?? 0;

  /// Increments the counter by [amount] (default: 1).
  ///
  /// Throws [ArgumentError] if amount is negative.
  void increment([int amount = 1]) {
    if (amount < 0) {
      throw ArgumentError('G-Counter can only be incremented, not decremented');
    }
    _counts[nodeId] = (_counts[nodeId] ?? 0) + amount;
  }

  /// Merges with another G-Counter.
  ///
  /// For each node, takes the maximum count.
  /// Returns true if this counter's value changed.
  bool merge(GCounter other) {
    final oldValue = value;

    for (final entry in other._counts.entries) {
      final currentCount = _counts[entry.key] ?? 0;
      _counts[entry.key] = max(currentCount, entry.value);
    }

    return value != oldValue;
  }

  /// Merges with raw state (map of node IDs to counts).
  ///
  /// Returns true if this counter's value changed.
  bool mergeState(Map<String, int> state) {
    final oldValue = value;

    for (final entry in state.entries) {
      final currentCount = _counts[entry.key] ?? 0;
      _counts[entry.key] = max(currentCount, entry.value);
    }

    return value != oldValue;
  }

  /// Returns the internal state for serialization.
  Map<String, int> toState() => Map.unmodifiable(_counts);

  /// Creates a copy of this counter.
  GCounter copy() {
    return GCounter.fromState(nodeId: nodeId, state: _counts);
  }

  @override
  String toString() => 'GCounter($value, nodes: ${_counts.length})';
}

/// A Positive-Negative Counter (PN-Counter) that supports both increment and decrement.
///
/// Internally uses two G-Counters: one for increments, one for decrements.
/// The value is the difference between them.
///
/// Usage:
/// ```dart
/// final counter = PNCounter(nodeId: 'node-1');
///
/// counter.increment(10);
/// counter.decrement(3);
/// print(counter.value); // 7
/// ```
class PNCounter {
  /// Counter for positive increments.
  final GCounter _positive;

  /// Counter for negative increments (decrements).
  final GCounter _negative;

  /// Creates a new PN-Counter for the given node.
  PNCounter({required String nodeId})
      : _positive = GCounter(nodeId: nodeId),
        _negative = GCounter(nodeId: nodeId);

  /// Creates a PN-Counter from existing state (for deserialization).
  PNCounter.fromState({
    required String nodeId,
    required Map<String, int> positive,
    required Map<String, int> negative,
  })  : _positive = GCounter.fromState(nodeId: nodeId, state: positive),
        _negative = GCounter.fromState(nodeId: nodeId, state: negative);

  /// Returns the current value (positive - negative).
  int get value => _positive.value - _negative.value;

  /// Returns the node ID.
  String get nodeId => _positive.nodeId;

  /// Increments the counter by [amount] (default: 1).
  void increment([int amount = 1]) {
    if (amount < 0) {
      throw ArgumentError('Use decrement() for negative values');
    }
    _positive.increment(amount);
  }

  /// Decrements the counter by [amount] (default: 1).
  void decrement([int amount = 1]) {
    if (amount < 0) {
      throw ArgumentError('Use increment() for negative values');
    }
    _negative.increment(amount);
  }

  /// Merges with another PN-Counter.
  ///
  /// Returns true if this counter's value changed.
  bool merge(PNCounter other) {
    final oldValue = value;
    _positive.merge(other._positive);
    _negative.merge(other._negative);
    return value != oldValue;
  }

  /// Merges with raw state.
  ///
  /// Returns true if this counter's value changed.
  bool mergeState({
    required Map<String, int> positive,
    required Map<String, int> negative,
  }) {
    final oldValue = value;
    _positive.mergeState(positive);
    _negative.mergeState(negative);
    return value != oldValue;
  }

  /// Returns the internal state for serialization.
  ({Map<String, int> positive, Map<String, int> negative}) toState() {
    return (positive: _positive.toState(), negative: _negative.toState());
  }

  /// Creates a copy of this counter.
  PNCounter copy() {
    return PNCounter.fromState(
      nodeId: nodeId,
      positive: _positive.toState(),
      negative: _negative.toState(),
    );
  }

  @override
  String toString() => 'PNCounter($value)';
}
