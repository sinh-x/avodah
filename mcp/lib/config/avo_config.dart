/// Avodah CLI configuration for user preferences.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'paths.dart';

/// User configuration for the avo CLI.
class AvoConfig {
  /// Custom category names for daily planning.
  /// If empty, defaults are used.
  final List<String> categories;

  static const defaultCategories = [
    'Learning',
    'Working',
    'Side-project',
    'Family & Friends',
    'Personal',
  ];

  const AvoConfig({
    this.categories = const [],
  });

  /// Effective categories list — user's if set, otherwise defaults.
  List<String> get effectiveCategories =>
      categories.isNotEmpty ? categories : defaultCategories;

  /// Loads config from `~/.config/avodah/config.json`.
  /// Returns default config if the file doesn't exist.
  static Future<AvoConfig> load(AvodahPaths paths) async {
    final configPath = p.join(paths.configDir, 'config.json');
    final file = File(configPath);

    if (!await file.exists()) return const AvoConfig();

    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return AvoConfig.fromJson(json);
    } catch (_) {
      return const AvoConfig();
    }
  }

  factory AvoConfig.fromJson(Map<String, dynamic> json) {
    final categoriesRaw = json['categories'] as List<dynamic>?;
    final categories =
        categoriesRaw?.map((e) => e as String).toList() ?? [];
    return AvoConfig(categories: categories);
  }
}
