import 'dart:convert';
import 'dart:io';

import 'notification_store.dart';

typedef VerifyNotificationDevice = Future<bool> Function(
    String node, String token);

/// Notification-only API. Producer credentials can send, never read or edit.
class NotificationApiService {
  final NotificationStore store;
  final VerifyNotificationDevice verifyDevice;
  final String? sendToken;

  NotificationApiService(
      {required this.store, required this.verifyDevice, this.sendToken});

  static bool _equals(String a, String b) {
    final left = utf8.encode(a), right = utf8.encode(b);
    var difference = left.length ^ right.length;
    for (var i = 0; i < left.length && i < right.length; i++) {
      difference |= left[i] ^ right[i];
    }
    return difference == 0;
  }

  Future<bool> handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    if (path != '/api/notifications' &&
        !path.startsWith('/api/notifications/')) {
      return false;
    }
    final response = request.response;
    // Auth is always required on actual requests, including same-origin web.
    response.headers
      ..set(
          'Access-Control-Allow-Origin', request.headers.value('Origin') ?? '*')
      ..set('Vary', 'Origin')
      ..set('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS')
      ..set('Access-Control-Allow-Headers',
          'Content-Type, X-Av-Node-Id, X-Av-Pair-Token, Authorization')
      ..set('Cache-Control', 'no-store');
    void reply(int status, Object value) {
      response.statusCode = status;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode(value));
    }

    try {
      if (request.method == 'OPTIONS') {
        response.statusCode = 204;
        return true;
      }
      final isSend = path == '/api/notifications' && request.method == 'POST';
      if (isSend) {
        final expected = sendToken;
        final auth = request.headers.value('Authorization') ?? '';
        if (expected == null ||
            expected.length < 32 ||
            !_equals(auth, 'Bearer $expected')) {
          throw NotificationProblem(
              403, 'Invalid notification send credential');
        }
      } else {
        final node = request.headers.value('X-Av-Node-Id');
        final token = request.headers.value('X-Av-Pair-Token');
        if (node == null || token == null || !await verifyDevice(node, token)) {
          throw NotificationProblem(403, 'Valid device pairing required');
        }
      }
      if (path == '/api/notifications' && request.method == 'GET') {
        final offset =
            int.tryParse(request.uri.queryParameters['offset'] ?? '0');
        if (offset == null || offset < 0)
          throw NotificationProblem(400, 'Invalid offset');
        final items = store.list(offset: offset, limit: 101);
        reply(200, {
          'items': items.take(100).toList(),
          'nextOffset': items.length > 100 ? offset + 100 : null
        });
      } else if (isSend) {
        final body = await _body(request);
        _keys(body, {'id', 'title', 'body'});
        final id = _text(body, 'id', 100);
        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
          throw NotificationProblem(400, 'Invalid notification ID');
        }
        final result = store.send(
            id, _text(body, 'title', 200), _text(body, 'body', 16000));
        reply(result.created ? 201 : 200, {
          'item': result.item,
          'created': result.created,
          'delivery': 'not-configured'
        });
      } else if (path.startsWith('/api/notifications/') &&
          path.substring('/api/notifications/'.length).isNotEmpty &&
          !path.substring('/api/notifications/'.length).contains('/')) {
        final id = path.substring('/api/notifications/'.length);
        if (request.method == 'GET') {
          reply(200, {'item': store.get(id)});
        } else if (request.method == 'PATCH' || request.method == 'DELETE') {
          final body = await _body(request);
          final deleting = request.method == 'DELETE';
          _keys(
              body,
              deleting
                  ? {'revision'}
                  : {'revision', 'read', 'handled', 'remarks'});
          if (body['revision'] is! int ||
              (body['revision'] as int) < 1 ||
              (!deleting && body.length < 2) ||
              (body.containsKey('read') && body['read'] is! bool) ||
              (body.containsKey('handled') && body['handled'] is! bool) ||
              (body.containsKey('remarks') &&
                  (body['remarks'] is! String ||
                      (body['remarks'] as String).length > 16000))) {
            throw NotificationProblem(
                400, 'Invalid edit; revision and typed fields required');
          }
          reply(200, {
            'item': store.update(id, body['revision'] as int,
                read: body['read'] as bool?,
                handled: body['handled'] as bool?,
                remarks: body['remarks'] as String?,
                delete: deleting)
          });
        } else {
          throw NotificationProblem(405, 'Method not allowed');
        }
      } else {
        throw NotificationProblem(405, 'Method not allowed');
      }
    } on NotificationProblem catch (e) {
      reply(e.status, {'error': e.message});
    } on FormatException {
      reply(400, {'error': 'Invalid JSON object'});
    } catch (_) {
      reply(500, {'error': 'Notification service unavailable'});
    } finally {
      await response.close();
    }
    return true;
  }

  static void _keys(Map<String, dynamic> body, Set<String> allowed) {
    if (body.keys.any((key) => !allowed.contains(key))) {
      throw NotificationProblem(400, 'Unknown fields');
    }
  }

  static String _text(Map<String, dynamic> body, String key, int max) {
    final value = body[key];
    if (value is! String || value.trim().isEmpty || value.length > max) {
      throw NotificationProblem(400, 'Invalid $key');
    }
    return value;
  }

  static Future<Map<String, dynamic>> _body(HttpRequest request) async {
    if (request.headers.contentType?.mimeType != 'application/json') {
      throw NotificationProblem(415, 'application/json required');
    }
    final bytes = <int>[];
    await for (final chunk in request.timeout(const Duration(seconds: 10))) {
      if (bytes.length + chunk.length > 70000) {
        throw NotificationProblem(413, 'Request too large');
      }
      bytes.addAll(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }
}
