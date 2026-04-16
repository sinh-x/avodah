/// URL detection utilities for quick capture content type detection.
library;

/// Returns true if [text] looks like a URL (starts with http:// or https://).
bool isUrl(String text) {
  final trimmed = text.trim();
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}

/// Extracts the URL from [text] if it is a URL, otherwise returns null.
String? extractUrl(String text) {
  final trimmed = text.trim();
  if (isUrl(trimmed)) {
    return trimmed;
  }
  return null;
}
