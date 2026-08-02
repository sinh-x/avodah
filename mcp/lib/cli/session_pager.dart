/// Minimal read-only pager for `avo session history`.
///
/// Extracted from `session_commands.dart` (CQ-3 review finding) to keep each
/// CLI source file under the ~400 line guideline. Renders a window of lines
/// from [lines] and responds to:
/// - ↑ / ↓ — scroll one line
/// - Page Up / Page Down — scroll one page
/// - Home / End — jump to top / bottom
/// - `q`, `Esc`, `Ctrl+C` — quit
///
/// The pager is intentionally simple: it redraws the whole visible window on
/// each keypress rather than diffing, which keeps the code small and avoids
/// ANSI scroll-region tricks that don't survive all terminals.
library;

import 'dart:io';

import 'package:dart_console/dart_console.dart';

class SessionPager {
  final List<String> lines;
  final String filePath;
  final String deploymentId;

  SessionPager(this.lines, this.filePath, this.deploymentId);

  void run() {
    final console = Console();
    final height = console.windowHeight;
    // Reserve 2 lines for the status bar (top) and the help line (bottom).
    final visibleRows = height > 4 ? height - 3 : 1;
    final maxWidth = console.windowWidth;

    var topLine = 0;
    var needsRedraw = true;

    stdin.echoMode = false;
    stdin.lineMode = false;
    console.hideCursor();
    try {
      while (true) {
        if (needsRedraw) {
          _render(console, topLine, visibleRows, maxWidth);
          needsRedraw = false;
        }

        final key = console.readKey();

        if (key.controlChar == ControlCharacter.ctrlC ||
            key.controlChar == ControlCharacter.escape ||
            (key.controlChar == ControlCharacter.none &&
                key.char.toLowerCase() == 'q')) {
          // Clear the pager area before returning so the shell prompt isn't
          // left covered by stale log output.
          console.showCursor();
          stdout.write('\r\x1B[J');
          return;
        } else if (key.controlChar == ControlCharacter.arrowDown) {
          final maxTop = _maxTop(visibleRows);
          if (topLine < maxTop) {
            topLine++;
            needsRedraw = true;
          }
        } else if (key.controlChar == ControlCharacter.arrowUp) {
          if (topLine > 0) {
            topLine--;
            needsRedraw = true;
          }
        } else if (key.controlChar == ControlCharacter.pageDown) {
          final maxTop = _maxTop(visibleRows);
          final next = topLine + visibleRows;
          topLine = next > maxTop ? maxTop : next;
          needsRedraw = true;
        } else if (key.controlChar == ControlCharacter.pageUp) {
          final prev = topLine - visibleRows;
          topLine = prev < 0 ? 0 : prev;
          needsRedraw = true;
        } else if (key.controlChar == ControlCharacter.home) {
          topLine = 0;
          needsRedraw = true;
        } else if (key.controlChar == ControlCharacter.end) {
          topLine = _maxTop(visibleRows);
          needsRedraw = true;
        }
      }
    } finally {
      console.showCursor();
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  int _maxTop(int visibleRows) {
    if (lines.length <= visibleRows) return 0;
    return lines.length - visibleRows;
  }

  void _render(Console console, int topLine, int visibleRows, int maxWidth) {
    stdout.write('\r\x1B[J');

    // Status bar (line 1).
    final bottom = topLine + visibleRows > lines.length
        ? lines.length
        : topLine + visibleRows;
    final status = ' $deploymentId  ${bottom}/${lines.length}  $filePath';
    console.setForegroundColor(ConsoleColor.blue);
    stdout.writeln(_truncateForDisplay(status, maxWidth));
    console.resetColorAttributes();

    // Visible log lines.
    final end = topLine + visibleRows;
    for (var i = topLine; i < end && i < lines.length; i++) {
      stdout.writeln(_truncateForDisplay(lines[i], maxWidth));
    }

    // Pad the window to visibleRows so the help line stays at the bottom.
    final rendered = (end > lines.length ? lines.length : end) - topLine;
    for (var i = rendered; i < visibleRows; i++) {
      stdout.writeln('');
    }

    // Help line.
    console.setForegroundColor(ConsoleColor.brightBlack);
    stdout.write(
        '↑/↓ scroll · PgUp/PgDn · Home/End · q/Esc quit');
    console.resetColorAttributes();
  }

  /// Truncates [text] to [maxWidth] display columns, appending an ellipsis
  /// when truncated. Treats each code unit as one column, which is correct
  /// for the ASCII-heavy session logs and simple enough for the pager.
  static String _truncateForDisplay(String text, int maxWidth) {
    if (maxWidth <= 0) return '';
    if (text.length <= maxWidth) return text;
    if (maxWidth <= 1) return '\u2026';
    return '${text.substring(0, maxWidth - 1)}\u2026';
  }
}