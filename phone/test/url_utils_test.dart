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

    test('returns false for www without scheme', () {
      expect(isUrl('www.example.com'), isFalse);
    });

    test('returns false for ftp scheme', () {
      expect(isUrl('ftp://files.example.com'), isFalse);
    });

    test('returns false for file scheme', () {
      expect(isUrl('file:///tmp/test.txt'), isFalse);
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
  });
}
