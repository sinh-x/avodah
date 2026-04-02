/// Last-Writer-Wins Set (LWW-Set) CRDT implementation.
///
/// A set where each element has associated add and remove timestamps.
/// An element is present if its add timestamp is greater than its remove timestamp.
///
/// This is also known as an LWW-Element-Set and is useful for tracking
/// collections where elements can be added and removed multiple times.
library;

import 'hlc.dart';

/// Tracks the add/remove timestamps for a single element.
class _ElementState {
  HybridTimestamp? addTimestamp;
  HybridTimestamp? removeTimestamp;

  _ElementState({this.addTimestamp, this.removeTimestamp});

  /// Returns true if the element is currently in the set.
  bool get isPresent {
    if (addTimestamp == null) return false;
    if (removeTimestamp == null) return true;
    return addTimestamp! > removeTimestamp!;
  }

  /// Merges with another element state.
  void merge(_ElementState other) {
    // Take the max add timestamp
    if (other.addTimestamp != null) {
      if (addTimestamp == null || other.addTimestamp! > addTimestamp!) {
        addTimestamp = other.addTimestamp;
      }
    }

    // Take the max remove timestamp
    if (other.removeTimestamp != null) {
      if (removeTimestamp == null || other.removeTimestamp! > removeTimestamp!) {
        removeTimestamp = other.removeTimestamp;
      }
    }
  }

  _ElementState copy() {
    return _ElementState(
      addTimestamp: addTimestamp,
      removeTimestamp: removeTimestamp,
    );
  }

  @override
  String toString() => '_ElementState(add: $addTimestamp, remove: $removeTimestamp)';
}

/// A Last-Writer-Wins Set that tracks elements with add/remove timestamps.
///
/// Elements are present if their add timestamp > remove timestamp.
/// This allows elements to be added and removed multiple times with
/// correct merge semantics.
///
/// Usage:
/// ```dart
/// final clock = HybridLogicalClock(nodeId: 'node-1');
/// final tags = LWWSet<String>(clock: clock);
///
/// tags.add('urgent');
/// tags.add('work');
/// print(tags.contains('urgent')); // true
///
/// tags.remove('urgent');
/// print(tags.contains('urgent')); // false
///
/// // Merge with remote state
/// tags.merge(remoteTags);
/// ```
class LWWSet<E> {
  /// The HLC used for generating timestamps.
  final HybridLogicalClock clock;

  /// Map of elements to their add/remove state.
  final Map<E, _ElementState> _elements = {};

  /// Creates an empty LWW Set.
  LWWSet({required this.clock});

  /// Creates a set from existing state (for deserialization).
  LWWSet.fromState({
    required this.clock,
    required Map<E, ({HybridTimestamp? add, HybridTimestamp? remove})> state,
  }) {
    for (final entry in state.entries) {
      _elements[entry.key] = _ElementState(
        addTimestamp: entry.value.add,
        removeTimestamp: entry.value.remove,
      );
    }
  }

  /// Returns true if [element] is currently in the set.
  bool contains(E element) {
    return _elements[element]?.isPresent ?? false;
  }

  /// Returns all elements currently in the set.
  Set<E> get elements {
    return _elements.entries
        .where((e) => e.value.isPresent)
        .map((e) => e.key)
        .toSet();
  }

  /// Returns the number of elements currently in the set.
  int get length => elements.length;

  /// Returns true if the set is empty.
  bool get isEmpty => elements.isEmpty;

  /// Returns true if the set is not empty.
  bool get isNotEmpty => elements.isNotEmpty;

  /// Adds an element to the set.
  ///
  /// Returns the timestamp of the add operation.
  HybridTimestamp add(E element) {
    final ts = clock.now();
    _elements[element] ??= _ElementState();
    _elements[element]!.addTimestamp = ts;
    return ts;
  }

  /// Removes an element from the set.
  ///
  /// Returns the timestamp of the remove operation.
  HybridTimestamp remove(E element) {
    final ts = clock.now();
    _elements[element] ??= _ElementState();
    _elements[element]!.removeTimestamp = ts;
    return ts;
  }

  /// Adds all elements from [iterable] to the set.
  void addAll(Iterable<E> iterable) {
    for (final e in iterable) {
      add(e);
    }
  }

  /// Removes all elements in [iterable] from the set.
  void removeAll(Iterable<E> iterable) {
    for (final e in iterable) {
      remove(e);
    }
  }

  /// Merges with another LWW Set.
  ///
  /// Returns the set of elements whose presence changed.
  Set<E> merge(LWWSet<E> other) {
    final changed = <E>{};

    for (final entry in other._elements.entries) {
      final element = entry.key;
      final otherState = entry.value;

      final wasPresentBefore = contains(element);

      _elements[element] ??= _ElementState();
      _elements[element]!.merge(otherState);

      final isPresentAfter = contains(element);

      if (wasPresentBefore != isPresentAfter) {
        changed.add(element);
      }

      // Update clock with remote timestamps
      if (otherState.addTimestamp != null) {
        clock.receive(otherState.addTimestamp!);
      }
      if (otherState.removeTimestamp != null) {
        clock.receive(otherState.removeTimestamp!);
      }
    }

    return changed;
  }

  /// Merges a single element's state.
  ///
  /// Returns true if the element's presence changed.
  bool mergeElement(
    E element, {
    HybridTimestamp? addTimestamp,
    HybridTimestamp? removeTimestamp,
  }) {
    final wasPresentBefore = contains(element);

    _elements[element] ??= _ElementState();
    _elements[element]!.merge(_ElementState(
      addTimestamp: addTimestamp,
      removeTimestamp: removeTimestamp,
    ));

    final isPresentAfter = contains(element);

    // Update clock
    if (addTimestamp != null) {
      clock.receive(addTimestamp);
    }
    if (removeTimestamp != null) {
      clock.receive(removeTimestamp);
    }

    return wasPresentBefore != isPresentAfter;
  }

  /// Returns the state as a map for serialization.
  Map<E, ({HybridTimestamp? add, HybridTimestamp? remove})> toState() {
    return Map.fromEntries(
      _elements.entries.map(
        (e) => MapEntry(
          e.key,
          (add: e.value.addTimestamp, remove: e.value.removeTimestamp),
        ),
      ),
    );
  }

  /// Returns timestamps for a specific element (for debugging/sync).
  ({HybridTimestamp? add, HybridTimestamp? remove})? getElementState(E element) {
    final state = _elements[element];
    if (state == null) return null;
    return (add: state.addTimestamp, remove: state.removeTimestamp);
  }

  /// Creates a copy of this set.
  LWWSet<E> copy() {
    final copied = LWWSet<E>(clock: clock);
    for (final entry in _elements.entries) {
      copied._elements[entry.key] = entry.value.copy();
    }
    return copied;
  }

  @override
  String toString() => 'LWWSet(${elements.join(', ')})';
}
