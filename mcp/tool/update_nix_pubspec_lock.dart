import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// Run after `dart pub get` to refresh buildDartApplication's dependency lock.
void main() {
  final packageDir = File.fromUri(Platform.script).parent.parent;
  final source = File('${packageDir.path}/pubspec.lock');
  final target = File('${packageDir.path}/pubspec.lock.json');
  target.writeAsStringSync(encodeNixPubspecLock(source.readAsStringSync()));
  stdout.writeln('Updated pubspec.lock.json from pubspec.lock.');
}

String encodeNixPubspecLock(String source) {
  final lock = loadYaml(source);
  if (lock is! YamlMap ||
      lock['packages'] is! YamlMap ||
      lock['sdks'] is! YamlMap) {
    throw const FormatException(
        'Expected a Dart pub lock with packages and sdks.');
  }
  return '${const JsonEncoder.withIndent('  ').convert(lock)}\n';
}
