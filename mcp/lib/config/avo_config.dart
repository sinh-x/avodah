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

  /// Port for the sync WebSocket server.
  final int syncPort;

  /// Interval in seconds between snapshot pushes to connected clients.
  final int syncInterval;

  /// Per-category comment chip presets for quick comments when stopping timers.
  /// Example: {'Working': ['standup', 'code review', 'debugging'],
  ///           'Learning': ['reading', 'course']}
  final Map<String, List<String>> categoryChips;

  static const defaultCategories = [
    'Learning',
    'Working',
    'Side-project',
    'Family & Friends',
    'Personal',
  ];

  const AvoConfig({
    this.categories = const [],
    this.syncPort = 9847,
    this.syncInterval = 30,
    this.categoryChips = const {},
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

    final syncMap = json['sync'] as Map<String, dynamic>?;
    final syncPort = (syncMap?['port'] as int?) ?? 9847;
    final syncInterval = (syncMap?['intervalSeconds'] as int?) ?? 30;

    final chipsMap = json['categoryChips'] as Map<String, dynamic>?;
    final categoryChips = <String, List<String>>{};
    if (chipsMap != null) {
      for (final entry in chipsMap.entries) {
        final chips = (entry.value as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];
        categoryChips[entry.key] = chips;
      }
    }

    return AvoConfig(
      categories: categories,
      syncPort: syncPort,
      syncInterval: syncInterval,
      categoryChips: categoryChips,
    );
  }

  /// Converts this config to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'categories': categories,
      'sync': {
        'port': syncPort,
        'intervalSeconds': syncInterval,
      },
      'categoryChips': categoryChips,
    };
  }

  /// Saves this config to `~/.config/avodah/config.json`.
  Future<void> save(AvodahPaths paths) async {
    final configPath = p.join(paths.configDir, 'config.json');
    final file = File(configPath);
    await file.writeAsString(jsonEncode(toJson()));
  }
}
