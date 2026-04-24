library;

/// Map of domain patterns to their content categories.
///
/// Keys are domain substrings (e.g., 'youtube.com', 'github.com').
/// Values are category strings matching the QuickCaptureScreen dropdown.
const Map<String, String> _domainCategoryMap = {
  // Video
  'youtube.com': 'video',
  'youtu.be': 'video',
  'vimeo.com': 'video',
  'twitch.tv': 'video',
  'dailymotion.com': 'video',

  // Articles / Reading
  'medium.com': 'article',
  'substack.com': 'article',
  'dev.to': 'article',
  'hashnode.com': 'article',

  // Code / Technical
  'github.com': 'code',
  'gitlab.com': 'code',
  'bitbucket.org': 'code',
  'stackoverflow.com': 'code',
  'stackblitz.com': 'code',
  'codesandbox.io': 'code',
  'replit.com': 'code',

  // News / Information
  'news.ycombinator.com': 'article',
  'hn.': 'article',
  'reddit.com': 'article',
  'lobsters.org': 'article',

  // Documentation / Reference
  'docs.google.com': 'article',
  'notion.so': 'article',
  'canva.com': 'article',
  'figma.com': 'article',

  // Social
  'twitter.com': 'article',
  'x.com': 'article',
  'linkedin.com': 'article',
  'threads.net': 'article',
};

/// Returns the category for a given URL based on its domain.
///
/// Returns 'learning' as the default when no domain matches.
///
/// The matching is done via substring containment — any domain containing
/// a mapped key will receive that category. For example:
/// - 'https://www.youtube.com/watch?v=...' → 'video'
/// - 'https://github.com/user/repo' → 'code'
/// - 'https://example.com/unknown' → 'learning'
String detectCategoryFromUrl(String? url) {
  if (url == null || url.isEmpty) {
    return 'learning';
  }

  final lowerUrl = url.toLowerCase();

  for (final entry in _domainCategoryMap.entries) {
    if (lowerUrl.contains(entry.key)) {
      return entry.value;
    }
  }

  return 'learning';
}

/// Returns a human-readable label for a category.
String categoryLabel(String category) {
  switch (category) {
    case 'video':
      return 'Video';
    case 'article':
      return 'Article';
    case 'code':
      return 'Code';
    case 'personal':
      return 'Personal';
    case 'work':
      return 'Work';
    case 'learning':
    default:
      return 'Learning';
  }
}
