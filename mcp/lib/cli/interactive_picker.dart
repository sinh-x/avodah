/// Interactive fuzzy picker for terminal selection.
library;

import 'dart:io';
import 'dart:math';

import 'package:dart_console/dart_console.dart';

/// A single item in the interactive picker.
class PickerItem<T> {
  /// The underlying value returned on selection.
  final T value;

  /// Formatted display line shown in the list.
  final String displayLine;

  /// Lowercased concatenated searchable text for filtering.
  final String searchText;

  PickerItem({
    required this.value,
    required this.displayLine,
    required this.searchText,
  });
}

/// A generic interactive picker that presents a filterable list in the terminal.
///
/// Users type to filter, use arrow keys to navigate, Enter to select,
/// and Esc/Ctrl+C to cancel.
class InteractivePicker<T> {
  final List<PickerItem<T>> items;
  final String prompt;

  InteractivePicker({
    required this.items,
    this.prompt = 'Search tasks',
  });

  /// Runs the interactive picker loop. Returns the selected value or null
  /// if cancelled. Returns null immediately if stdin is not a TTY.
  T? pick() {
    if (!stdin.hasTerminal) return null;

    final console = Console();
    final query = <int>[];
    var selectedIndex = 0;
    var scrollOffset = 0;
    var queryDirty = true;
    var filtered = items;

    stdin.echoMode = false;
    stdin.lineMode = false;

    try {
      while (true) {
        // Recompute query string for display
        final queryStr = String.fromCharCodes(query).toLowerCase();

        // Filter items only when query changed
        if (queryDirty) {
          filtered = queryStr.isEmpty
              ? items
              : items.where((item) => item.searchText.contains(queryStr)).toList();
          queryDirty = false;
        }

        // Clamp selection
        if (filtered.isEmpty) {
          selectedIndex = 0;
        } else {
          selectedIndex = selectedIndex.clamp(0, filtered.length - 1);
        }

        // Calculate visible window
        final maxVisible = min(console.windowHeight - 4, 15);
        final visibleCount = min(filtered.length, maxVisible);

        // Adjust scroll offset to keep selection visible
        if (selectedIndex < scrollOffset) {
          scrollOffset = selectedIndex;
        } else if (selectedIndex >= scrollOffset + visibleCount) {
          scrollOffset = selectedIndex - visibleCount + 1;
        }

        // Render
        _render(
          console: console,
          query: queryStr,
          filtered: filtered,
          totalCount: items.length,
          selectedIndex: selectedIndex,
          scrollOffset: scrollOffset,
          visibleCount: visibleCount,
        );

        // Read key
        final key = console.readKey();

        if (key.controlChar == ControlCharacter.enter) {
          _clearDisplay(visibleCount + 2);
          if (filtered.isEmpty) return null;
          return filtered[selectedIndex].value;
        } else if (key.controlChar == ControlCharacter.escape ||
            key.controlChar == ControlCharacter.ctrlC) {
          _clearDisplay(visibleCount + 2);
          return null;
        } else if (key.controlChar == ControlCharacter.arrowUp) {
          if (selectedIndex > 0) selectedIndex--;
        } else if (key.controlChar == ControlCharacter.arrowDown) {
          if (filtered.isNotEmpty && selectedIndex < filtered.length - 1) {
            selectedIndex++;
          }
        } else if (key.controlChar == ControlCharacter.backspace) {
          if (query.isNotEmpty) {
            query.removeLast();
            selectedIndex = 0;
            scrollOffset = 0;
            queryDirty = true;
          }
        } else if (key.controlChar == ControlCharacter.none &&
            key.char.isNotEmpty) {
          final code = key.char.codeUnitAt(0);
          if (code >= 32) {
            query.add(code);
            selectedIndex = 0;
            scrollOffset = 0;
            queryDirty = true;
          }
        }
      }
    } finally {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  /// Renders the picker UI.
  void _render({
    required Console console,
    required String query,
    required List<PickerItem<T>> filtered,
    required int totalCount,
    required int selectedIndex,
    required int scrollOffset,
    required int visibleCount,
  }) {
    // Move cursor to start and clear
    stdout.write('\r\x1B[J');

    // Search prompt
    stdout.writeln('$prompt: $query\x1B[K');

    // Count line
    final countText = filtered.length == totalCount
        ? '  $totalCount tasks'
        : '  ${filtered.length} of $totalCount tasks';
    stdout.writeln(countText);

    // Task list
    if (filtered.isEmpty) {
      stdout.writeln('  (no matching tasks)');
    } else {
      final end = min(scrollOffset + visibleCount, filtered.length);
      for (var i = scrollOffset; i < end; i++) {
        final item = filtered[i];
        if (i == selectedIndex) {
          // Reverse video for selected row
          stdout.writeln('\x1B[7m${item.displayLine}\x1B[0m');
        } else {
          stdout.writeln(item.displayLine);
        }
      }
    }

    // Move cursor back to top of rendered area
    final linesRendered = 2 + (filtered.isEmpty ? 1 : visibleCount);
    stdout.write('\x1B[${linesRendered}A');
    // Position cursor at end of query text
    stdout.write('\r\x1B[${prompt.length + 2 + query.length}C');
  }

  /// Clears the picker display area before returning.
  void _clearDisplay(int lines) {
    stdout.write('\r\x1B[J');
  }
}
