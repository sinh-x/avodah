/// Canonical credential destination. Path is a deployment boundary, not an
/// origin/XSS isolation boundary. Never accept credentials embedded in URLs.
String normalizeServerScope(String value) {
  final uri = Uri.parse(value.trim());
  if (!{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.path.contains('//') ||
      uri.pathSegments.any((s) => s == '.' || s == '..')) {
    throw const FormatException(
      'Use an HTTP(S) server base without credentials, query or fragment',
    );
  }
  return '${uri.origin}${uri.path.replaceFirst(RegExp(r'/+$'), '')}';
}
