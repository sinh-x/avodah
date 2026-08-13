/// WebSocket client for the pa-platform `/ws/session` interactive session
/// protocol.
///
/// Connects to `ws://<host>/ws/session` and exposes a typed [Stream] of
/// [WsSessionEvent] objects. A client sends `start` / `resume` / `stop`
/// messages and receives `session-id` / `event` / `error` / `end` events
/// back over the same socket.
///
/// ## Lifecycle
///
/// 1. [connect] opens the WebSocket and returns a [WsSessionClient].
/// 2. [start] or [resume] sends the initial message and awaits the
///    `session-id` event.
/// 3. [events] is a broadcast stream of all subsequent `event` / `error` /
///    `end` messages.
/// 4. [stop] sends the `stop` message to terminate the session.
/// 5. [close] closes the underlying WebSocket sink.
///
/// All network calls are async — no UI blocking.
///
/// See: `pa-platform/docs/api/websocket.md` — Session Protocol.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/ws_session_event.dart';

/// Message types the client can send to the server.
enum WsSessionMessageType { start, resume, stop }

class WsSessionClient {
  final WebSocketChannel _channel;
  final StreamController<WsSessionEvent> _controller =
      StreamController<WsSessionEvent>.broadcast();

  bool _closed = false;

  WsSessionClient._(this._channel) {
    _channel.stream.listen(
      _onData,
      onError: (Object e) {
        if (!_controller.isClosed) {
          _controller.addError(e);
        }
      },
      onDone: () {
        if (!_controller.isClosed) _controller.close();
      },
    );
  }

  /// Connect to `/ws/session` at the given base URL.
  ///
  /// [wsBaseUrl] must be a `ws://` or `wss://` URL (e.g.
  /// `ws://192.168.1.10:9847`). The `/ws/session` path is appended
  /// automatically. Auth headers (`X-Av-Pair-Token`, `X-Av-Node-Id`) are
  /// passed via [headers] when going through the sync server proxy.
  ///
  /// Throws an [WsSessionConnectException] with a user-facing message when
  /// pa-platform is not running (connection refused, timeout, DNS failure).
  static WsSessionClient connect(
    String wsBaseUrl, {
    Map<String, dynamic>? headers,
  }) {
    final base = wsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/ws/session');
    WebSocketChannel channel;
    try {
      channel = IOWebSocketChannel.connect(uri, headers: headers);
    } catch (e) {
      throw WsSessionConnectException(
        'pa-platform is not running at $wsBaseUrl. '
        'Start it with `pa-core serve`. ($e)',
      );
    }
    return WsSessionClient._(channel);
  }

  /// Broadcast stream of all session events from the server.
  ///
  /// Emits [WsSessionEvent] objects for `session-id`, `event`, `error`,
  /// and `end` messages. The stream closes when the WebSocket disconnects.
  Stream<WsSessionEvent> get events => _controller.stream;

  /// Send a `start` message and return immediately.
  ///
  /// Listen to [events] for the `session-id` confirmation and the
  /// subsequent `event` stream.
  void start(String prompt, {String? model}) {
    _send({
      'type': 'start',
      'prompt': prompt,
      if (model != null) 'model': model,
    });
  }

  /// Send a `resume` message with an existing opencode session id.
  void resume(String sessionId, String prompt, {String? model}) {
    _send({
      'type': 'resume',
      'sessionId': sessionId,
      'prompt': prompt,
      if (model != null) 'model': model,
    });
  }

  /// Send a `stop` message to terminate the active session.
  void stop() {
    _send({'type': 'stop'});
  }

  /// Close the WebSocket connection.
  void close() {
    if (_closed) return;
    _closed = true;
    _channel.sink.close();
  }

  void _send(Map<String, dynamic> message) {
    _channel.sink.add(jsonEncode(message));
  }

  void _onData(dynamic data) {
    if (data is String) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        _controller.add(WsSessionEvent.fromJson(json));
      } catch (_) {
        // Non-JSON messages are silently dropped (matching server behaviour).
      }
    }
  }

  /// Whether the underlying WebSocket is still open.
  bool get isOpen => !_closed && !_controller.isClosed;
}

/// Thrown when the WebSocket connection to `/ws/session` cannot be
/// established (pa-platform not running, wrong host/port, TLS failure).
class WsSessionConnectException implements Exception {
  final String message;

  WsSessionConnectException(this.message);

  @override
  String toString() => message;
}