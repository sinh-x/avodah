import 'package:web_socket_channel/web_socket_channel.dart';

bool isSessionPermissionDenied(Object error) => false;

WebSocketChannel connectNativeSession(Uri uri, Map<String, dynamic>? headers) =>
    throw UnsupportedError(
      'Interactive sessions are not available in this browser delivery',
    );
