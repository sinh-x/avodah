import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as hl;

import '../services/display_settings_service.dart';

/// Maps common file extensions to highlight.js language names.
String? inferLanguage(String? filePath) {
  if (filePath == null || filePath.isEmpty) return null;

  final lastDot = filePath.lastIndexOf('.');
  if (lastDot < 0 || lastDot == filePath.length - 1) return null;
  final ext = filePath.substring(lastDot);

  const Map<String, String> extToLang = {
    '.dart': 'dart',
    '.js': 'javascript',
    '.jsx': 'javascript',
    '.ts': 'typescript',
    '.tsx': 'typescript',
    '.py': 'python',
    '.rb': 'ruby',
    '.go': 'go',
    '.rs': 'rust',
    '.java': 'java',
    '.kt': 'kotlin',
    '.swift': 'swift',
    '.c': 'c',
    '.cpp': 'cpp',
    '.cc': 'cpp',
    '.cxx': 'cpp',
    '.h': 'c',
    '.hpp': 'cpp',
    '.cs': 'csharp',
    '.php': 'php',
    '.html': 'xml',
    '.htm': 'xml',
    '.xml': 'xml',
    '.svg': 'xml',
    '.css': 'css',
    '.scss': 'scss',
    '.sass': 'scss',
    '.less': 'less',
    '.json': 'json',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.md': 'markdown',
    '.sql': 'sql',
    '.sh': 'bash',
    '.bash': 'bash',
    '.zsh': 'bash',
    '.fish': 'bash',
    '.ps1': 'powershell',
    '.psm1': 'powershell',
    '.dockerfile': 'dockerfile',
    '.tf': 'hcl',
    '.hcl': 'hcl',
    '.toml': 'ini',
    '.ini': 'ini',
    '.cfg': 'ini',
    '.conf': 'ini',
    '.env': 'bash',
    '.gitignore': 'gitignore',
    '.vim': 'vim',
    '.lua': 'lua',
    '.r': 'r',
    '.R': 'r',
    '.scala': 'scala',
    '.sbt': 'scala',
    '.gradle': 'gradle',
    '.ex': 'elixir',
    '.exs': 'elixir',
    '.erl': 'erlang',
    '.hrl': 'erlang',
    '.hs': 'haskell',
    '.ml': 'ocaml',
    '.fs': 'fsharp',
    '.fsx': 'fsharp',
    '.clj': 'clojure',
    '.cljs': 'clojure',
    '.cljc': 'clojure',
    '.elm': 'elm',
    '.vue': 'xml',
    '.svelte': 'xml',
    '.proto': 'protobuf',
    '.rspec': 'ruby',
    '.jbuilder': 'ruby',
    '.rake': 'ruby',
    '.gemspec': 'ruby',
    '.feature': 'gherkin',
    '.gradle.kts': 'kotlin',
    '.kts': 'kotlin',
  };

  return extToLang[ext.toLowerCase()];
}

/// Muted color scheme for syntax highlighting in diff context.
/// Colors are desaturated to avoid clashing with green/red word-diff highlighting.
Map<String, Color> _syntaxColors = {
  'keyword': const Color(0xFF9E9E9E),
  'built_in': const Color(0xFF8D8D8D),
  'type': const Color(0xFF7A8B9A),
  'literal': const Color(0xFF8D8D8D),
  'number': const Color(0xFF9E9E9E),
  'string': const Color(0xFF8A8A8A),
  'comment': const Color(0xFF6B7B6B),
  'doctag': const Color(0xFF6B7B6B),
  'meta': const Color(0xFF7A7A7A),
  'function': const Color(0xFF8A7A6A),
  'class': const Color(0xFF7A8B9A),
  'title': const Color(0xFF8A7A6A),
  'attr': const Color(0xFF8A7A6A),
  'variable': const Color(0xFF8A7A6A),
  'selector-tag': const Color(0xFF9E9E9E),
  'selector-id': const Color(0xFF9E9E9E),
  'selector-class': const Color(0xFF9E9E9E),
  'template-variable': const Color(0xFF8A7A6A),
  'tag': const Color(0xFF9E9E9E),
  'name': const Color(0xFF9E9E9E),
  'bullet': const Color(0xFF9E9E9E),
  'section': const Color(0xFF9E9E9E),
  'subst': const Color(0xFF9E9E9E),
  'emphasis': const Color(0xFF9E9E9E),
  'strong': const Color(0xFF9E9E9E),
  'default': const Color(0xFFE0E0E0),
};

Color _colorForClass(String? className, [SyntaxColors? syntaxColors]) {
  final colors = syntaxColors ?? SyntaxColors.normal;

  if (className == null || className.isEmpty) {
    return colors.defaultColor;
  }

  final firstClass = className.split(' ').first;
  final mapped = colors.forClass(firstClass);
  if (mapped != colors.defaultColor || _syntaxColors.containsKey(firstClass)) {
    return mapped;
  }
  for (final key in _syntaxColors.keys) {
    if (firstClass.startsWith(key)) {
      return _syntaxColors[key]!;
    }
  }
  return colors.defaultColor;
}

/// Parses code with syntax highlighting and returns a list of TextSpans.
List<TextSpan> parseSyntaxHighlighted(String code, String? language,
    [SyntaxColors? syntaxColors]) {
  if (language == null || language.isEmpty || code.isEmpty) {
    return [
      TextSpan(
          text: code,
          style:
              TextStyle(color: (syntaxColors ?? SyntaxColors.normal).defaultColor))
    ];
  }

  try {
    final result = hl.highlight.parse(code, language: language);
    final spans = _convertNodes(result.nodes ?? [], syntaxColors);
    if (spans.isEmpty) {
      return [
        TextSpan(
            text: code,
            style: TextStyle(
                color: (syntaxColors ?? SyntaxColors.normal).defaultColor))
      ];
    }
    return spans;
  } catch (_) {
    return [
      TextSpan(
          text: code,
          style:
              TextStyle(color: (syntaxColors ?? SyntaxColors.normal).defaultColor))
    ];
  }
}

List<TextSpan> _convertNodes(List<hl.Node> nodes, [SyntaxColors? syntaxColors]) {
  final spans = <TextSpan>[];
  for (final node in nodes) {
    if (node.value != null) {
      spans.add(TextSpan(
        text: node.value,
        style: TextStyle(color: _colorForClass(node.className, syntaxColors)),
      ));
    } else if (node.children != null) {
      final childSpans = _convertNodes(node.children!, syntaxColors);
      if (childSpans.isNotEmpty) {
        spans.addAll(childSpans);
      }
    }
  }
  return spans;
}
