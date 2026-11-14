import 'dart:io';
import 'package:args/args.dart';

class SyncListenerConfig {
  final int port;
  final InternetAddress host;
  SyncListenerConfig(this.port, this.host);

  factory SyncListenerConfig.parse(List<String> args, Map<String, String> env,
      {int configPort = 9847}) {
    final parser = ArgParser()
      ..addOption('port',
          abbr: 'p', defaultsTo: env['SYNC_PORT'] ?? '$configPort')
      ..addOption('host',
          abbr: 'h', defaultsTo: env['SYNC_HOST'] ?? '127.0.0.1')
      ..addFlag('allow-nonloopback', defaultsTo: false, negatable: false);
    final parsed = parser.parse(args);
    final port = int.tryParse(parsed['port'] as String);
    final host = InternetAddress.tryParse(parsed['host'] as String);
    if (port == null ||
        port < 1 ||
        port > 65535 ||
        host == null ||
        (!host.isLoopback && !(parsed['allow-nonloopback'] as bool))) {
      throw const FormatException(
          'Invalid listener: port 1..65535, literal loopback IP required; nonloopback requires development opt-in');
    }
    if (env['JIRA_ENABLED'] != null &&
        !{'true', 'false'}.contains(env['JIRA_ENABLED'])) {
      throw const FormatException('JIRA_ENABLED must be true or false');
    }
    return SyncListenerConfig(port, host);
  }
}
