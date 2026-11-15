import 'dart:io';
import 'package:avodah_mcp/config/sync_listener_config.dart';
import 'package:test/test.dart';

void main() {
  test('CLI > environment > persisted port > safe defaults', () {
    expect(SyncListenerConfig.parse([], {}).port, 9847);
    expect(SyncListenerConfig.parse([], {}, configPort: 9000).port, 9000);
    expect(
        SyncListenerConfig.parse([], {'SYNC_PORT': '9001'}, configPort: 9000)
            .port,
        9001);
    expect(
        SyncListenerConfig.parse(['--port', '9002'], {'SYNC_PORT': '9001'})
            .port,
        9002);
    expect(SyncListenerConfig.parse([], {}).host.isLoopback, true);
    expect(SyncListenerConfig.parse(['--host', '::1'], {}).host.type,
        InternetAddressType.IPv6);
  });
  test('invalid boundary values and nonloopback require explicit opt-in', () {
    for (final port in ['x', '0', '-1', '65536']) {
      expect(() => SyncListenerConfig.parse([], {'SYNC_PORT': port}),
          throwsFormatException);
    }
    for (final host in ['localhost', 'bad host', '0.0.0.0', '::']) {
      expect(() => SyncListenerConfig.parse([], {'SYNC_HOST': host}),
          throwsFormatException);
    }
    expect(
        SyncListenerConfig.parse(
            ['--host', '0.0.0.0', '--allow-nonloopback'], {}).host.isLoopback,
        false);
    expect(() => SyncListenerConfig.parse([], {'JIRA_ENABLED': 'yes'}),
        throwsFormatException);
  });
  test('bad startup cannot create data/config/state directories', () async {
    final fixture = await Directory.systemTemp.createTemp('avo-invalid-');
    try {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/sync_server.dart',
        '--port',
        '0'
      ], environment: {
        'AVODAH_CONFIG_DIR': '${fixture.path}/config',
        'AVODAH_DATA_DIR': '${fixture.path}/data',
        'XDG_STATE_HOME': '${fixture.path}/state'
      });
      expect(result.exitCode, 64);
      expect(fixture.listSync(), isEmpty);
    } finally {
      await fixture.delete(recursive: true);
    }
  });
}
