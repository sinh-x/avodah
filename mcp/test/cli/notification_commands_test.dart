import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
      'CLI sends explicitly, retains idempotency ID and never opens the local DB',
      () async {
    final dir = await Directory.systemTemp.createTemp('avo-notify-cli-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final token = List.filled(40, 'x').join();
    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/notifications');
      expect(request.headers.value('Authorization'), 'Bearer $token');
      expect(jsonDecode(await utf8.decoder.bind(request).join()),
          {'id': 'stable-id', 'title': 'Hello', 'body': 'Computer send'});
      request.response
        ..statusCode = 201
        ..write('{"id":"stable-id","created":true,"delivery":"no-device"}');
      await request.response.close();
    });
    try {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/avo.dart',
        'notify',
        '--server',
        'http://127.0.0.1:${server.port}',
        '--id',
        'stable-id',
        '--title',
        'Hello',
        '--body',
        'Computer send',
      ], environment: {
        'AVODAH_NOTIFICATION_SEND_TOKEN': token,
        'AVODAH_DATA_DIR': '${dir.path}/must-not-exist',
        'AVODAH_CONFIG_DIR': '${dir.path}/config-must-not-exist'
      });
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(jsonDecode(result.stdout as String)['id'], 'stable-id');
      expect(await Directory('${dir.path}/must-not-exist').exists(), false);
      expect(
          await Directory('${dir.path}/config-must-not-exist').exists(), false);
    } finally {
      await server.close(force: true);
      await dir.delete(recursive: true);
    }
  });

  test('CLI refuses non-loopback plaintext without touching the database',
      () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/avo.dart',
      'notify',
      '--server',
      'http://example.test',
      '--id',
      'id',
      '--title',
      'title',
      '--body',
      'body',
    ]);
    expect(result.exitCode, 64);
    expect(result.stderr, contains('HTTPS'));
  });
}
