import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:avodah_viewer/services/title_extraction_service.dart';

void main() {
  group('TitleExtractionService', () {
    test('extracts title from valid HTML', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>Example Page</title></head></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, 'Example Page');
    });

    test('handles uppercase TITLE tag', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><TITLE>Uppercase Title</TITLE></head></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, 'Uppercase Title');
    });

    test('decodes common HTML entities', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>Tom &amp; Jerry &lt;3&gt;</title></head></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, 'Tom & Jerry <3>');
    });

    test('decodes &quot; and &#39; entities', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>&quot;Hello&quot; &#39;World&#39;</title></head></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, '"Hello" \'World\'');
    });

    test('decodes &apos; entity', () async {
      final client = MockClient((request) async {
        return http.Response(
          "<html><head><title>It&apos;s working</title></head></html>",
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, "It's working");
    });

    test('decodes decimal numeric entities', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>Copyright &#169; 2026</title></head></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      // &#169; = ©
      expect(title, 'Copyright \u00A9 2026');
    });

    test('decodes hex numeric entities', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>Smart &#x2019;quotes&#x2019;</title></head></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      // &#x2019; = right single quotation mark
      expect(title, 'Smart \u2019quotes\u2019');
    });

    test('collapses whitespace in title', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>  Lots   of    spaces  </title></head></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, 'Lots of spaces');
    });

    test('returns null when no title found', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head></head><body>No title here</body></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, isNull);
    });

    test('returns null for non-200 status', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, isNull);
    });

    test('returns null for network error', () async {
      final client = MockClient((request) async {
        throw Exception('Connection refused');
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, isNull);
    });

    test('rejects non-http/https URLs', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('', 200);
      });
      final service = TitleExtractionService(client: client);

      expect(await service.fetchTitle('file:///etc/passwd'), isNull);
      expect(await service.fetchTitle('ftp://files.example.com'), isNull);
      expect(await service.fetchTitle('javascript:alert(1)'), isNull);
      expect(requestCount, 0, reason: 'No HTTP requests should be made');
    });

    test('handles title with attributes', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title lang="en">Attributed Title</title></head></html>',
          200,
        );
      });
      final service = TitleExtractionService(client: client);

      final title = await service.fetchTitle('https://example.com');
      expect(title, 'Attributed Title');
    });
  });
}
