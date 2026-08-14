import 'dart:async';
import 'dart:convert';

import 'package:avodah_mcp/cli/session_attach_runner.dart';
import 'package:test/test.dart';

/// Creates a `Stream<List<int>>` from a list of byte chunks, ensuring the
/// stream type is `List<int>` (not `Uint8List`) so it matches the
/// `StreamTransformer<List<int>, SseEvent>` contract.
Stream<List<int>> _byteStream(List<List<int>> chunks) {
  final controller = StreamController<List<int>>();
  for (final c in chunks) {
    controller.add(c);
  }
  controller.close();
  return controller.stream;
}

/// Convenience: split a string into 1-byte chunks for fragmentation tests.
Stream<List<int>> _oneByteAtATime(String text) {
  final bytes = utf8.encode(text);
  final controller = StreamController<List<int>>();
  for (final b in bytes) {
    controller.add([b]);
  }
  controller.close();
  return controller.stream;
}

void main() {
  group('SseEventTransformer', () {
    test('parses a complete event from a single chunk', () async {
      final events = await _byteStream([
        utf8.encode('event: event\ndata: {"type":"event","data":{"body":"hi"}}'
            '\n\n'),
      ]).transform<SseEvent>(SessionAttachRunner.sseEventTransformer).toList();
      expect(events, hasLength(1));
      expect(events[0].eventType, 'event');
      expect(events[0].data, '{"type":"event","data":{"body":"hi"}}');
    });

    test('handles 1-byte fragmentation without data loss (NFR6/AC13)',
        () async {
      final events = await _oneByteAtATime('event: event\ndata: hello\n\n')
          .transform<SseEvent>(SessionAttachRunner.sseEventTransformer)
          .toList();
      expect(events, hasLength(1));
      expect(events[0].eventType, 'event');
      expect(events[0].data, 'hello');
    });

    test('handles split multi-byte UTF-8 characters across chunks (AC13)',
        () async {
      const full = 'event: event\ndata: café\n\n';
      final bytes = utf8.encode(full);
      // 'é' is U+00E9 → UTF-8 [0xC3, 0xA9]. Split between the two bytes.
      final splitAt = utf8.encode('event: event\ndata: caf').length;
      final events = await _byteStream([
        bytes.sublist(0, splitAt),
        bytes.sublist(splitAt),
      ]).transform<SseEvent>(SessionAttachRunner.sseEventTransformer).toList();
      expect(events, hasLength(1));
      expect(events[0].eventType, 'event');
      expect(events[0].data, 'café');
    });

    test('handles partial SSE line split across chunks', () async {
      final events = await _byteStream([
        utf8.encode('event: ev'),
        utf8.encode('ent\ndata: hi\n\n'),
      ]).transform<SseEvent>(SessionAttachRunner.sseEventTransformer).toList();
      expect(events, hasLength(1));
      expect(events[0].eventType, 'event');
      expect(events[0].data, 'hi');
    });

    test('handles multiple events in a single chunk', () async {
      final events = await _byteStream([
        utf8.encode('event: ready\ndata: {}\n\n'
            'event: event\ndata: {"type":"event"}\n\n'),
      ]).transform<SseEvent>(SessionAttachRunner.sseEventTransformer).toList();
      expect(events, hasLength(2));
      expect(events[0].eventType, 'ready');
      expect(events[1].eventType, 'event');
    });

    test('handles CRLF line endings', () async {
      final events = await _byteStream([
        utf8.encode('event: event\r\ndata: hi\r\n\r\n'),
      ]).transform<SseEvent>(SessionAttachRunner.sseEventTransformer).toList();
      expect(events, hasLength(1));
      expect(events[0].eventType, 'event');
      expect(events[0].data, 'hi');
    });

    test('flushes trailing event without blank-line terminator', () async {
      final events = await _byteStream([
        utf8.encode('event: end\ndata: {"reason":"done"}'),
      ]).transform<SseEvent>(SessionAttachRunner.sseEventTransformer).toList();
      expect(events, hasLength(1));
      expect(events[0].eventType, 'end');
      expect(events[0].data, '{"reason":"done"}');
    });

    test('joins multiple data: lines with newline', () async {
      final events = await _byteStream([
        utf8.encode('event: event\ndata: line1\ndata: line2\n\n'),
      ]).transform<SseEvent>(SessionAttachRunner.sseEventTransformer).toList();
      expect(events, hasLength(1));
      expect(events[0].data, 'line1\nline2');
    });
  });

  group('SessionAttachRunner.parseSseChunk', () {
    test('parses a single event', () {
      final events = <(String, String)>[];
      SessionAttachRunner.parseSseChunk(
          'event: event\ndata: hello\n\n',
          (type, data) => events.add((type, data)));
      expect(events, hasLength(1));
      expect(events[0].$1, 'event');
      expect(events[0].$2, 'hello');
    });

    test('parses multiple events', () {
      final events = <(String, String)>[];
      SessionAttachRunner.parseSseChunk(
          'event: ready\ndata: {}\n\nevent: event\ndata: hi\n\n',
          (type, data) => events.add((type, data)));
      expect(events, hasLength(2));
      expect(events[0].$1, 'ready');
      expect(events[1].$1, 'event');
    });
  });
}