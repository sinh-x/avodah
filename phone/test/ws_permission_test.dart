import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:avodah_viewer/services/ws_session_client.dart';

void main() {
  for (final code in [401, 403]) {
    test(
      'native session HTTP $code is permission denied, not offline',
      () async {
        HttpOverrides.global = null;
        final server = await HttpServer.bind('127.0.0.1', 0);
        server.listen((r) async {
          r.response.statusCode = code;
          await r.response.close();
        });
        try {
          await expectLater(
            WsSessionClient.connect('ws://127.0.0.1:${server.port}'),
            throwsA(
              isA<WsSessionConnectException>().having(
                (e) => e.message,
                'message',
                contains('permission denied'),
              ),
            ),
          );
        } finally {
          await server.close(force: true);
        }
      },
    );
  }
}
