/// Testable sync/enrollment/PA gateway. Never falls back to another backend.
library;

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'pairing_service.dart';
import 'sync_api_service.dart';
import 'sync_request_policy.dart';

class SyncHttpHandler {
  final SyncApiService sync;
  final PairingService pairing;
  final String agentApiUrl;
  final SyncRequestPolicy policy;
  final DateTime started = DateTime.now();
  final bool jiraConfigured;

  SyncHttpHandler(
      {required this.sync,
      required this.pairing,
      required this.agentApiUrl,
      this.jiraConfigured = false,
      SyncRequestPolicy? policy})
      : policy = policy ?? sync.policy;

  static const enrollment = {
    '/api/sync/status': {'GET'},
    '/api/sync/pair/start': {'POST'},
    '/api/sync/pair/confirm': {'POST'},
    '/api/sync/pair': {'DELETE'},
  };
  static const proxyMethods = {'GET', 'POST', 'PUT', 'PATCH', 'DELETE'};

  Future<void> call(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (!policy.checkOrigin(request)) return;
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        // Only the known native session namespace, not arbitrary upgrades.
        if (path != '/ws' && path != '/ws/session') {
          jsonResponse(request, 404, {'error': 'Unknown WebSocket route'});
          return;
        }
        if (!await policy.authenticate(request, pairing)) return;
        await _webSocket(request);
        return;
      }
      final methods = enrollment[path];
      if (methods != null) {
        if (policy.preflight(request, methods)) return;
        if (path == '/api/sync/pair' &&
            !await policy.authenticate(request, pairing)) return;
        if (!methods.contains(request.method)) {
          jsonResponse(request, 405, {'error': 'Method not allowed'});
          return;
        }
        await _enroll(request);
        return;
      }
      if (await sync.handleRequest(request)) return;
      // Reserved namespaces never leak into the general PA proxy.
      if (path.startsWith('/api/sync') || path.startsWith('/api/config')) {
        jsonResponse(request, 404, {'error': 'Not found'});
        return;
      }
      if (path.startsWith('/api/')) {
        if (policy.preflight(request, proxyMethods)) return;
        if (!await policy.authenticate(request, pairing)) return;
        if (!proxyMethods.contains(request.method)) {
          jsonResponse(request, 405, {'error': 'Method not allowed'});
          return;
        }
        await _proxy(request);
        return;
      }
      if ((path == '/' || path == '/health') && request.method == 'GET') {
        jsonResponse(request, 200, {'status': 'ok', 'service': 'avodah-sync'});
        return;
      }
      if (path == '/ready' && request.method == 'GET') {
        try {
          await sync.db
              .customSelect('SELECT count(*) FROM settings')
              .get()
              .timeout(const Duration(seconds: 2));
          jsonResponse(request, 200, {'crdt': 'ready'});
        } catch (_) {
          jsonResponse(request, 503, {'crdt': 'not-ready'});
        }
        return;
      }
      if (path == '/dependencies' && request.method == 'GET') {
        final client = http.Client();
        var pa = 'unavailable';
        try {
          final response = await client
              .get(Uri.parse('$agentApiUrl/api/health'))
              .timeout(const Duration(seconds: 2));
          pa = response.statusCode == 401 || response.statusCode == 403
              ? 'auth-unavailable'
              : response.statusCode == 200
                  ? 'reachable'
                  : 'degraded';
        } catch (_) {
        } finally {
          client.close();
        }
        jsonResponse(request, 200, {
          'pa': pa,
          'jira': !jiraConfigured
              ? 'disabled'
              : sync.jiraService == null
                  ? 'configured-unavailable'
                  : 'configured-unverified'
        });
        return;
      }
      jsonResponse(request, 404, {'error': 'Not found'});
    } on HttpException {
      jsonResponse(request, 413, {'error': 'Body too large'});
    } on FormatException {
      jsonResponse(request, 400, {'error': 'Invalid request'});
    } on TimeoutException {
      jsonResponse(request, 408, {'error': 'Request timeout'});
    } catch (_) {
      jsonResponse(request, 400, {'error': 'Request failed'});
    }
  }

  Future<void> _enroll(HttpRequest r) async {
    switch (r.uri.path) {
      case '/api/sync/status':
        jsonResponse(r, 200, await pairing.getStatus());
      case '/api/sync/pair':
        await pairing.revokePairing(r.headers.value('X-Av-Node-Id')!);
        jsonResponse(r, 200, {'success': true});
      default:
        final body = await readJsonBody(r, 8192);
        final node = body['nodeId'];
        if (node is! String || !PairingService.validNode(node)) {
          jsonResponse(r, 400, {'error': 'Invalid node identity'});
          return;
        }
        if (r.uri.path.endsWith('/start')) {
          final source = r.connectionInfo?.remoteAddress.address ?? 'unknown';
          if (!pairing.admitStart(source)) {
            r.response.headers.set('Retry-After', '60');
            jsonResponse(r, 429, {'error': 'Enrollment rate limited'});
            return;
          }
          try {
            jsonResponse(r, 200, await pairing.startPairing(node));
          } on StateError {
            jsonResponse(r, 429, {'error': 'Enrollment unavailable'});
          }
        } else {
          final pub = body['phonePubKey'];
          final proof = body['hmacProof'];
          if (pub is! String || proof is! String) {
            jsonResponse(r, 400, {'error': 'Invalid pairing request'});
            return;
          }
          final result = await pairing.confirmPairing(
              nodeId: node,
              phonePubKeyBase64: pub,
              hmacProofBase64: proof,
              origin: r.headers.value('origin'));
          jsonResponse(r, result['success'] == true ? 200 : 403, result);
        }
    }
  }

  Future<void> _proxy(HttpRequest r) async {
    final client = http.Client();
    try {
      final bytes = <int>[];
      await for (final chunk in r.timeout(const Duration(seconds: 3))) {
        if (bytes.length + chunk.length > avoMaxPushDeltaBodyBytes) {
          throw const HttpException('body too large');
        }
        bytes.addAll(chunk);
      }
      final upstream = http.Request(r.method, Uri.parse('$agentApiUrl${r.uri}'))
        ..followRedirects = false
        ..bodyBytes = bytes;
      r.headers.forEach((name, values) {
        if (!{
          'host',
          'connection',
          'transfer-encoding',
          'content-length',
          'x-av-pair-token',
          'x-av-node-id'
        }.contains(name.toLowerCase())) {
          upstream.headers[name] = values.join(', ');
        }
      });
      // PA Authorization is forwarded, never synthesized from device authority.
      final response =
          await client.send(upstream).timeout(const Duration(seconds: 3));
      final body =
          await response.stream.toBytes().timeout(const Duration(seconds: 3));
      r.response.statusCode = response.statusCode;
      response.headers.forEach((name, value) {
        if (!{
          'connection',
          'transfer-encoding',
          'content-length',
          'access-control-allow-origin',
          'access-control-allow-headers',
          'access-control-allow-methods'
        }.contains(name.toLowerCase())) {
          r.response.headers.set(name, value);
        }
      });
      r.response.add(body);
      await r.response.close();
    } catch (_) {
      jsonResponse(r, 502, {'error': 'PA unavailable', 'code': 'BAD_GATEWAY'});
    } finally {
      client.close();
    }
  }

  Future<void> _webSocket(HttpRequest r) async {
    WebSocket? upstream;
    try {
      final uri = Uri.parse('$agentApiUrl${r.uri}');
      final auth = r.headers.value('authorization');
      upstream = await WebSocket.connect(
        uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws').toString(),
        headers: {if (auth != null) 'Authorization': auth},
      ).timeout(const Duration(seconds: 3));
      // Recheck after connect to fence a revocation racing the handshake.
      if (!await policy.authenticate(r, pairing)) {
        await upstream.close();
        return;
      }
      final downstream = await WebSocketTransformer.upgrade(r);
      final node = r.headers.value('X-Av-Node-Id')!;
      pairing.trackSocket(node, upstream);
      pairing.trackSocket(node, downstream);
      final peer = upstream;
      peer.listen(downstream.add,
          onDone: downstream.close, onError: (_) => downstream.close());
      downstream.listen(peer.add,
          onDone: peer.close, onError: (_) => peer.close());
    } catch (_) {
      await upstream?.close();
      jsonResponse(r, 502, {'error': 'PA WebSocket unavailable'});
    }
  }
}
