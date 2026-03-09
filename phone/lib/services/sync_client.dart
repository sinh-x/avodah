import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/snapshot.dart';

enum SyncConnectionState { disconnected, connecting, connected }

/// WebSocket client that connects to the desktop sync server.
///
/// Manages connection lifecycle, auto-reconnect, and exposes
/// a stream of [DaySnapshot] updates.
class SyncClient {
  final String serverUrl;

  final _controller = StreamController<DaySnapshot>.broadcast();
  final connectionState =
      ValueNotifier<SyncConnectionState>(SyncConnectionState.disconnected);

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  /// Last successfully received snapshot.
  DaySnapshot? lastSnapshot;

  SyncClient({required this.serverUrl});

  /// Stream of incoming snapshots.
  Stream<DaySnapshot> get snapshots => _controller.stream;

  /// Connect to the sync server.
  void connect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    connectionState.value = SyncConnectionState.connecting;

    try {
      final uri = Uri.parse(serverUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.ready.then((_) {
        if (_disposed) return;
        connectionState.value = SyncConnectionState.connected;
        _reconnectAttempts = 0;
      }).catchError((e) {
        debugPrint('WebSocket connection failed: $e');
        _handleDisconnect();
      });

      _channel!.stream.listen(
        (data) {
          if (_disposed) return;
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final snapshot = DaySnapshot.fromJson(json);
            // Set snapshot timestamp for live timer computation
            if (snapshot.timer != null) {
              snapshot.timer!.snapshotTimestamp = snapshot.timestamp;
            }
            lastSnapshot = snapshot;
            _controller.add(snapshot);
          } catch (e) {
            debugPrint('Error parsing snapshot: $e');
          }
        },
        onDone: () => _handleDisconnect(),
        onError: (e) {
          debugPrint('WebSocket error: $e');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('Failed to create WebSocket: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    connectionState.value = SyncConnectionState.disconnected;
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, max 30s
    final delay = Duration(
      seconds: (1 << _reconnectAttempts).clamp(1, 30),
    );
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, () {
      if (!_disposed) connect();
    });
  }

  /// Disconnect and stop reconnecting.
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    connectionState.value = SyncConnectionState.disconnected;
  }

  /// Permanently dispose this client.
  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
    connectionState.dispose();
  }
}
