import 'dart:js_interop';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

http.Client createScopedClient(String baseUrl) =>
    _ScopedClient(Uri.parse(baseUrl));

class _ScopedClient extends http.BaseClient {
  final Uri base;
  _ScopedClient(this.base);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (base.scheme != 'https' ||
        base.origin != Uri.parse(web.window.location.href).origin ||
        request.url.origin != base.origin ||
        !request.url.path.startsWith(
          '${base.path.replaceFirst(RegExp(r'/+$'), '')}/api/',
        )) {
      throw StateError('Unsafe browser credential destination');
    }
    final body = await request.finalize().toBytes();
    final headers = web.Headers();
    request.headers.forEach((name, value) => headers.set(name, value));
    final response = await web.window
        .fetch(
          request.url.toString().toJS,
          web.RequestInit(
            method: request.method,
            headers: headers,
            redirect: 'error',
            credentials: 'omit',
            cache: 'no-store',
            body: body.isEmpty ? null : body.toJS,
          ),
        )
        .toDart;
    final bytes = (await response.arrayBuffer().toDart).toDart.asUint8List();
    return http.StreamedResponse(
      Stream.value(bytes),
      response.status,
      request: request,
      headers: {'content-type': response.headers.get('content-type') ?? ''},
    );
  }
}
