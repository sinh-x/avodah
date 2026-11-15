import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectNativeSession(Uri uri, Map<String, dynamic>? headers) =>
    IOWebSocketChannel.connect(uri, headers: headers);

bool isSessionPermissionDenied(Object error) {
  final cause = error is WebSocketChannelException ? error.inner : error;
  return cause is WebSocketException &&
      (cause.httpStatusCode == 401 || cause.httpStatusCode == 403);
}
