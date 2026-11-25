import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../tool/update_nix_pubspec_lock.dart';

void main() {
  test('Nix lock covers every declared direct dependency', () {
    final manifest =
        loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final lock = jsonDecode(File('pubspec.lock.json').readAsStringSync())
        as Map<String, dynamic>;
    final packages = lock['packages'] as Map<String, dynamic>;
    const regenerate =
        'Run dart pub get && dart run tool/update_nix_pubspec_lock.dart in mcp.';

    for (final group in {
      'dependencies': 'direct main',
      'dev_dependencies': 'direct dev',
    }.entries) {
      for (final dependency in (manifest[group.key] as YamlMap).entries) {
        final name = dependency.key as String;
        expect(packages.containsKey(name), isTrue,
            reason: '$name missing. $regenerate');
        final entry = packages[name] as Map<String, dynamic>;
        expect(entry['dependency'], group.value,
            reason: '$name classification is stale. $regenerate');
        final declaration = dependency.value;
        if (declaration is YamlMap && declaration.containsKey('path')) {
          expect(entry['source'], 'path');
          expect(entry['description']['path'], declaration['path']);
          final localManifest = loadYaml(
            File('${declaration['path']}/pubspec.yaml').readAsStringSync(),
          ) as YamlMap;
          expect(entry['version'], localManifest['version'],
              reason: '$name local version is stale. $regenerate');
        } else {
          expect(entry['source'], 'hosted');
          expect(entry['description']['name'], name);
          expect(entry['description']['sha256'], matches(r'^[a-f0-9]{64}$'));
          expect(entry['version'], isNotEmpty);
        }
      }
    }
  });

  test('lock conversion preserves YAML package metadata and SDK constraints',
      () {
    const source = '''
packages:
  example:
    dependency: direct main
    description:
      name: example
      sha256: "0123456789abcdef"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.3"
  local:
    dependency: direct main
    description:
      path: ../packages/local
      relative: true
    source: path
    version: "0.1.0"
sdks:
  dart: ">=3.10.8 <4.0.0"
''';
    final encoded = encodeNixPubspecLock(source);
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    expect(decoded['packages']['example']['version'], '1.2.3');
    expect(decoded['packages']['example']['description']['sha256'],
        '0123456789abcdef');
    expect(decoded['packages']['local']['description']['relative'], isTrue);
    expect(decoded['sdks']['dart'], '>=3.10.8 <4.0.0');
    expect(encoded, endsWith('\n'));
    expect(encodeNixPubspecLock(encoded), encoded);
  });

  test('lock conversion rejects documents without the expected structure', () {
    for (final source in ['', '[]', 'packages: {}', 'packages: []\nsdks: {}']) {
      expect(() => encodeNixPubspecLock(source), throwsFormatException);
    }
  });
}
