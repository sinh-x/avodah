import 'package:http/http.dart' as http;

http.Client createScopedClient(String baseUrl) =>
    _ScopedClient(Uri.parse(baseUrl));

class _ScopedClient extends http.BaseClient {
  final Uri base;
  final http.Client inner = http.Client();
  _ScopedClient(this.base);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.origin != base.origin ||
        !request.url.path.startsWith(
          '${base.path.replaceFirst(RegExp(r'/+$'), '')}/api/',
        )) {
      throw StateError('Unsafe credential destination');
    }
    request.followRedirects = false;
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}
