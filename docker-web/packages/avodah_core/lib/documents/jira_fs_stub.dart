/// Stub for platform-specific file system operations.
///
/// This file is used when dart:io is not available (web platform).
/// On native platforms, jira_fs_native.dart is used instead.

/// Expands ~ in paths to the home directory.
/// On web, returns the path unchanged.
String expandHomePath(String path) {
  return path;
}

/// Reads a file and returns its contents.
/// On web, always throws - file system is not available.
Future<String> readFileAsString(String path) async {
  throw UnsupportedError('File system not available on web');
}

/// Checks if a file exists.
/// On web, always returns false.
Future<bool> fileExists(String path) async {
  return false;
}
