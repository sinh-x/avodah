import 'package:flutter_test/flutter_test.dart';
import 'package:avodah_viewer/utils/category_detection.dart';

void main() {
  group('detectCategoryFromUrl', () {
    test('returns learning for null URL', () {
      expect(detectCategoryFromUrl(null), 'learning');
    });

    test('returns learning for empty URL', () {
      expect(detectCategoryFromUrl(''), 'learning');
    });

    test('returns learning for unknown domain', () {
      expect(detectCategoryFromUrl('https://example.com/page'), 'learning');
    });

    group('video domains', () {
      test('youtube.com', () {
        expect(
          detectCategoryFromUrl('https://www.youtube.com/watch?v=abc'),
          'video',
        );
      });

      test('youtu.be', () {
        expect(detectCategoryFromUrl('https://youtu.be/abc'), 'video');
      });

      test('vimeo.com', () {
        expect(detectCategoryFromUrl('https://vimeo.com/12345'), 'video');
      });

      test('twitch.tv', () {
        expect(detectCategoryFromUrl('https://twitch.tv/channel'), 'video');
      });

      test('dailymotion.com', () {
        expect(
          detectCategoryFromUrl('https://www.dailymotion.com/video'),
          'video',
        );
      });
    });

    group('article domains', () {
      test('medium.com', () {
        expect(
          detectCategoryFromUrl('https://medium.com/@user/post'),
          'article',
        );
      });

      test('substack.com', () {
        expect(
          detectCategoryFromUrl('https://newsletter.substack.com/p/issue'),
          'article',
        );
      });

      test('dev.to', () {
        expect(detectCategoryFromUrl('https://dev.to/user/post'), 'article');
      });

      test('reddit.com', () {
        expect(
          detectCategoryFromUrl('https://www.reddit.com/r/flutter/post'),
          'article',
        );
      });

      test('news.ycombinator.com', () {
        expect(
          detectCategoryFromUrl('https://news.ycombinator.com/item?id=123'),
          'article',
        );
      });

      test('twitter.com', () {
        expect(
          detectCategoryFromUrl('https://twitter.com/user/status/123'),
          'article',
        );
      });

      test('x.com', () {
        expect(
          detectCategoryFromUrl('https://x.com/user/status/123'),
          'article',
        );
      });
    });

    group('code domains', () {
      test('github.com', () {
        expect(
          detectCategoryFromUrl('https://github.com/user/repo'),
          'code',
        );
      });

      test('gitlab.com', () {
        expect(
          detectCategoryFromUrl('https://gitlab.com/user/repo'),
          'code',
        );
      });

      test('bitbucket.org', () {
        expect(
          detectCategoryFromUrl('https://bitbucket.org/user/repo'),
          'code',
        );
      });

      test('stackoverflow.com', () {
        expect(
          detectCategoryFromUrl(
            'https://stackoverflow.com/questions/123/title',
          ),
          'code',
        );
      });

      test('codesandbox.io', () {
        expect(
          detectCategoryFromUrl('https://codesandbox.io/s/example'),
          'code',
        );
      });

      test('replit.com', () {
        expect(
          detectCategoryFromUrl('https://replit.com/@user/project'),
          'code',
        );
      });
    });

    test('case insensitive matching', () {
      expect(
        detectCategoryFromUrl('https://GITHUB.COM/user/repo'),
        'code',
      );
      expect(
        detectCategoryFromUrl('https://YouTube.COM/watch?v=abc'),
        'video',
      );
    });
  });

  group('categoryLabel', () {
    test('returns correct labels for known categories', () {
      expect(categoryLabel('video'), 'Video');
      expect(categoryLabel('article'), 'Article');
      expect(categoryLabel('code'), 'Code');
      expect(categoryLabel('personal'), 'Personal');
      expect(categoryLabel('work'), 'Work');
      expect(categoryLabel('learning'), 'Learning');
    });

    test('returns Learning for unknown category', () {
      expect(categoryLabel('unknown'), 'Learning');
    });
  });
}
