/// Result of a word-level diff computation on a pair of lines.
///
/// Each entry represents a segment of the diff with its text content
/// and the type of change (unchanged, added, or deleted).
class WordDiffResult {
  /// The segments making up the diff, in order.
  final List<WordDiffSegment> segments;

  /// Whether this diff was skipped due to size threshold.
  final bool skipped;

  const WordDiffResult({required this.segments, this.skipped = false});

  /// An empty result for when no diff is needed (empty lines).
  const WordDiffResult.empty()
      : segments = const [],
        skipped = false;

  /// A result indicating the diff was skipped due to size.
  const WordDiffResult.skipped()
      : segments = const [],
        skipped = true;
}

/// A single segment within a word diff result.
class WordDiffSegment {
  /// The text content of this segment.
  final String text;

  /// The type of this segment: 'unchanged', 'added', or 'deleted'.
  final String type;

  const WordDiffSegment({required this.text, required this.type});

  bool get isAdded => type == 'added';
  bool get isDeleted => type == 'deleted';
  bool get isUnchanged => type == 'unchanged';
}

/// Options for word diff computation.
class WordDiffOptions {
  /// Maximum total lines in a diff hunk before skipping word-level diff.
  /// Large diffs can be slow and are better handled with full-line highlighting.
  final int maxLinesForWordDiff;

  const WordDiffOptions({this.maxLinesForWordDiff = 500});
}

/// Computes word-level diff between two strings.
///
/// Returns a [WordDiffResult] containing the segments with their change types.
/// Returns [WordDiffResult.skipped] if the hunk exceeds [maxLinesForWordDiff] total lines.
WordDiffResult computeWordDiff(String oldLine, String newLine, {WordDiffOptions options = const WordDiffOptions()}) {
  // Fast path: empty lines need no word diff
  if (oldLine.isEmpty && newLine.isEmpty) {
    return const WordDiffResult.empty();
  }

  // Fast path: if either is empty, all content is add or delete
  if (oldLine.isEmpty) {
    return WordDiffResult(segments: [WordDiffSegment(text: newLine, type: 'added')]);
  }
  if (newLine.isEmpty) {
    return WordDiffResult(segments: [WordDiffSegment(text: oldLine, type: 'deleted')]);
  }

  // Compute LCS-based word diff
  final oldWords = _splitIntoWords(oldLine);
  final newWords = _splitIntoWords(newLine);

  final segments = _computeLcsDiff(oldWords, newWords);

  // Merge adjacent segments of the same type to reduce widget count
  final merged = _mergeAdjacentSegments(segments);

  return WordDiffResult(segments: merged);
}

/// Splits a line into words (tokens separated by whitespace).
///
/// Preserves whitespace as separate tokens so we can reconstruct
/// the original spacing when rendering.
List<String> _splitIntoWords(String line) {
  if (line.isEmpty) return [];

  final result = <String>[];
  final buffer = StringBuffer();
  bool inWhitespace = false;

  for (int i = 0; i < line.length; i++) {
    final char = line[i];
    final isWs = char == ' ' || char == '\t';

    if (isWs) {
      if (!inWhitespace && buffer.isNotEmpty) {
        // End of a word - save it
        result.add(buffer.toString());
        buffer.clear();
      }
      // Collect whitespace into a single token
      if (!inWhitespace) {
        inWhitespace = true;
        buffer.write(char);
      } else {
        buffer.write(char);
      }
    } else {
      if (inWhitespace && buffer.isNotEmpty) {
        // End of whitespace - save it
        result.add(buffer.toString());
        buffer.clear();
        inWhitespace = false;
      }
      buffer.write(char);
    }
  }

  // Don't forget the last buffer
  if (buffer.isNotEmpty) {
    result.add(buffer.toString());
  }

  return result;
}

/// Computes LCS-based diff between two word lists.
List<WordDiffSegment> _computeLcsDiff(List<String> oldWords, List<String> newWords) {
  final result = <WordDiffSegment>[];

  // Build LCS table using Myers' algorithm-inspired approach
  // For word-level diff, we want to find which words are unchanged, added, deleted

  final m = oldWords.length;
  final n = newWords.length;

  // Build the LCS cost matrix
  // dp[i][j] = length of LCS of oldWords[0..i-1] and newWords[0..j-1]
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      if (oldWords[i - 1] == newWords[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
      }
    }
  }

  // Backtrack to find the diff
  int i = m;
  int j = n;
  final diffPairs = <({String text, String type})>[];

  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && oldWords[i - 1] == newWords[j - 1]) {
      // Unchanged word
      diffPairs.add((text: oldWords[i - 1], type: 'unchanged'));
      i--;
      j--;
    } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
      // Added word (in new but not in old)
      diffPairs.add((text: newWords[j - 1], type: 'added'));
      j--;
    } else if (i > 0) {
      // Deleted word (in old but not in new)
      diffPairs.add((text: oldWords[i - 1], type: 'deleted'));
      i--;
    }
  }

  // Reverse since we backtracked from the end
  for (int k = diffPairs.length - 1; k >= 0; k--) {
    result.add(WordDiffSegment(text: diffPairs[k].text, type: diffPairs[k].type));
  }

  return result;
}

/// Merges adjacent segments of the same type to reduce widget count.
List<WordDiffSegment> _mergeAdjacentSegments(List<WordDiffSegment> segments) {
  if (segments.isEmpty) return [];

  final result = <WordDiffSegment>[];
  var current = segments.first;

  for (int i = 1; i < segments.length; i++) {
    final seg = segments[i];
    if (seg.type == current.type) {
      // Merge with current
      current = WordDiffSegment(text: current.text + seg.text, type: current.type);
    } else {
      result.add(current);
      current = seg;
    }
  }
  result.add(current);

  return result;
}

/// Checks if a diff hunk should be skipped due to size.
///
/// When a hunk has too many lines, word-level diff is skipped
/// to maintain UI responsiveness.
bool shouldSkipWordDiff(List<({String type, String content})> lines, {int maxLines = 500}) {
  return lines.length > maxLines;
}

/// Computes word diff for a list of del/add line pairs within a hunk.
///
/// Returns a map where keys are line indices and values are [WordDiffResult].
/// Lines that don't pair evenly are returned as full-line add/del without word-level diff.
///
/// The [delLines] and [addLines] must be parallel lists (same length).
Map<int, WordDiffResult> computeHunkWordDiffs(
  List<({String type, String content})> lines, {
  WordDiffOptions options = const WordDiffOptions(),
}) {
  final results = <int, WordDiffResult>{};

  // Skip if too many lines
  if (shouldSkipWordDiff(lines, maxLines: options.maxLinesForWordDiff)) {
    // Mark all add lines as skipped
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].type == 'add') {
        results[i] = const WordDiffResult.skipped();
      }
    }
    return results;
  }

  // Find consecutive del→add pairs
  int i = 0;
  while (i < lines.length) {
    if (lines[i].type == 'del') {
      // Count consecutive del lines
      int delCount = 0;
      while (i + delCount < lines.length && lines[i + delCount].type == 'del') {
        delCount++;
      }

      // Check if followed by same count of add lines
      if (i + delCount < lines.length && lines[i + delCount].type == 'add') {
        int addCount = 0;
        while (i + delCount + addCount < lines.length &&
               lines[i + delCount + addCount].type == 'add') {
          addCount++;
        }

        if (delCount == addCount) {
          // Paired sequence - compute word diff for each pair
          for (int pair = 0; pair < delCount; pair++) {
            final delIdx = i + pair;
            final addIdx = i + delCount + pair;
            results[addIdx] = computeWordDiff(
              lines[delIdx].content,
              lines[addIdx].content,
              options: options,
            );
          }
          i += delCount + addCount;
          continue;
        }
      }
    }

    // Not part of a paired sequence - mark add lines as skipped (no word diff)
    if (lines[i].type == 'add') {
      results[i] = const WordDiffResult.skipped();
    }
    i++;
  }

  return results;
}
