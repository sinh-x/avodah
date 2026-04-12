Fix markdown code block syntax highlighting for AVO-090.

## Context
- Repo: /home/sinh/git-repos/sinh-x/tools/avodah
- Branch: feature/AVO-090-display-color-control
- Ticket: AVO-090
- Phase: Gap fix (not part of original implementation plan)

## Problem
Markdown code blocks (fenced code blocks with triple backticks in .md documents) do NOT use SyntaxColors. flutter_markdown renders them with plain monospace via its default CodeElementBuilder. This means the contrast and syntax color settings don't affect markdown code blocks.

## Requirements
- FR-A: Markdown code blocks must use SyntaxColors for syntax highlighting
- FR-B: Code blocks must respond to the High Contrast setting (normal vs high contrast syntax colors)
- FR-C: No new package dependencies

## Technical Approach
1. Create a custom CodeBlockBuilder class in phone/lib/widgets/markdown_with_annotations.dart that extends MarkdownElementBuilder
2. Override visitElementAfter to parse the code content with parseSyntaxHighlighted(code, language, syntaxColors) and render using RichText with TextSpans
3. The builder reads theme.syntaxColors.isHighContrast to determine which syntax colors to use
4. Register the builder in the Markdown widget's builders map: 'code': _CodeBlockBuilder()
5. The existing _buildAnnotationStyleSheet should set 'code' style to match the theme's monospace font

## Files to Modify
- phone/lib/widgets/markdown_with_annotations.dart — Add CodeBlockBuilder and wire it up

## Acceptance Criteria
- Code blocks in .md documents render with syntax highlighting (keyword, string, comment colors visible)
- High contrast mode changes code block syntax colors appropriately
- flutter analyze passes with 0 errors
- No new package dependencies

## Verification
Run: cd phone && flutter analyze