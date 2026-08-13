/// Drives the live attach loop for `avo session attach`.
///
/// Connects to the pa-platform SSE stream (`GET /api/sessions/:id/stream`)
/// for real-time session events, renders each event, and detaches on
/// Ctrl+C / Escape. File-based `activity.jsonl` reading is dropped —
/// WebSocket sessions (the primary interactive path) are streamed via
/// the API. Deploy sessions return 404 from the SSE endpoint (no child
/// process to stream), which is surfaced as a clear message.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:http/http.dart' as http;

import 'format.dart';

class SessionAttachRunner {
  final String deploymentId;
  final String sessionId;
  final String apiBaseUrl;
  final http.Client httpClient;

  SessionAttachRunner({
    required this.deploymentId,
    required this.sessionId,
    required this.apiBaseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Future<void> run() async {
    final console = Console();
    final hasTty = stdin.hasTerminal;

    var rawMode = false;
    if (hasTty) {
      try {
        stdin.echoMode = false;
        stdin.lineMode = false;
        rawMode = true;
      } catch (_) {
        // No TTY control available (CI, pipes, test runner) — skip raw mode.
        rawMode = false;
      }
    }

    var detached = false;
    var ended = false;

    // Keyboard watcher — cancelled via a Completer so the loop exits
    // before terminal cleanup.
    final keyboardCancel = Completer<void>();
    Future<void> keyboardWatcher() async {
      if (!rawMode) return;
      while (!keyboardCancel.isCompleted) {
        final key = console.readKey();
        if (keyboardCancel.isCompleted) return;
        if (key.controlChar == ControlCharacter.ctrlC ||
            key.controlChar == ControlCharacter.escape) {
          detached = true;
          return;
        }
      }
    }

    // SSE stream from GET /api/sessions/:id/stream
    final streamUrl = '$apiBaseUrl/api/sessions/$sessionId/stream';
    final sseCompleter = Completer<void>();
    late http.StreamedResponse response;

    try {
      final request = http.Request('GET', Uri.parse(streamUrl));
      response = await httpClient.send(request);
    } catch (e) {
      if (rawMode) {
        try {
          stdin.echoMode = true;
          stdin.lineMode = true;
        } catch (_) {}
      }
      print(sectionHeader('ATTACH ERROR'));
      print('');
      print('Failed to connect to pa-platform SSE stream.');
      print('');
      print(hintPlain('$e'));
      return;
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      if (rawMode) {
        try {
          stdin.echoMode = true;
          stdin.lineMode = true;
        } catch (_) {}
      }
      print(sectionHeader('ATTACH ERROR'));
      print('');
      print('SSE stream returned HTTP ${response.statusCode}.');
      String? errorMsg;
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        errorMsg = json['error'] as String?;
      } catch (_) {}
      if (errorMsg != null && errorMsg.contains('Deploy sessions')) {
        print('');
        print(hintPlain(
            'Deploy sessions (started via `avo session start`) do not support '
            'live streaming. WebSocket sessions started from the phone app '
            'are the primary interactive path.'));
      } else {
        print('');
        print(hintPlain(errorMsg ?? body));
      }
      return;
    }

    final sseSub = response.stream.listen(
      (List<int> chunk) {
        final text = utf8.decode(chunk);
        _parseSseChunk(text, (eventType, data) {
          if (eventType == 'event' || eventType == 'ready') {
            // 'ready' is a no-op confirmation; 'event' carries the payload.
            if (eventType == 'ready') return;
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              _renderEvent(json);
              if (json['type'] == 'end') {
                ended = true;
                if (!sseCompleter.isCompleted) sseCompleter.complete();
              }
            } catch (_) {
              stdout.writeln(data);
            }
          } else if (eventType == 'end') {
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              _renderEvent(json);
            } catch (_) {
              stdout.writeln(data);
            }
            ended = true;
            if (!sseCompleter.isCompleted) sseCompleter.complete();
          } else if (eventType == 'error') {
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final msg = json['message'] as String? ?? data;
              stderr.writeln('Error: $msg');
            } catch (_) {
              stderr.writeln(data);
            }
            ended = true;
            if (!sseCompleter.isCompleted) sseCompleter.complete();
          }
        });
      },
      onDone: () {
        if (!sseCompleter.isCompleted) {
          ended = true;
          sseCompleter.complete();
        }
      },
      onError: (e) {
        stderr.writeln('SSE stream error: $e');
        if (!sseCompleter.isCompleted) {
          ended = true;
          sseCompleter.complete();
        }
      },
    );

    final keyboardFuture = keyboardWatcher();

    await Future.any<Object?>([
      keyboardFuture.then((_) => 'detach'),
      sseCompleter.future.then((_) => 'end'),
    ]);

    detached = detached || ended;
    if (!keyboardCancel.isCompleted) keyboardCancel.complete();
    await sseSub.cancel();

    if (rawMode) {
      try {
        stdin.echoMode = true;
        stdin.lineMode = true;
      } catch (_) {
        // Best-effort cleanup — ignore if TTY control is unavailable.
      }
    }

    stdout.writeln('');
    if (ended) {
      print(sectionHeader('SESSION END'));
      print('');
      print('Session $deploymentId has ended.');
    } else {
      print(sectionHeader('DETACHED'));
      print('');
      print('Detached from $deploymentId. The session is still running.');
      print(hintPlain('Use `avo session list` to check its status or '
          '`avo session stop $deploymentId` to terminate it.'));
    }
  }

  void _renderEvent(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final data = json['data'] as Map<String, dynamic>?;
    final timestamp = json['timestamp'] as String? ?? '';

    switch (type) {
      case 'session-id':
        final sid = json['sessionId'] as String? ?? '';
        stdout.writeln('[$timestamp] session-id: $sid');
        break;
      case 'event':
        if (data == null) return;
        final kind = data['kind'] as String? ?? 'event';
        final body = data['body'] as String? ?? '';
        final source = data['source'] as String? ?? '';
        final prefix = source.isNotEmpty ? '[$source] ' : '';
        stdout.writeln('[$timestamp] $prefix$kind: $body');
        break;
      case 'error':
        final msg = json['message'] as String? ?? 'Unknown error';
        stdout.writeln('[$timestamp] error: $msg');
        break;
      case 'end':
        if (data != null) {
          final exitCode = data['exitCode'];
          final reason = data['reason'] as String?;
          if (exitCode != null) {
            stdout.writeln('[$timestamp] end (exitCode: $exitCode)');
          } else if (reason != null) {
            stdout.writeln('[$timestamp] end (reason: $reason)');
          } else {
            stdout.writeln('[$timestamp] end');
          }
        } else {
          stdout.writeln('[$timestamp] end');
        }
        break;
      default:
        stdout.writeln('[$timestamp] $type: ${jsonEncode(data ?? {})}');
    }
  }

  /// Parse a chunk of SSE text and call [onEvent] for each `event: … / data: …` pair.
  void _parseSseChunk(
      String chunk, void Function(String eventType, String data) onEvent) {
    final lines = chunk.split('\n');
    String? currentEventType;
    final dataLines = <String>[];

    for (final line in lines) {
      if (line.isEmpty) {
        // Event boundary — flush.
        if (currentEventType != null && dataLines.isNotEmpty) {
          onEvent(currentEventType, dataLines.join('\n'));
        }
        currentEventType = null;
        dataLines.clear();
        continue;
      }
      if (line.startsWith('event:')) {
        currentEventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      }
    }
    // Flush any trailing event without a blank-line terminator.
    if (currentEventType != null && dataLines.isNotEmpty) {
      onEvent(currentEventType, dataLines.join('\n'));
    }
  }
}