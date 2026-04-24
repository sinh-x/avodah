import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Best-effort HTTP title extraction service.
///
/// Fetches the <title> tag from a URL. Falls back to null on timeout
/// or error — callers should use the raw URL as the title fallback.
class TitleExtractionService {
  final http.Client _client;
  final Duration _timeout;

  TitleExtractionService({
    http.Client? client,
    Duration timeout = const Duration(seconds: 3),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  /// Fetches the <title> from [url].
  ///
  /// Returns the title text on success, null on timeout or error.
  /// Errors are logged but not thrown — this is best-effort.
  Future<String?> fetchTitle(String url) async {
    // Only fetch http/https URLs — reject file://, ftp://, etc.
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    try {
      final response = await _client
          .get(uri)
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Title fetch timed out');
      });

      if (response.statusCode != 200) {
        debugPrint('[TitleExtraction] Non-200 status: ${response.statusCode} for $url');
        return null;
      }

      return _parseTitle(response.body);
    } catch (e) {
      debugPrint('[TitleExtraction] Failed to fetch title for $url: $e');
      return null;
    }
  }

  /// Parses the <title> tag from [html] content.
  ///
  /// Handles common variations: <title>, <TITLE>, whitespace, attributes.
  /// Returns null if no title found.
  String? _parseTitle(String html) {
    // Try lowercase first (most common)
    var match = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
        .firstMatch(html);
    if (match != null) {
      return _cleanTitle(match.group(1)!);
    }
    return null;
  }

  /// Cleans extracted title text.
  ///
  /// Trims whitespace and decodes common HTML entities.
  String _cleanTitle(String raw) {
    var result = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");

    // Decode decimal numeric entities: &#NNN;
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    );

    // Decode hex numeric entities: &#xHHH;
    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );

    return result.trim();
  }
}
