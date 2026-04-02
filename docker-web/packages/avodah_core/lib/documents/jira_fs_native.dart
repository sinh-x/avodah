import 'dart:io';

/// Native file system operations for Jira credentials.
///
/// Uses dart:io for file system access.
/// On web, jira_fs_stub.dart is used instead.

/// Expands ~ in paths to the home directory.
String expandHomePath(String path) {
  if (path.startsWith('~/')) {
    final home = Platform.environment['HOME'] ?? '';
    return path.replaceFirst('~', home);
  }
  return path;
}

/// Reads a file and returns its contents.
Future<String> readFileAsString(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw FileSystemException('Config file not found', path);
  }
  return file.readAsString();
}

/// Checks if a file exists.
Future<bool> fileExists(String path) async {
  return File(path).exists();
}
