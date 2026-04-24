import 'package:flutter_test/flutter_test.dart';
import 'package:avodah_viewer/utils/url_utils.dart';

void main() {
  group('isUrl', () {
    test('returns true for http URLs', () {
      expect(isUrl('http://example.com'), isTrue);
    });

    test('returns true for https URLs', () {
      expect(isUrl('https://example.com'), isTrue);
    });

    test('returns true with leading/trailing whitespace', () {
      expect(isUrl('  https://example.com  '), isTrue);
    });

    test('returns false for plain text', () {
      expect(isUrl('just some text'), isFalse);
    });

    test('returns false for empty string', () {
      expect(isUrl(''), isFalse);
    });

    test('returns true for www without scheme', () {
      expect(isUrl('www.example.com'), isTrue);
    });

    test('returns true for scheme-less URL with path', () {
      expect(isUrl('news.google.com/articles/123'), isTrue);
    });

    test('returns true for scheme-less domain with path', () {
      expect(isUrl('github.com/user/repo'), isTrue);
    });

    test('returns false for bare domain without path', () {
      expect(isUrl('example.com'), isFalse);
    });

    test('returns false for filename-like text', () {
      expect(isUrl('file.txt'), isFalse);
    });

    test('returns false for ftp scheme', () {
      expect(isUrl('ftp://files.example.com'), isFalse);
    });

    test('returns false for file scheme', () {
      expect(isUrl('file:///tmp/test.txt'), isFalse);
    });

    test('returns false for text with spaces', () {
      expect(isUrl('not a url.com/path'), isFalse);
    });
  });

  group('extractUrl', () {
    test('returns URL for https URL', () {
      expect(extractUrl('https://example.com/path'), 'https://example.com/path');
    });

    test('returns trimmed URL with whitespace', () {
      expect(extractUrl('  https://example.com  '), 'https://example.com');
    });

    test('returns null for plain text', () {
      expect(extractUrl('not a url'), isNull);
    });

    test('returns null for empty string', () {
      expect(extractUrl(''), isNull);
    });

    test('prepends https for scheme-less URL with path', () {
      expect(
        extractUrl('news.google.com/articles/CBMi123'),
        'https://news.google.com/articles/CBMi123',
      );
    });

    test('prepends https for www domain', () {
      expect(extractUrl('www.example.com'), 'https://www.example.com');
    });

    test('prepends https for github-like URL', () {
      expect(
        extractUrl('github.com/user/repo'),
        'https://github.com/user/repo',
      );
    });

    test('returns null for bare domain without path', () {
      expect(extractUrl('example.com'), isNull);
    });

    test('trims whitespace before detecting scheme-less URL', () {
      expect(
        extractUrl('  news.google.com/path  '),
        'https://news.google.com/path',
      );
    });
  });
}
