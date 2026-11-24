import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;

class NotifyCommand extends Command<void> {
  @override
  final name = 'notify';
  @override
  final description =
      'Explicitly send one notification to the shared Avodah inbox.';

  NotifyCommand() {
    argParser
      ..addOption('server',
          defaultsTo: Platform.environment['AVODAH_SERVER_URL'],
          help: 'Sync server base URL (HTTPS, or loopback HTTP).')
      ..addOption('id',
          mandatory: true, help: 'Stable unique ID; reuse on retries.')
      ..addOption('title', mandatory: true)
      ..addOption('body', mandatory: true);
  }

  @override
  Future<void> run() async {
    final server = Uri.tryParse(argResults!['server'] as String? ?? '');
    final token = Platform.environment['AVODAH_NOTIFICATION_SEND_TOKEN'];
    if (server == null ||
        !server.hasAuthority ||
        server.userInfo.isNotEmpty ||
        server.hasQuery ||
        server.hasFragment ||
        (server.scheme != 'https' &&
            !(server.scheme == 'http' &&
                {'localhost', '127.0.0.1', '::1'}.contains(server.host)))) {
      usageException('Set --server to HTTPS (or loopback HTTP).');
    }
    if (token == null || token.length < 32) {
      usageException(
          'Set AVODAH_NOTIFICATION_SEND_TOKEN (at least 32 characters).');
    }
    final client = http.Client();
    try {
      final base = server.toString().replaceFirst(RegExp(r'/$'), '');
      final request = http.Request('POST', Uri.parse('$base/api/notifications'))
        ..followRedirects = false
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        })
        ..body = jsonEncode({
          for (final key in ['id', 'title', 'body']) key: argResults![key]
        });
      final response = await http.Response.fromStream(
              await client.send(request).timeout(const Duration(seconds: 20)))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 && response.statusCode != 201) {
        stderr.writeln('Notification send failed: HTTP ${response.statusCode}. '
            'Retry with the same ID and content.');
        exitCode = 1;
        return;
      }
      stdout.writeln(response.body);
    } catch (_) {
      stderr.writeln(
          'Notification send unavailable. Retry with the same ID and content.');
      exitCode = 1;
    } finally {
      client.close();
    }
  }
}
