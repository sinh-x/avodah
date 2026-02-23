#!/usr/bin/env dart

/// Increments the Flutter build number (+N) in root pubspec.yaml
/// and updates version.dart with the beta suffix.
///
/// Usage:
///   dart run tool/bump_build.dart
///
/// Updates:
///   - pubspec.yaml: version X.Y.Z+N → X.Y.Z+(N+1)
///   - packages/avodah_core/lib/version.dart: 'X.Y.Z-beta.N'
import 'dart:io';

void main() {
  final rootDir = _findRoot();

  // 1. Bump build number in pubspec.yaml
  final pubspecFile = File('$rootDir/pubspec.yaml');
  final content = pubspecFile.readAsStringSync();

  final pattern = RegExp(r'version:\s*(\d+\.\d+\.\d+)\+(\d+)');
  final match = pattern.firstMatch(content);

  if (match == null) {
    print('Error: Could not find version+build in pubspec.yaml');
    exit(1);
  }

  final version = match.group(1)!;
  final currentBuild = int.parse(match.group(2)!);
  final newBuild = currentBuild + 1;

  final updated = content.replaceFirst(
    match.group(0)!,
    'version: $version+$newBuild',
  );

  pubspecFile.writeAsStringSync(updated);
  print('Bumped build: $version+$currentBuild → $version+$newBuild');

  // 2. Update version.dart with beta suffix
  final versionFile = File('$rootDir/packages/avodah_core/lib/version.dart');
  final betaVersion = '$version-beta.$newBuild';
  versionFile.writeAsStringSync(
    "/// Single source of truth for the Avodah version.\n"
    "/// Updated by tool/bump_version.dart and tool/bump_build.dart — do not edit manually.\n"
    "const String avodahVersion = '$betaVersion';\n",
  );
  print('Updated version.dart: $betaVersion');
}

String _findRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/packages').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      print('Error: Could not find project root.');
      exit(1);
    }
    dir = parent;
  }
}
