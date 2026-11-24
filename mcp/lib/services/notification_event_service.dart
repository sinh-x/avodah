import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'notification_store.dart';

/// Private SSE references, not inbox content or proof of Android presentation.
/// Connections are bounded; durable sequence replay recovers missed signals.
class NotificationEventService {
  final NotificationStore store;
  final Future<bool> Function(String node, String token) verifyDevice;
  final Duration heartbeat, lifetime;
  final _activeNodes = <String>{};

  NotificationEventService(
      {required this.store,
      required this.verifyDevice,
      this.heartbeat = const Duration(seconds: 15),
      this.lifetime = const Duration(seconds: 50)});

  Future<bool> handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers
      ..set(
          'Access-Control-Allow-Origin', request.headers.value('Origin') ?? '*')
      ..set('Vary', 'Origin')
      ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'X-Av-Node-Id, X-Av-Pair-Token')
      ..set('Cache-Control', 'no-store, no-transform');
    String? activeNode;
    try {
      if (request.method == 'OPTIONS') {
        response.statusCode = 204;
        return true;
      }
      final node = request.headers.value('X-Av-Node-Id');
      final token = request.headers.value('X-Av-Pair-Token');
      if (node == null || token == null || !await verifyDevice(node, token)) {
        throw NotificationProblem(403, 'Valid device pairing required');
      }
      if (request.method != 'GET')
        throw NotificationProblem(405, 'Method not allowed');
      if (request.uri.queryParameters.keys.any((key) => key != 'after')) {
        throw NotificationProblem(400, 'Unknown stream parameter');
      }
      final raw = request.uri.queryParameters['after'];
      final after = raw == null ? store.latestEventSequence : int.tryParse(raw);
      if (after == null || after < 0)
        throw NotificationProblem(400, 'Invalid cursor');
      if (after > store.latestEventSequence) {
        throw NotificationProblem(
            409, 'Cursor is newer than server history; review server recovery');
      }
      if (_activeNodes.contains(node) || _activeNodes.length >= 16) {
        throw NotificationProblem(429, 'Notification listener limit reached');
      }
      _activeNodes.add(node);
      activeNode = node;
      await _stream(response, node, token, after);
    } on NotificationProblem catch (e) {
      response.statusCode = e.status;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({'error': e.message}));
    } catch (_) {
      // Disconnects are ordinary. Never log headers, references or credentials.
    } finally {
      if (activeNode != null) _activeNodes.remove(activeNode);
      try {
        await response.close();
      } catch (_) {}
    }
    return true;
  }

  Future<void> _stream(
      HttpResponse response, String node, String token, int after) async {
    response.headers
      ..contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..set('X-Accel-Buffering', 'no');
    response.bufferOutput = false;
    final wakes = StreamController<void>();
    var closed = false, pending = false;
    void wake() {
      if (!closed && !pending) {
        pending = true;
        wakes.add(null);
      }
    }

    void close() {
      if (!closed) {
        closed = true;
        unawaited(wakes.close());
      }
    }

    final subscription = store.eventsChanged.listen((_) => wake());
    final tick = Timer.periodic(heartbeat, (_) => wake());
    final expiry = Timer(lifetime, close);
    response.done.then((_) => close(), onError: (Object _) => close());
    var cursor = after, emitted = 0;
    try {
      response.write(
          'data: ${jsonEncode({'type': 'checkpoint', 'cursor': cursor})}\n\n');
      await response.flush().timeout(const Duration(seconds: 5));
      wake();
      await for (final _ in wakes.stream) {
        pending = false;
        // Revocation is checked before each event batch and every heartbeat.
        if (!await verifyDevice(node, token)) {
          response.write(
              'data: {"type":"error","reason":"authorization-required"}\n\n');
          await response.flush().timeout(const Duration(seconds: 5));
          break;
        }
        final events = store.eventsAfter(cursor, limit: 64 - emitted);
        for (final event in events) {
          cursor = event['cursor'] as int;
          response.write(
              'data: ${jsonEncode({'type': 'notification', ...event})}\n\n');
          emitted++;
        }
        if (events.isEmpty) response.write(': heartbeat\n\n');
        await response.flush().timeout(const Duration(seconds: 5));
        if (emitted >= 64) break;
      }
    } finally {
      closed = true;
      tick.cancel();
      expiry.cancel();
      await subscription.cancel();
      unawaited(wakes.close());
    }
  }
}
