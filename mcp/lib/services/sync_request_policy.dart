/// Shared fail-closed HTTP boundary. CORS is a separate browser restriction.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'pairing_service.dart';

class SyncRequestPolicy {
  final Set<String> allowedOrigins;

  SyncRequestPolicy({Iterable<String>? allowedOrigins})
      : allowedOrigins = Set.unmodifiable(allowedOrigins ??
            (Platform.environment['SYNC_ALLOWED_ORIGINS'] ?? '')
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty));

  static const allowedHeaders = {
    'content-type',
    'x-av-node-id',
    'x-av-pair-token',
  };

  /// Native requests omit Origin. Browser origins must be exact operator entries.
  bool checkOrigin(HttpRequest request) {
    final origins = request.headers['origin'];
    if (origins == null) return true;
    if (origins.length != 1) {
      jsonResponse(request, 403, {'error': 'Origin not allowed'});
      return false;
    }
    final origin = origins.single;
    final uri = Uri.tryParse(origin);
    if (origin == 'null' ||
        uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.origin != origin ||
        !allowedOrigins.contains(origin)) {
      jsonResponse(request, 403, {'error': 'Origin not allowed'});
      return false;
    }
    request.response.headers.set('Access-Control-Allow-Origin', origin);
    request.response.headers.set('Vary', 'Origin');
    return true;
  }

  bool preflight(HttpRequest request, Set<String> methods) {
    if (request.method != 'OPTIONS') return false;
    final requested = request.headers.value('access-control-request-method');
    final headers =
        (request.headers.value('access-control-request-headers') ?? '')
            .split(',')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty);
    if (requested == null ||
        !methods.contains(requested) ||
        headers.any((s) => !allowedHeaders.contains(s))) {
      jsonResponse(request, 403, {'error': 'Preflight not allowed'});
    } else {
      request.response.headers
          .set('Access-Control-Allow-Methods', methods.join(', '));
      request.response.headers
          .set('Access-Control-Allow-Headers', allowedHeaders.join(', '));
      request.response.statusCode = 204;
      request.response.close();
    }
    return true;
  }

  Future<bool> authenticate(
      HttpRequest request, PairingService? pairing) async {
    final nodes = request.headers['X-Av-Node-Id'];
    final tokens = request.headers['X-Av-Pair-Token'];
    if (pairing == null ||
        nodes == null ||
        nodes.length != 1 ||
        tokens == null ||
        tokens.length != 1 ||
        !await pairing.verifyPairToken(nodes.single, tokens.single)) {
      jsonResponse(request, 403, {
        'error': 'Pairing required',
        'code': 'PAIRING_REQUIRED',
      });
      return false;
    }
    return true;
  }
}

void jsonResponse(HttpRequest request, int status, Map<String, dynamic> body) {
  request.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  request.response.close();
}

/// Enforces the limit while streaming, including chunked requests.
Future<Map<String, dynamic>> readJsonBody(
    HttpRequest request, int maxBytes) async {
  final bytes = await readBoundedBytes(request, maxBytes);
  final value = jsonDecode(utf8.decode(bytes));
  if (value is! Map<String, dynamic>)
    throw const FormatException('object required');
  return value;
}

/// Total deadline, not a resettable per-chunk timeout. Cancels the subscription
/// on every failure so a slow sender cannot retain unbounded background work.
Future<List<int>> readBoundedBytes(Stream<List<int>> stream, int maxBytes,
    {Duration deadline = const Duration(seconds: 3)}) async {
  final iterator = StreamIterator<List<int>>(stream);
  final watch = Stopwatch()..start();
  final bytes = <int>[];
  try {
    while (true) {
      final remaining = deadline - watch.elapsed;
      if (remaining <= Duration.zero) throw TimeoutException('Body deadline');
      if (!await iterator.moveNext().timeout(remaining)) break;
      if (bytes.length + iterator.current.length > maxBytes) {
        throw const HttpException('body too large');
      }
      bytes.addAll(iterator.current);
    }
    return bytes;
  } finally {
    await iterator.cancel();
  }
}
