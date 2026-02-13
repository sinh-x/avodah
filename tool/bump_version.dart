#!/usr/bin/env dart

/// Bumps the Avodah version across all files.
///
/// Usage:
///   dart run tool/bump_version.dart <version>
///   dart run tool/bump_version.dart patch|minor|major
///
/// Updates:
///   - packages/avodah_core/lib/version.dart  (source of truth)
///   - packages/avodah_core/pubspec.yaml
///   - mcp/pubspec.yaml
///   - pubspec.yaml                           (root Flutter app)
///   - flake.nix
///   - CHANGELOG.md                           (adds new section from git log)
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    print('Usage: dart run tool/bump_version.dart <version|patch|minor|major>');
    exit(0);
  }

  final rootDir = _findRoot();
  final currentVersion = _readCurrentVersion(rootDir);
  final newVersion = _resolveVersion(currentVersion, args.first);

  if (newVersion == currentVersion) {
    print('Already at version $currentVersion — nothing to do.');
    exit(0);
  }

  print('Bumping $currentVersion → $newVersion\n');

  // 1. version.dart (source of truth)
  _replaceInFile(
    File('$rootDir/packages/avodah_core/lib/version.dart'),
    "const String avodahVersion = '$currentVersion';",
    "const String avodahVersion = '$newVersion';",
  );

  // 2. packages/avodah_core/pubspec.yaml
  _replacePubspecVersion(
    File('$rootDir/packages/avodah_core/pubspec.yaml'),
    currentVersion,
    newVersion,
  );

  // 3. mcp/pubspec.yaml
  _replacePubspecVersion(
    File('$rootDir/mcp/pubspec.yaml'),
    currentVersion,
    newVersion,
  );

  // 4. Root pubspec.yaml (Flutter — version: X.Y.Z+build)
  final rootPubspec = File('$rootDir/pubspec.yaml');
  final rootContent = rootPubspec.readAsStringSync();
  final rootPattern = RegExp(r'version:\s*' + RegExp.escape(currentVersion) + r'(\+\d+)?');
  final rootMatch = rootPattern.firstMatch(rootContent);
  if (rootMatch != null) {
    final buildSuffix = rootMatch.group(1) ?? '+1';
    final updated = rootContent.replaceFirst(
      rootMatch.group(0)!,
      'version: $newVersion$buildSuffix',
    );
    rootPubspec.writeAsStringSync(updated);
    print('  Updated pubspec.yaml');
  } else {
    print('  WARNING: Could not find version in pubspec.yaml');
  }

  // 5. flake.nix
  _replaceInFile(
    File('$rootDir/flake.nix'),
    'version = "$currentVersion"',
    'version = "$newVersion"',
  );

  // 6. CHANGELOG.md — prepend new section
  _updateChangelog(rootDir, currentVersion, newVersion);

  // Summary
  print('');
  print('Done! Updated 6 files to $newVersion.');
  print('');
  print('Next steps:');
  print('  git add -A && git commit -m "chore: bump version to $newVersion"');
  print('  git tag v$newVersion');
  print('  git push origin main --tags');
}

// ── Helpers ──────────────────────────────────────────────────────────────────

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

String _readCurrentVersion(String rootDir) {
  final file = File('$rootDir/packages/avodah_core/lib/version.dart');
  final content = file.readAsStringSync();
  final match = RegExp(r"avodahVersion\s*=\s*'([^']+)'").firstMatch(content);
  if (match == null) {
    print('Error: Could not read current version from version.dart');
    exit(1);
  }
  return match.group(1)!;
}

String _resolveVersion(String current, String arg) {
  final parts = current.split('.').map(int.parse).toList();
  if (parts.length != 3) {
    print('Error: Current version "$current" is not semver.');
    exit(1);
  }

  switch (arg) {
    case 'major':
      return '${parts[0] + 1}.0.0';
    case 'minor':
      return '${parts[0]}.${parts[1] + 1}.0';
    case 'patch':
      return '${parts[0]}.${parts[1]}.${parts[2] + 1}';
    default:
      // Validate explicit version
      if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(arg)) {
        print('Error: "$arg" is not a valid semver version or bump keyword.');
        exit(1);
      }
      return arg;
  }
}

void _replaceInFile(File file, String from, String to) {
  final content = file.readAsStringSync();
  if (!content.contains(from)) {
    print('  WARNING: Pattern not found in ${file.path}');
    return;
  }
  file.writeAsStringSync(content.replaceFirst(from, to));
  print('  Updated ${file.uri.pathSegments.last}');
}

void _replacePubspecVersion(File file, String from, String to) {
  final content = file.readAsStringSync();
  final pattern = RegExp(r'version:\s*' + RegExp.escape(from));
  if (!pattern.hasMatch(content)) {
    print('  WARNING: Could not find version in ${file.path}');
    return;
  }
  file.writeAsStringSync(content.replaceFirst(pattern, 'version: $to'));
  print('  Updated ${file.uri.pathSegments.last}');
}

void _updateChangelog(String rootDir, String oldVersion, String newVersion) {
  final changelog = File('$rootDir/CHANGELOG.md');
  if (!changelog.existsSync()) {
    print('  WARNING: CHANGELOG.md not found, skipping.');
    return;
  }

  // Get commits since last tag
  final tag = 'v$oldVersion';
  final result = Process.runSync('git', ['log', '$tag..HEAD', '--oneline']);
  final commits = (result.stdout as String)
      .split('\n')
      .where((l) => l.trim().isNotEmpty)
      .toList();

  // Categorize commits
  final added = <String>[];
  final fixed = <String>[];
  final changed = <String>[];

  for (final commit in commits) {
    // Strip hash prefix
    final msg = commit.replaceFirst(RegExp(r'^[a-f0-9]+\s+'), '');
    // Strip conventional commit prefix for display
    final display = msg.replaceFirst(RegExp(r'^(feat|fix|chore|refactor|docs|test|ci)(\([^)]*\))?:\s*'), '');
    final capitalised = display[0].toUpperCase() + display.substring(1);

    if (msg.startsWith('feat')) {
      added.add(capitalised);
    } else if (msg.startsWith('fix')) {
      fixed.add(capitalised);
    } else {
      changed.add(capitalised);
    }
  }

  // Build new section
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final buf = StringBuffer();
  buf.writeln('## [$newVersion] - $today');
  buf.writeln('');
  if (added.isNotEmpty) {
    buf.writeln('### Added');
    for (final a in added) {
      buf.writeln('- $a');
    }
    buf.writeln('');
  }
  if (fixed.isNotEmpty) {
    buf.writeln('### Fixed');
    for (final f in fixed) {
      buf.writeln('- $f');
    }
    buf.writeln('');
  }
  if (changed.isNotEmpty) {
    buf.writeln('### Changed');
    for (final c in changed) {
      buf.writeln('- $c');
    }
    buf.writeln('');
  }
  if (commits.isEmpty) {
    buf.writeln('_No conventional commits since $oldVersion._');
    buf.writeln('');
  }

  // Insert after the header line "## [old..."
  var content = changelog.readAsStringSync();
  final insertPoint = content.indexOf('\n## [');
  if (insertPoint >= 0) {
    content = content.substring(0, insertPoint + 1) +
        buf.toString() +
        content.substring(insertPoint + 1);
  } else {
    // No existing section — append before EOF
    content += '\n${buf.toString()}';
  }

  // Update link references at bottom
  final linkLine =
      '[$newVersion]: https://github.com/sinh-x/avodah/compare/v$oldVersion...v$newVersion';
  if (!content.contains('[$newVersion]')) {
    // Insert new link before the old version link
    final oldLink = '[$oldVersion]:';
    final linkPos = content.indexOf(oldLink);
    if (linkPos >= 0) {
      content = content.substring(0, linkPos) +
          '$linkLine\n' +
          content.substring(linkPos);
    } else {
      content += '\n$linkLine\n';
    }
  }

  changelog.writeAsStringSync(content);
  print('  Updated CHANGELOG.md');
}
