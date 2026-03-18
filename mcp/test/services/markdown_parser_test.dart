import 'package:avodah_mcp/services/markdown_parser.dart';
import 'package:test/test.dart';

// Sample markdown with no frontmatter
const _plainMarkdown = '''# Test Document

> **Date:** 2026-03-14
> **From:** requirements / team-manager
> **Type:** Review Request
> **Status:** Pending

## Content

Some content here.
''';

// Sample markdown with existing frontmatter
const _markdownWithFrontmatter = '''---
some_key: some_value
---
# Test Document

Body content.
''';

void main() {
  group('parseMarkdownMetadata', () {
    test('parses title from heading', () {
      final meta = parseMarkdownMetadata(_plainMarkdown);
      expect(meta.title, equals('Test Document'));
    });

    test('parses inline metadata fields', () {
      final meta = parseMarkdownMetadata(_plainMarkdown);
      expect(meta.date, equals('2026-03-14'));
      expect(meta.from, equals('requirements / team-manager'));
      expect(meta.type, equals('Review Request'));
      expect(meta.status, equals('Pending'));
    });

    test('returns null humanFeedback when no frontmatter present', () {
      final meta = parseMarkdownMetadata(_plainMarkdown);
      expect(meta.humanFeedback, isNull);
    });

    test('parses humanFeedback from YAML frontmatter', () {
      const content = '''---
human_feedback:
  action: approved
  by: Sinh
  at: 2026-03-14T10:00:00
  note: Great work
  chips: ["Needs follow-up", "Looks good"]
---
# Document
''';
      final meta = parseMarkdownMetadata(content);
      expect(meta.humanFeedback, isNotNull);
      expect(meta.humanFeedback!.action, equals('approved'));
      expect(meta.humanFeedback!.by, equals('Sinh'));
      expect(meta.humanFeedback!.note, equals('Great work'));
      expect(meta.humanFeedback!.chips,
          equals(['Needs follow-up', 'Looks good']));
    });

    test('parses reject-specific fields from frontmatter', () {
      const content = '''---
human_feedback:
  action: rejected
  by: Sinh
  at: 2026-03-14T10:00:00
  what_is_wrong: Missing UX specs
  what_to_fix: Add phone mockups
  priority: high
---
# Document
''';
      final meta = parseMarkdownMetadata(content);
      final hf = meta.humanFeedback!;
      expect(hf.action, equals('rejected'));
      expect(hf.whatIsWrong, equals('Missing UX specs'));
      expect(hf.whatToFix, equals('Add phone mockups'));
      expect(hf.priority, equals('high'));
    });

    test('parses defer-specific fields from frontmatter', () {
      const content = '''---
human_feedback:
  action: deferred
  by: Sinh
  at: 2026-03-14T10:00:00
  defer_reason: Pending Q2 budget
  requeue_after: "2026-04-01"
---
# Document
''';
      final meta = parseMarkdownMetadata(content);
      final hf = meta.humanFeedback!;
      expect(hf.action, equals('deferred'));
      expect(hf.deferReason, equals('Pending Q2 budget'));
      expect(hf.requeueAfter, equals('2026-04-01'));
    });

    test('parses pending-reject-feedback state from frontmatter', () {
      const content = '''---
human_feedback:
  action: pending-reject-feedback
  by: Sinh
  at: 2026-03-14T10:00:00
---
# Document
''';
      final meta = parseMarkdownMetadata(content);
      expect(meta.humanFeedback!.action, equals('pending-reject-feedback'));
      expect(meta.humanFeedback!.isPendingRejectFeedback, isTrue);
    });

    test('parses saved-for-later state from frontmatter', () {
      const content = '''---
human_feedback:
  action: saved-for-later
  by: Sinh
  at: 2026-03-14T09:15:00
---
# Document
''';
      final meta = parseMarkdownMetadata(content);
      expect(meta.humanFeedback!.action, equals('saved-for-later'));
      expect(meta.humanFeedback!.isSavedForLater, isTrue);
    });

    test('unknown YAML frontmatter keys are ignored (secretary compatibility)',
        () {
      // AC21: secretary can parse files with human_feedback fields without errors
      // Unknown top-level keys should not cause failures
      const content = '''---
some_unknown_key: value
another_unknown: 42
human_feedback:
  action: approved
  by: Sinh
  at: 2026-03-14T10:00:00
  note: Good work
  unknown_future_field: future_value
---
# Document

> **Date:** 2026-03-14
''';
      // Should parse without throwing; unknown keys are ignored
      final meta = parseMarkdownMetadata(content);
      expect(meta.humanFeedback!.action, equals('approved'));
      expect(meta.humanFeedback!.note, equals('Good work'));
      expect(meta.date, equals('2026-03-14'));
    });

    test('uses filename as title fallback when no heading found', () {
      const content = 'Some body without a heading.';
      final meta =
          parseMarkdownMetadata(content, filename: 'my-document.md');
      expect(meta.title, equals('my-document'));
    });
  });

  group('writeFeedbackAnnotation — annotation decision table', () {
    // AC12: fast-path approve with no note/chips → no annotation written
    test('AC12: approve with no note and no chips — no annotation (fast-path)',
        () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const ApproveFeedbackAnnotation(),
      );
      expect(result, equals(_plainMarkdown)); // content unchanged
    });

    // AC11: approve with note → frontmatter + ## Human Review section
    test('AC11: approve with note — writes frontmatter + Human Review section',
        () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const ApproveFeedbackAnnotation(
          note: 'Secretary: follow up on section 3',
        ),
      );
      expect(result, contains('human_feedback:'));
      expect(result, contains('action: approved'));
      expect(result, contains('note:'));
      expect(result, contains('follow up on section 3'));
      expect(result, contains('## Human Review'));
      expect(result, contains('**Action:** approved'));
      expect(result, contains('**Note:** Secretary: follow up on section 3'));
    });

    // approve with chips only → frontmatter + ## Human Review section
    test('approve with chips only — writes frontmatter + Human Review section',
        () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const ApproveFeedbackAnnotation(chips: ['Needs follow-up']),
      );
      expect(result, contains('human_feedback:'));
      expect(result, contains('action: approved'));
      expect(result, contains('chips:'));
      expect(result, contains('## Human Review'));
      expect(result, contains('**Chips:** Needs follow-up'));
    });

    // AC13: reject with structured fields → frontmatter + ## Human Review section
    test(
        'AC13: reject with structured fields — writes frontmatter + Human Review',
        () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const RejectFeedbackAnnotation(
          whatIsWrong: 'Missing mobile UX requirements',
          whatToFix: 'Add phone-specific screens and touch flow details',
          priority: 'high',
        ),
      );
      expect(result, contains('action: rejected'));
      expect(result, contains('what_is_wrong:'));
      expect(result, contains('Missing mobile UX requirements'));
      expect(result, contains('what_to_fix:'));
      expect(result, contains('Add phone-specific screens'));
      expect(result, contains('priority: high'));
      expect(result, contains('## Human Review'));
      expect(result, contains("**What's wrong:** Missing mobile UX requirements"));
      expect(result, contains('**What to fix:** Add phone-specific screens'));
      expect(result, contains('**Priority:** High'));
    });

    // AC14: pending-reject-feedback → frontmatter only, no ## Human Review section
    test(
        'AC14: pending-reject → writes frontmatter only, no Human Review section',
        () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const PendingRejectAnnotation(),
      );
      expect(result, contains('action: pending-reject-feedback'));
      expect(result, isNot(contains('## Human Review')));
    });

    // AC16: defer with note + date → frontmatter + ## Human Review section
    test('AC16: defer with note and date — writes frontmatter + Human Review',
        () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const DeferFeedbackAnnotation(
          reason: 'Pending Q2 budget',
          requeueAfter: '2026-04-01',
        ),
      );
      expect(result, contains('action: deferred'));
      expect(result, contains('defer_reason:'));
      expect(result, contains('Pending Q2 budget'));
      expect(result, contains('requeue_after: "2026-04-01"'));
      expect(result, contains('## Human Review'));
      expect(result, contains('**Reason:** Pending Q2 budget'));
      expect(result, contains('**Re-queue after:** 2026-04-01'));
    });

    // AC22: defer with no note/date → no annotation (fast-path)
    test('AC22: defer with no note and no date — no annotation (fast-path)',
        () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const DeferFeedbackAnnotation(),
      );
      expect(result, equals(_plainMarkdown)); // content unchanged
    });

    // AC17: save for later → frontmatter only, no ## Human Review section
    test(
        'AC17: save for later — writes YAML frontmatter only, no Human Review section',
        () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const SaveForLaterAnnotation(),
      );
      expect(result, contains('action: saved-for-later'));
      expect(result, contains('human_feedback:'));
      expect(result, isNot(contains('## Human Review')));
    });

    // Existing frontmatter is preserved and human_feedback merged
    test('merges human_feedback into existing frontmatter', () {
      final result = writeFeedbackAnnotation(
        _markdownWithFrontmatter,
        const ApproveFeedbackAnnotation(note: 'Good job'),
      );
      expect(result, contains('some_key: some_value'));
      expect(result, contains('human_feedback:'));
      expect(result, contains('action: approved'));
      // Content is still present after frontmatter
      expect(result, contains('# Test Document'));
      expect(result, contains('Body content.'));
    });

    // YAML frontmatter human_feedback is replaced on re-apply.
    // ## Human Review sections accumulate (additive-only model, NF1).
    // In practice, files move out of inbox on action so double-annotation
    // only occurs for pending-reject → full reject flow (AC15), where
    // pending has no ## Human Review section, so no duplication occurs.
    test('re-applying annotation: YAML human_feedback is replaced', () {
      final step1 = writeFeedbackAnnotation(
        _plainMarkdown,
        const ApproveFeedbackAnnotation(note: 'First note'),
      );
      final step2 = writeFeedbackAnnotation(
        step1,
        const ApproveFeedbackAnnotation(note: 'Updated note'),
      );
      // YAML frontmatter has exactly one human_feedback: block with new note
      expect(RegExp(r'human_feedback:').allMatches(step2).length, equals(1));
      // The YAML note field is updated
      expect(step2, contains('note: Updated note'));
      // "First note" remains only in the body's old ## Human Review section
      // (additive model — this is expected; in real flow files move out of inbox)
    });
  });

  group('YAML frontmatter parsing — secretary compatibility (AC21)', () {
    // AC21: secretary reads human_feedback.action and human_feedback.note
    test('secretary can read action and note from approved file', () {
      // Simulate a file that was approved with a note
      const content = '''---
human_feedback:
  action: approved
  by: Sinh
  at: 2026-03-14T10:00:00
  note: "Secretary: create follow-up task for section 3"
---
# Requirements Doc

Content here.
''';
      final meta = parseMarkdownMetadata(content);
      expect(meta.humanFeedback, isNotNull);
      expect(meta.humanFeedback!.action, equals('approved'));
      expect(meta.humanFeedback!.note,
          equals('Secretary: create follow-up task for section 3'));
    });

    test('secretary can read action and structured fields from rejected file',
        () {
      // Simulate a file rejected with structured feedback
      const content = '''---
human_feedback:
  action: rejected
  by: Sinh
  at: 2026-03-14T10:30:00
  what_is_wrong: Missing UX specs
  what_to_fix: Add phone-specific screens
  priority: high
---
# Draft Requirements

Draft content.
''';
      final meta = parseMarkdownMetadata(content);
      final hf = meta.humanFeedback!;
      expect(hf.action, equals('rejected'));
      expect(hf.whatIsWrong, equals('Missing UX specs'));
      expect(hf.whatToFix, equals('Add phone-specific screens'));
      expect(hf.priority, equals('high'));
    });

    test('files without frontmatter still parse correctly (backward compat)',
        () {
      // AC from NF4: existing files without human_feedback still work
      const legacy = '''# Old Document

> **Date:** 2026-02-01
> **From:** some-agent

Content without any YAML frontmatter.
''';
      final meta = parseMarkdownMetadata(legacy);
      expect(meta.title, equals('Old Document'));
      expect(meta.humanFeedback, isNull);
      expect(meta.date, equals('2026-02-01'));
    });

    test('returns empty chips list when no chips in frontmatter', () {
      const content = '''---
human_feedback:
  action: approved
  by: Sinh
  at: 2026-03-14T10:00:00
---
# Document
''';
      final meta = parseMarkdownMetadata(content);
      expect(meta.humanFeedback!.chips, isEmpty);
    });
  });

  group('annotation output format', () {
    test('frontmatter is prepended before document title', () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const SaveForLaterAnnotation(),
      );
      // YAML frontmatter must come before the document body
      final fmEnd = result.indexOf('\n---\n', 4);
      final titleIdx = result.indexOf('# Test Document');
      expect(fmEnd, greaterThan(0));
      expect(titleIdx, greaterThan(fmEnd));
    });

    test('## Human Review section is appended at end of file', () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const ApproveFeedbackAnnotation(note: 'Good'),
      );
      final reviewIdx = result.indexOf('## Human Review');
      expect(reviewIdx, greaterThan(result.indexOf('Some content here.')));
    });

    test('priority capitalized correctly in Human Review section', () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const RejectFeedbackAnnotation(
          whatIsWrong: 'Issue',
          whatToFix: 'Fix it',
          priority: 'high',
        ),
      );
      expect(result, contains('**Priority:** High'));
    });

    test('YAML string with colon is quoted', () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const ApproveFeedbackAnnotation(
          note: 'Secretary: create task',
        ),
      );
      // The note contains ': ' so it should be quoted in YAML
      expect(result,
          contains('note: "Secretary: create task"'));
    });
  });

  group('detectDocumentType — type detection algorithm (AC33, AC34, AC36, NF1, NF2)', () {
    // AC33: no Type: field + no review- prefix → work-report (default)
    test('AC33: file with no Type field and no review- prefix defaults to work-report', () {
      const content = '''# Work Report: Builder Phase 2

> **Date:** 2026-03-14
> **From:** builder / team-manager
> **Status:** success

## What Was Done
- Built something
''';
      expect(detectDocumentType(content, '2026-03-14-builder-phase-2.md'),
          equals('work-report'));
    });

    // AC34: filename starts with review- after date prefix → review-request
    test('AC34: filename with review- prefix (no Type field) → review-request', () {
      const content = '''# Review Request: PA Rich Feedback

> **Date:** 2026-03-14
> **From:** requirements / team-manager

## What Was Done
- Built something
''';
      expect(
          detectDocumentType(content, '2026-03-14-review-pa-rich-feedback.md'),
          equals('review-request'));
    });

    // AC36: legacy alias "FYI + Optional Review" → fyi
    test('AC36: legacy alias "FYI + Optional Review" in Type field → fyi', () {
      const content = '''# FYI: Mockups Routed

> **Date:** 2026-03-14
> **From:** requirements / manager
> **Type:** FYI + Optional Review

Informational content.
''';
      expect(detectDocumentType(content, '2026-03-14-fyi-mockups-routed.md'),
          equals('fyi'));
    });

    // NF1: backward-compat — existing plan-draft in filename → plan-draft
    test('NF1: filename contains plan-draft → plan-draft', () {
      const content = '''# Daily Plan — 2026-03-14

Goals for today.
''';
      expect(
          detectDocumentType(content, '2026-03-14-plan-draft.md'),
          equals('plan-draft'));
    });

    // NF2: tolerant — unknown Type value falls back to work-report
    test('NF2: unknown Type value falls back to work-report', () {
      const content = '''# Some Document

> **Type:** unknown-future-type

Content.
''';
      expect(detectDocumentType(content, '2026-03-14-some-document.md'),
          equals('work-report'));
    });

    test('canonical type values parsed correctly', () {
      for (final testCase in [
        ('> **Type:** work-report', 'work-report'),
        ('> **Type:** review-request', 'review-request'),
        ('> **Type:** plan-draft', 'plan-draft'),
        ('> **Type:** fyi', 'fyi'),
        ('> **Type:** Review & Feedback', 'review-request'),
        ('> **Type:** Plan Draft', 'plan-draft'),
        ('> **Type:** notification', 'fyi'),
      ]) {
        final (typeLine, expected) = testCase;
        final content = '# Title\n\n$typeLine\n\nContent.\n';
        expect(detectDocumentType(content, '2026-03-14-doc.md'), equals(expected),
            reason: 'Type line "$typeLine" should map to "$expected"');
      }
    });

    // Type field takes precedence over filename
    test('explicit Type: field overrides filename fallback', () {
      const content = '''# Review Request: Something

> **Type:** work-report

Content.
''';
      // Filename says review- but Type: says work-report → explicit field wins
      expect(
          detectDocumentType(content, '2026-03-14-review-something.md'),
          equals('work-report'));
    });
  });

  group('AcknowledgeFeedbackAnnotation — acknowledge workflow (AC24, AC25)', () {
    // AC24: acknowledge with no note → no annotation written (fast-path clean move)
    test('AC24: acknowledge with no note writes no annotation (fast-path)', () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const AcknowledgeFeedbackAnnotation(),
      );
      // No YAML frontmatter prepended (no annotation written)
      expect(result.startsWith('---\n'), isFalse);
      // No Human Review section
      expect(result, isNot(contains('## Human Review')));
      // Content unchanged
      expect(result, equals(_plainMarkdown));
    });

    // AC25: acknowledge with note → YAML frontmatter with action: acknowledged + note
    //       NO ## Human Review section
    test('AC25: acknowledge with note writes frontmatter only (no Human Review section)', () {
      final result = writeFeedbackAnnotation(
        _plainMarkdown,
        const AcknowledgeFeedbackAnnotation(note: 'Good work on Phase 2'),
      );
      // YAML frontmatter present
      expect(result.startsWith('---\n'), isTrue);
      // action: acknowledged
      expect(result, contains('action: acknowledged'));
      // note is recorded
      expect(result, contains('note: Good work on Phase 2'));
      // NO ## Human Review section
      expect(result, isNot(contains('## Human Review')));
      // Original content still present
      expect(result, contains('# Test Document'));
    });
  });
}
