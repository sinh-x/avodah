/// URL detection utilities for quick capture content type detection.
library;

/// Detects scheme-less URLs:
/// - www.example.com (with or without path)
/// - domain.tld/path (must have path to avoid false positives like "file.txt")
final _schemelessUrlPattern = RegExp(
  r'^www\.[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}(/\S*)?$'
  r'|'
  r'^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}/\S+$',
);

/// Returns true if [text] looks like a URL.
///
/// Matches http/https URLs and scheme-less patterns like
/// `news.google.com/articles/...` or `www.example.com`.
bool isUrl(String text) {
  final trimmed = text.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return true;
  }
  return _schemelessUrlPattern.hasMatch(trimmed);
}

/// Extracts the URL from [text] if it is a URL, otherwise returns null.
///
/// For scheme-less URLs, prepends `https://`.
String? extractUrl(String text) {
  final trimmed = text.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (_schemelessUrlPattern.hasMatch(trimmed)) {
    return 'https://$trimmed';
  }
  return null;
}
