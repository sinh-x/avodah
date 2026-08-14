import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:avodah_viewer/services/ws_session_client.dart';
import 'package:avodah_viewer/models/ws_session_event.dart';

/// A minimal fake [WebSocketChannel] for testing [WsSessionClient] without
/// a real WebSocket server. Uses broadcast [StreamController]s to simulate
/// the bidirectional stream/sink pair (Mn4).
class _FakeWebSocketChannel
    extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _sinkController =
      StreamController<dynamic>();

  final List<String> sentMessages = [];
  bool _sinkClosed = false;

  /// Push a raw JSON string into the channel's stream as if received from
  /// the server.
  void serverSend(String json) {
    _streamController.add(json);
  }

  /// Close the server side of the channel (sends done to the client).
  void serverClose() {
    _streamController.close();
  }

  @override
  Stream get stream => _streamController.stream;

  @override
  WebSocketSink get sink => _FakeWebSocketSink(this);

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

/// A [WebSocketSink] that records messages into the fake channel.
class _FakeWebSocketSink implements WebSocketSink {
  final _FakeWebSocketChannel _channel;

  _FakeWebSocketSink(this._channel);

  @override
  void add(dynamic event) {
    _channel.sentMessages.add(event as String);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _channel._streamController.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream stream) async {
    await for (final item in stream) {
      add(item);
    }
  }

  @override
  Future close([int? closeCode, String? closeReason]) {
    _channel._sinkClosed = true;
    _channel._sinkController.close();
    return Future.value();
  }

  @override
  Future get done => Future.value();
}

void main() {
  group('WsSessionClient message serialization (Mn4)', () {
    test('start() sends JSON with type=start and prompt', () {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      client.start('Hello, world', model: 'glm-5', team: 'builder',
          mode: 'implement');

      expect(fake.sentMessages, hasLength(1));
      final msg = jsonDecode(fake.sentMessages[0]) as Map<String, dynamic>;
      expect(msg['type'], 'start');
      expect(msg['prompt'], 'Hello, world');
      expect(msg['model'], 'glm-5');
      expect(msg['team'], 'builder');
      expect(msg['mode'], 'implement');
    });

    test('resume() sends JSON with type=resume, sessionId, and prompt', () {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      client.resume('s-abc123', 'Follow up', model: 'glm-5');

      expect(fake.sentMessages, hasLength(1));
      final msg = jsonDecode(fake.sentMessages[0]) as Map<String, dynamic>;
      expect(msg['type'], 'resume');
      expect(msg['sessionId'], 's-abc123');
      expect(msg['prompt'], 'Follow up');
      expect(msg['model'], 'glm-5');
      expect(msg.containsKey('team'), isFalse);
    });

    test('stop() sends JSON with type=stop', () {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      client.stop();

      expect(fake.sentMessages, hasLength(1));
      final msg = jsonDecode(fake.sentMessages[0]) as Map<String, dynamic>;
      expect(msg['type'], 'stop');
      expect(msg.length, 1);
    });

    test('start() omits null optional fields', () {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      client.start('just a prompt');

      final msg = jsonDecode(fake.sentMessages[0]) as Map<String, dynamic>;
      expect(msg['type'], 'start');
      expect(msg['prompt'], 'just a prompt');
      expect(msg.containsKey('model'), isFalse);
      expect(msg.containsKey('team'), isFalse);
      expect(msg.containsKey('mode'), isFalse);
    });
  });

  group('WsSessionClient event parsing (Mn4)', () {
    test('parses session-id event correctly', () async {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      final completer = Completer<WsSessionEvent>();
      final sub = client.events.listen((e) {
        if (!completer.isCompleted) completer.complete(e);
      });

      fake.serverSend(jsonEncode({
        'type': 'session-id',
        'sessionId': 's-test-42',
        'timestamp': '2026-08-13T04:00:00Z',
      }));

      final event = await completer.future.timeout(
          const Duration(seconds: 1));
      await sub.cancel();

      expect(event.type, WsSessionEventType.sessionId);
      expect(event.sessionId, 's-test-42');
      expect(event.timestamp, '2026-08-13T04:00:00Z');
    });

    test('parses event type correctly', () async {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      final completer = Completer<WsSessionEvent>();
      final sub = client.events.listen((e) {
        if (!completer.isCompleted) completer.complete(e);
      });

      fake.serverSend(jsonEncode({
        'type': 'event',
        'timestamp': '2026-08-13T04:00:01Z',
        'data': {'kind': 'output', 'body': 'Hello from opencode'},
      }));

      final event = await completer.future.timeout(
          const Duration(seconds: 1));
      await sub.cancel();

      expect(event.type, WsSessionEventType.event);
      expect(event.data, isNotNull);
      expect(event.data!['kind'], 'output');
      expect(event.data!['body'], 'Hello from opencode');
    });

    test('parses error event correctly', () async {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      final completer = Completer<WsSessionEvent>();
      final sub = client.events.listen((e) {
        if (!completer.isCompleted) completer.complete(e);
      });

      fake.serverSend(jsonEncode({
        'type': 'error',
        'timestamp': '2026-08-13T04:00:02Z',
        'message': 'Spawn failed',
      }));

      final event = await completer.future.timeout(
          const Duration(seconds: 1));
      await sub.cancel();

      expect(event.type, WsSessionEventType.error);
      expect(event.message, 'Spawn failed');
    });

    test('parses end event correctly', () async {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      final completer = Completer<WsSessionEvent>();
      final sub = client.events.listen((e) {
        if (!completer.isCompleted) completer.complete(e);
      });

      fake.serverSend(jsonEncode({
        'type': 'end',
        'timestamp': '2026-08-13T04:00:03Z',
        'data': {'reason': 'completed', 'exitCode': 0},
      }));

      final event = await completer.future.timeout(
          const Duration(seconds: 1));
      await sub.cancel();

      expect(event.type, WsSessionEventType.end);
      expect(event.data, isNotNull);
      expect(event.data!['reason'], 'completed');
      expect(event.data!['exitCode'], 0);
    });

    test('silently drops non-JSON messages', () async {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      final received = <WsSessionEvent>[];
      final sub = client.events.listen(received.add);

      fake.serverSend('not json at all');
      fake.serverSend('{"broken":');

      // Give async events a chance to propagate.
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(received, isEmpty);
    });

    test('silently drops non-object JSON (array)', () async {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      final received = <WsSessionEvent>[];
      final sub = client.events.listen(received.add);

      fake.serverSend('[1, 2, 3]');

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(received, isEmpty);
    });

    test('unknown event type defaults to WsSessionEventType.event', () async {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      final completer = Completer<WsSessionEvent>();
      final sub = client.events.listen((e) {
        if (!completer.isCompleted) completer.complete(e);
      });

      fake.serverSend(jsonEncode({
        'type': 'unknown-future-type',
        'timestamp': '2026-08-13T04:00:00Z',
      }));

      final event = await completer.future.timeout(
          const Duration(seconds: 1));
      await sub.cancel();

      expect(event.type, WsSessionEventType.event);
    });
  });

  group('WsSessionClient connect-failure mapping (Mn4/Mn5)', () {
    test('WsSessionConnectException carries user-facing message', () {
      final exc = WsSessionConnectException('pa-platform is not running');
      expect(exc.message, 'pa-platform is not running');
      expect(exc.toString(), 'pa-platform is not running');
    });

    test('close() is idempotent', () {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      client.close();
      client.close(); // Should not throw.

      expect(fake._sinkClosed, isTrue);
    });

    test('isOpen returns false after close', () {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      expect(client.isOpen, isTrue);
      client.close();
      expect(client.isOpen, isFalse);
    });

    test('events stream closes when server disconnects', () async {
      final fake = _FakeWebSocketChannel();
      final client = WsSessionClient.forTesting(fake);

      final doneCompleter = Completer<void>();
      final sub = client.events.listen(
        (_) {},
        onDone: () {
          if (!doneCompleter.isCompleted) doneCompleter.complete();
        },
      );

      fake.serverClose();

      await doneCompleter.future.timeout(const Duration(seconds: 1));
      await sub.cancel();

      expect(client.isOpen, isFalse);
    });
  });
}