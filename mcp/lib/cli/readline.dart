/// Reusable terminal readline with arrow key, Home/End, and wrapping support.
library;

import 'dart:io';

import 'package:dart_console/dart_console.dart';

/// Provides readline-style line editing in raw terminal mode.
///
/// Supports arrow keys, Home/End, backspace/delete, and handles text
/// wrapping when input exceeds terminal width.
class TerminalReadline {
  final Console _console = Console();

  /// Terminal width in columns.
  int get windowWidth => _console.windowWidth;

  /// Terminal height in rows.
  int get windowHeight => _console.windowHeight;

  /// Reads a raw keypress from the terminal.
  Key readKey() => _console.readKey();

  /// Reads a line with arrow key / Home / End / backspace / delete support.
  /// Returns null if the user presses Ctrl+C.
  String? readLine(String prompt) {
    stdout.write(prompt);
    final width = _console.windowWidth;
    final buf = <int>[];
    var cursor = 0;
    var screenPos = prompt.length;

    stdin.echoMode = false;
    stdin.lineMode = false;

    try {
      while (true) {
        final key = _console.readKey();

        if (key.controlChar == ControlCharacter.enter) {
          stdout.writeln();
          return String.fromCharCodes(buf);
        } else if (key.controlChar == ControlCharacter.ctrlC) {
          stdout.writeln();
          return null;
        } else if (key.controlChar == ControlCharacter.backspace) {
          if (cursor > 0) {
            buf.removeAt(cursor - 1);
            cursor--;
            screenPos = _redraw(prompt, buf, cursor, width, screenPos);
          }
        } else if (key.controlChar == ControlCharacter.delete) {
          if (cursor < buf.length) {
            buf.removeAt(cursor);
            screenPos = _redraw(prompt, buf, cursor, width, screenPos);
          }
        } else if (key.controlChar == ControlCharacter.arrowLeft) {
          if (cursor > 0) {
            cursor--;
            screenPos = _redraw(prompt, buf, cursor, width, screenPos);
          }
        } else if (key.controlChar == ControlCharacter.arrowRight) {
          if (cursor < buf.length) {
            cursor++;
            screenPos = _redraw(prompt, buf, cursor, width, screenPos);
          }
        } else if (key.controlChar == ControlCharacter.home) {
          cursor = 0;
          screenPos = _redraw(prompt, buf, cursor, width, screenPos);
        } else if (key.controlChar == ControlCharacter.end) {
          cursor = buf.length;
          screenPos = _redraw(prompt, buf, cursor, width, screenPos);
        } else if (key.controlChar == ControlCharacter.none &&
            key.char.isNotEmpty) {
          final code = key.char.codeUnitAt(0);
          if (code >= 32) {
            buf.insert(cursor, code);
            cursor++;
            screenPos = _redraw(prompt, buf, cursor, width, screenPos);
          }
        }
      }
    } finally {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  /// Clears display, rewrites prompt + buffer, positions cursor.
  int _redraw(
      String prompt, List<int> buf, int cursor, int width, int screenPos) {
    final rowsUp = screenPos ~/ width;
    if (rowsUp > 0) stdout.write('\x1B[${rowsUp}A');
    stdout.write('\r');

    stdout.write('\x1B[J');
    stdout.write(prompt);
    stdout.write(String.fromCharCodes(buf));

    final endPos = prompt.length + buf.length;
    final targetPos = prompt.length + cursor;
    final rowsBack = (endPos ~/ width) - (targetPos ~/ width);
    if (rowsBack > 0) stdout.write('\x1B[${rowsBack}A');
    stdout.write('\x1B[${(targetPos % width) + 1}G');

    return targetPos;
  }
}
