import 'package:avodah_mcp/cli/format.dart';
import 'package:test/test.dart';

void main() {
  group('parseTimeOfDay', () {
    test('parses HH:MM (24h)', () {
      final result = parseTimeOfDay('14:30');
      expect(result, isNotNull);
      expect(result!.hour, equals(14));
      expect(result.minute, equals(30));
      // Should be today
      final now = DateTime.now();
      expect(result.year, equals(now.year));
      expect(result.month, equals(now.month));
      expect(result.day, equals(now.day));
    });

    test('parses H:MM (single digit hour)', () {
      final result = parseTimeOfDay('9:00');
      expect(result, isNotNull);
      expect(result!.hour, equals(9));
      expect(result.minute, equals(0));
    });

    test('parses 0:00 (midnight)', () {
      final result = parseTimeOfDay('0:00');
      expect(result, isNotNull);
      expect(result!.hour, equals(0));
      expect(result.minute, equals(0));
    });

    test('parses 23:59', () {
      final result = parseTimeOfDay('23:59');
      expect(result, isNotNull);
      expect(result!.hour, equals(23));
      expect(result.minute, equals(59));
    });

    test('parses YYYY-MM-DDThh:mm', () {
      final result = parseTimeOfDay('2026-02-15T09:00');
      expect(result, isNotNull);
      expect(result!.year, equals(2026));
      expect(result.month, equals(2));
      expect(result.day, equals(15));
      expect(result.hour, equals(9));
      expect(result.minute, equals(0));
    });

    test('parses YYYY-MM-DD hh:mm (space separator)', () {
      final result = parseTimeOfDay('2026-02-15 14:30');
      expect(result, isNotNull);
      expect(result!.year, equals(2026));
      expect(result.month, equals(2));
      expect(result.day, equals(15));
      expect(result.hour, equals(14));
      expect(result.minute, equals(30));
    });

    test('parses "yesterday HH:MM"', () {
      final result = parseTimeOfDay('yesterday 14:00');
      expect(result, isNotNull);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(result!.year, equals(yesterday.year));
      expect(result.month, equals(yesterday.month));
      expect(result.day, equals(yesterday.day));
      expect(result.hour, equals(14));
      expect(result.minute, equals(0));
    });

    test('parses "Yesterday" case-insensitively', () {
      final result = parseTimeOfDay('Yesterday 9:30');
      expect(result, isNotNull);
      expect(result!.hour, equals(9));
      expect(result.minute, equals(30));
    });

    test('returns null for invalid hour', () {
      expect(parseTimeOfDay('25:00'), isNull);
    });

    test('returns null for invalid minute', () {
      expect(parseTimeOfDay('14:60'), isNull);
    });

    test('returns null for empty string', () {
      expect(parseTimeOfDay(''), isNull);
    });

    test('returns null for garbage', () {
      expect(parseTimeOfDay('not a time'), isNull);
    });

    test('returns null for invalid date in YYYY-MM-DD format', () {
      expect(parseTimeOfDay('2026-13-01 09:00'), isNull);
    });

    test('returns null for partial input', () {
      expect(parseTimeOfDay('14'), isNull);
    });

    test('handles whitespace trimming', () {
      final result = parseTimeOfDay('  9:00  ');
      expect(result, isNotNull);
      expect(result!.hour, equals(9));
    });
  });

  group('parseDuration', () {
    test('parses hours and minutes', () {
      expect(parseDuration('1h30m'), equals(const Duration(hours: 1, minutes: 30)));
    });

    test('parses hours only', () {
      expect(parseDuration('2h'), equals(const Duration(hours: 2)));
    });

    test('parses minutes only', () {
      expect(parseDuration('45m'), equals(const Duration(minutes: 45)));
    });

    test('handles spaces', () {
      expect(parseDuration('1h 30m'), equals(const Duration(hours: 1, minutes: 30)));
    });

    test('returns null for empty', () {
      expect(parseDuration(''), isNull);
    });

    test('returns null for garbage', () {
      expect(parseDuration('abc'), isNull);
    });
  });
}
