import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avodah_core/version.dart';
import '../services/agent_api_client.dart';
import '../services/crdt_sync_service.dart';
import '../services/display_settings_service.dart';

const kServerUrlKey = 'sync_server_url';
const kDefaultServerUrl = 'https://drgnfly.tail10c2c6.ts.net/avodah';

class SettingsScreen extends StatefulWidget {
  /// Optional API client for chip management. If not provided, creates one
  /// using the current saved server URL.
  final AgentApiClient? apiClient;

  /// Optional CRDT sync service for Forget Server functionality.
  /// If not provided, the Forget This Server button is hidden.
  final CrdtSyncService? crdtSyncService;

  /// Optional app-level display settings service. If not provided,
  /// _DisplaySettingsSection creates its own (dual-instance bug fix).
  final DisplaySettingsService? displaySettings;

  const SettingsScreen({
    super.key,
    this.apiClient,
    this.crdtSyncService,
    this.displaySettings,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  /// Loads the saved server URL, or returns the default.
  ///
  /// Auto-migrates legacy `ws://` URLs to `http://` (Phase 9 removed WebSocket).
  /// On web, defaults to the page's own origin (same-origin requests go through
  /// the Caddy reverse proxy) instead of the hardcoded Tailscale IP.
  static Future<String> loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    // On web, Uri.base comes from <base href> in index.html (set at build time
    // via --base-href). It already includes the reverse-proxy mount path, so
    // same-origin API calls go through the correct Caddy route.
    final defaultUrl = kIsWeb ? Uri.base.toString() : kDefaultServerUrl;
    var storedUrl = prefs.getString(kServerUrlKey);
    // On web, migrate any stored URL that's missing the app's mount path
    // (e.g. from an older build that used Uri.base.origin).
    if (kIsWeb && storedUrl != null) {
      final baseUri = Uri.base;
      final storedUri = Uri.tryParse(storedUrl);
      if (storedUri != null &&
          storedUri.origin == baseUri.origin &&
          storedUri.path.replaceAll('/', '').isEmpty &&
          baseUri.path.replaceAll('/', '').isNotEmpty) {
        storedUrl = null; // force re-default to pick up the correct mount path
      }
    }
    var url = storedUrl ?? defaultUrl;
    if (url.startsWith('ws://') || url.startsWith('wss://')) {
      url = url.replaceFirst(RegExp(r'^wss?://'), 'http://');
    }
    // Strip trailing slashes to avoid double-slash in API paths
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    await prefs.setString(kServerUrlKey, url);
    return url;
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _testing = false;
  String? _testResult;

  /// All categories with their chip presets.
  Map<String, List<String>> _categoryChips = {};

  /// Categories list for the picker.
  List<String> _categories = [];

  /// Currently selected category for chip management.
  String? _selectedCategory;

  /// Text controller for adding new chips.
  final _chipController = TextEditingController();

  /// Whether chip data is being loaded.
  bool _loadingChips = false;

  /// Self-update build state.
  bool _updateBuilding = false;
  String? _updateStatus;
  List<String> _updateLog = [];

  /// Polling timer for build status.
  Timer? _statusPollTimer;

  /// Whether Forget Server is in progress.
  bool _forgetting = false;

  /// Whether Force Full Sync is in progress.
  bool _fullSyncing = false;

  /// Triggers the Forget Server confirmation and revocation flow.
  Future<void> _forgetServer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget This Server?'),
        content: const Text(
          'This will remove pairing with the current sync server. '
          'You will need to pair again to resume sync.\n\n'
          'Your local data will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Forget Server'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _forgetting = true);

    try {
      await widget.crdtSyncService?.revokePairing();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server forgotten. Please restart the app.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to forget server: $e')));
      }
    } finally {
      if (mounted) setState(() => _forgetting = false);
    }
  }

  Future<void> _forceFullSync() async {
    setState(() => _fullSyncing = true);
    try {
      final pushed = await widget.crdtSyncService?.forceFullSync() ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Full sync complete. Pushed $pushed deltas. Pull will refresh shortly.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Full sync failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _fullSyncing = false);
    }
  }

  Future<void> _showP2pDiagnostics() async {
    final sync = widget.crdtSyncService;
    if (sync == null) return;

    try {
      final diagnostics = await sync.debugDiagnostics();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('P2P Sync Diagnostics'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                diagnostics.toDebugText(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Diagnostics failed: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUrl();
    _loadChips();
  }

  Future<void> _loadUrl() async {
    final url = await SettingsScreen.loadServerUrl();
    _controller.text = url;
  }

  Future<void> _loadChips() async {
    // Always use fresh URL for chip operations
    final url = await SettingsScreen.loadServerUrl();
    final client = widget.apiClient ?? AgentApiClient(baseUrl: url);
    setState(() => _loadingChips = true);
    try {
      final chips = await client.getAllCategoryChips();
      final categories = await client.getCategories();
      setState(() {
        _categoryChips = chips;
        _categories = categories.isNotEmpty
            ? categories
            : _getDefaultCategories();
        _loadingChips = false;
      });
    } catch (e) {
      setState(() {
        _categoryChips = {};
        _categories = _getDefaultCategories();
        _loadingChips = false;
      });
    }
  }

  List<String> _getDefaultCategories() {
    return [
      'Learning',
      'Working',
      'Side-project',
      'Administrative',
      'Meetings',
    ];
  }

  Future<void> _addChip() async {
    final category = _selectedCategory;
    final chip = _chipController.text.trim();
    if (category == null || chip.isEmpty) return;

    // Always use fresh URL
    final url = await SettingsScreen.loadServerUrl();
    final client = widget.apiClient ?? AgentApiClient(baseUrl: url);

    final success = await client.addCategoryChip(category, chip);
    if (success) {
      _chipController.clear();
      await _loadChips();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added "$chip" to $category')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add chip')));
      }
    }
  }

  Future<void> _removeChip(String category, String chip) async {
    // Always use fresh URL
    final url = await SettingsScreen.loadServerUrl();
    final client = widget.apiClient ?? AgentApiClient(baseUrl: url);

    final success = await client.removeCategoryChip(category, chip);
    if (success) {
      await _loadChips();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed "$chip" from $category')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to remove chip')));
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kServerUrlKey, _controller.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved. Restart app to reconnect.')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final url = _controller.text.trim();
      // Use root health endpoint (no auth required)
      final uri = Uri.parse('$url/');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() => _testResult = 'Connected successfully!');
      } else {
        setState(
          () => _testResult = 'Connection failed: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() => _testResult = 'Connection failed: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chipController.dispose();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _triggerSelfUpdate() async {
    final url = await SettingsScreen.loadServerUrl();
    final client = widget.apiClient ?? AgentApiClient(baseUrl: url);

    final result = await client.triggerSelfUpdate();
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to trigger update')),
        );
      }
      return;
    }

    setState(() {
      _updateBuilding = true;
      _updateStatus = 'Building...';
      _updateLog = ['Started at ${result.startedAt}'];
    });

    _startStatusPolling(url);
  }

  void _startStatusPolling(String url) {
    _statusPollTimer?.cancel();
    final client = widget.apiClient ?? AgentApiClient(baseUrl: url);
    _statusPollTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      final status = await client.getSelfUpdateStatus();

      if (status == null) return;

      setState(() {
        _updateLog = status.log;
        if (status.isBuilding) {
          _updateStatus = 'Building...';
        } else if (status.isSuccess) {
          _updateStatus = 'Update complete!';
          _updateBuilding = false;
          timer.cancel();
        } else if (status.isError) {
          _updateStatus = 'Build failed';
          _updateBuilding = false;
          timer.cancel();
        }
      });

      if (!status.isBuilding) {
        timer.cancel();
        if (mounted) {
          final snackMsg = status.isSuccess
              ? 'Update complete!'
              : 'Build failed. Check logs for details.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(snackMsg)));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.palette), text: 'Appearance'),
              Tab(icon: Icon(Icons.tune), text: 'Input'),
              Tab(icon: Icon(Icons.settings_ethernet), text: 'Technical'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppearanceTab(),
            _buildInputTab(),
            _buildTechnicalTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceTab() {
    if (widget.displaySettings == null) {
      return const Center(child: Text('Display settings unavailable'));
    }
    return ListView(
      children: [
        _DisplaySettingsSection(service: widget.displaySettings!),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInputTab() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comment Chip Presets',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      _selectedCategory = null;
                      await _loadChips();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage quick comment chips shown when stopping a timer.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        // Category selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedCategory,
            hint: const Text('Select a category'),
            items: _categories.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value);
            },
            onTap: () async {
              if (_categories.isEmpty) {
                await _loadChips();
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        // Add chip row
        if (_selectedCategory != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chipController,
                    decoration: const InputDecoration(
                      hintText: 'New chip text',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addChip(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addChip, child: const Text('Add')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Chips list for selected category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _loadingChips
                ? const Center(child: CircularProgressIndicator())
                : _buildChipsList(),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTechnicalTab() {
    return ListView(
      children: [
        // Sync Server URL
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sync Server URL',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: kDefaultServerUrl,
                  border: OutlineInputBorder(),
                  helperText: 'e.g. https://your-host.ts.net:9847',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _testing ? null : _testConnection,
                    child: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test Connection'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Text(
                  _testResult!,
                  style: TextStyle(
                    color: _testResult!.startsWith('Connected')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(),
        // Server Connection
        if (widget.crdtSyncService != null) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Server Connection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Remove pairing with the current sync server.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _fullSyncing ? null : _forceFullSync,
                    icon: _fullSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      _fullSyncing ? 'Syncing...' : 'Force Full Sync',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Re-downloads all data from the server.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showP2pDiagnostics,
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('P2P Sync Diagnostics'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Shows local worklog counts, watermarks, and last push result.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _forgetting ? null : _forgetServer,
                    icon: _forgetting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link_off, color: Colors.red),
                    label: Text(
                      _forgetting ? 'Forgetting...' : 'Forget This Server',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
        // App Updates
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Updates',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Build and install the latest version on your device.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (_updateBuilding || _updateStatus != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _updateStatus == 'Update complete!'
                        ? Colors.green.shade50
                        : _updateStatus == 'Build failed'
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _updateStatus == 'Update complete!'
                          ? Colors.green.shade200
                          : _updateStatus == 'Build failed'
                          ? Colors.red.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_updateBuilding)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              _updateStatus == 'Update complete!'
                                  ? Icons.check_circle
                                  : Icons.error,
                              size: 16,
                              color: _updateStatus == 'Update complete!'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _updateStatus ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _updateStatus == 'Update complete!'
                                    ? Colors.green.shade700
                                    : _updateStatus == 'Build failed'
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_updateLog.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _updateLog.take(5).join('\n'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _updateBuilding ? null : _triggerSelfUpdate,
                  icon: const Icon(Icons.system_update),
                  label: Text(_updateBuilding ? 'Building...' : 'Update App'),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // About
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          subtitle: Text('Avodah v$avodahVersion'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildChipsList() {
    final chips = _selectedCategory != null
        ? (_categoryChips[_selectedCategory] ?? [])
        : <String>[];

    if (chips.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No chips for this category yet.\nAdd one using the field above.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        return Chip(
          label: Text(chip),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => _removeChip(_selectedCategory!, chip),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Display Settings Section
// ---------------------------------------------------------------------------

class _DisplaySettingsSection extends StatefulWidget {
  final DisplaySettingsService service;

  const _DisplaySettingsSection({required this.service});

  @override
  State<_DisplaySettingsSection> createState() =>
      _DisplaySettingsSectionState();
}

class _DisplaySettingsSectionState extends State<_DisplaySettingsSection> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.service.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  DisplaySettingsService get _service => widget.service;

  @override
  void dispose() {
    // Service is owned by app-level main.dart, not disposed here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        if (!_loaded) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Display', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'Customize brightness, accent color, and contrast.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Brightness
              Text('Brightness', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              SegmentedButton<DisplayBrightness>(
                segments: const [
                  ButtonSegment(
                    value: DisplayBrightness.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: DisplayBrightness.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: DisplayBrightness.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                ],
                selected: {_service.brightness},
                onSelectionChanged: (selected) {
                  _service.setBrightness(selected.first);
                },
              ),
              const SizedBox(height: 20),

              // Accent color
              Text(
                'Accent Color',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAccentColors.map((color) {
                  final isSelected =
                      _service.accentColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => _service.setAccentColor(color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(128),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Contrast
              Text('Contrast', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              SegmentedButton<DisplayContrast>(
                segments: const [
                  ButtonSegment(
                    value: DisplayContrast.normal,
                    label: Text('Normal'),
                    icon: Icon(Icons.text_fields),
                  ),
                  ButtonSegment(
                    value: DisplayContrast.high,
                    label: Text('High'),
                    icon: Icon(Icons.contrast),
                  ),
                ],
                selected: {_service.contrast},
                onSelectionChanged: (selected) {
                  _service.setContrast(selected.first);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
