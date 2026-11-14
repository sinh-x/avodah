/// Shared fail-closed HTTP boundary. CORS is a separate browser restriction.
library;

import 'dart:convert';
import 'dart:io';

import 'pairing_service.dart';

class SyncRequestPolicy {
  final Set<String> allowedOrigins;

  SyncRequestPolicy({Iterable<String>? allowedOrigins})
      : allowedOrigins = Set.unmodifiable(allowedOrigins ??
            (Platform.environment['SYNC_ALLOWED_ORIGINS'] ?? '')
                .split(',')
                .where((s) => s.isNotEmpty));

  static const allowedHeaders = {
    'content-type',
    'x-av-node-id',
    'x-av-pair-token',
  };

  /// Native requests omit Origin. Browser origins must be exact operator entries.
  bool checkOrigin(HttpRequest request) {
    final origin = request.headers.value('origin');
    if (origin == null) return true;
    final uri = Uri.tryParse(origin);
    if (origin == 'null' ||
        uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
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
    final node = request.headers.value('X-Av-Node-Id');
    final token = request.headers.value('X-Av-Pair-Token');
    if (pairing == null ||
        node == null ||
        token == null ||
        !await pairing.verifyPairToken(node, token)) {
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
  final bytes = <int>[];
  await for (final chunk in request.timeout(const Duration(seconds: 3))) {
    if (bytes.length + chunk.length > maxBytes) {
      throw const HttpException('body too large');
    }
    bytes.addAll(chunk);
  }
  final value = jsonDecode(utf8.decode(bytes));
  if (value is! Map<String, dynamic>)
    throw const FormatException('object required');
  return value;
}
