import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// XDG-compliant path resolution for Avodah.
///
/// Follows the XDG Base Directory Specification:
/// - Data: ~/.local/share/avodah/
/// - Config: ~/.config/avodah/
/// - State: ~/.local/state/avodah/
/// - Cache: ~/.cache/avodah/
///
/// Override with:
/// 1. Constructor parameter (highest priority)
/// 2. AVODAH_DATA_DIR environment variable
/// 3. XDG defaults
class AvodahPaths {
  final String? _dataDir;
  final String? _configDir;

  /// Creates path resolver with optional overrides.
  AvodahPaths({
    String? dataDir,
    String? configDir,
  })  : _dataDir = dataDir,
        _configDir = configDir;

  /// Home directory.
  String get home => Platform.environment['HOME'] ?? '/tmp';

  /// Data directory (database, etc.).
  String get dataDir {
    // 1. Constructor override
    final override = _dataDir;
    if (override != null) return override;

    // 2. Environment variable
    final envOverride = Platform.environment['AVODAH_DATA_DIR'];
    if (envOverride != null) return envOverride;

    // 3. XDG default
    final xdgData = Platform.environment['XDG_DATA_HOME'] ?? p.join(home, '.local', 'share');
    return p.join(xdgData, 'avodah');
  }

  /// Config directory (settings, credentials).
  String get configDir {
    // 1. Constructor override
    final override = _configDir;
    if (override != null) return override;

    // 2. XDG default
    final xdgConfig = Platform.environment['XDG_CONFIG_HOME'] ?? p.join(home, '.config');
    return p.join(xdgConfig, 'avodah');
  }

  /// State directory (logs).
  String get stateDir {
    final xdgState = Platform.environment['XDG_STATE_HOME'] ?? p.join(home, '.local', 'state');
    return p.join(xdgState, 'avodah');
  }

  /// Cache directory.
  String get cacheDir {
    final xdgCache = Platform.environment['XDG_CACHE_HOME'] ?? p.join(home, '.cache');
    return p.join(xdgCache, 'avodah');
  }

  /// SQLite database path.
  String get databasePath => p.join(dataDir, 'avodah.db');

  /// Config file path.
  String get configPath => p.join(configDir, 'config.toml');

  /// Node ID file path.
  String get nodeIdPath => p.join(configDir, 'node-id');

  /// Jira credentials file path.
  String get jiraCredentialsPath => p.join(configDir, 'jira-credentials.json');

  /// Logs directory.
  String get logsDir => p.join(stateDir, 'logs');

  /// Ensures all necessary directories exist.
  Future<void> ensureDirectories() async {
    await Directory(dataDir).create(recursive: true);
    await Directory(configDir).create(recursive: true);
    await Directory(stateDir).create(recursive: true);
    await Directory(logsDir).create(recursive: true);
  }

  /// Gets or generates the unique node ID for CRDT.
  ///
  /// The node ID is persisted in ~/.config/avodah/node-id.
  /// If it doesn't exist, a new one is generated.
  Future<String> getNodeId() async {
    final file = File(nodeIdPath);

    if (await file.exists()) {
      final content = await file.readAsString();
      return content.trim();
    }

    // Generate new node ID
    final nodeId = _generateNodeId();
    await Directory(configDir).create(recursive: true);
    await file.writeAsString(nodeId);
    return nodeId;
  }

  /// Gets node ID synchronously (for use after ensureDirectories).
  String getNodeIdSync() {
    final file = File(nodeIdPath);

    if (file.existsSync()) {
      return file.readAsStringSync().trim();
    }

    // Generate new node ID
    final nodeId = _generateNodeId();
    Directory(configDir).createSync(recursive: true);
    file.writeAsStringSync(nodeId);
    return nodeId;
  }

  /// Generates a unique node ID.
  String _generateNodeId() {
    // Use short UUID + hostname for uniqueness and debuggability
    final shortId = const Uuid().v4().substring(0, 8);
    final hostname = Platform.localHostname;
    return 'node-$shortId-$hostname';
  }
}
