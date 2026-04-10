import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avodah_core/version.dart';
import '../services/agent_api_client.dart';
import '../services/crdt_sync_service.dart';

const kServerUrlKey = 'sync_server_url';
const kDefaultServerUrl = 'http://100.64.0.1:9847';

class SettingsScreen extends StatefulWidget {
  /// Optional API client for chip management. If not provided, creates one
  /// using the current saved server URL.
  final AgentApiClient? apiClient;

  /// Optional CRDT sync service for Forget Server functionality.
  /// If not provided, the Forget This Server button is hidden.
  final CrdtSyncService? crdtSyncService;

  const SettingsScreen({super.key, this.apiClient, this.crdtSyncService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  /// Loads the saved server URL, or returns the default.
  ///
  /// Auto-migrates legacy `ws://` URLs to `http://` (Phase 9 removed WebSocket).
  static Future<String> loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var url = prefs.getString(kServerUrlKey) ?? kDefaultServerUrl;
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
          const SnackBar(content: Text('Server forgotten. Please restart the app.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to forget server: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _forgetting = false);
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
    final client = AgentApiClient(baseUrl: url);
    setState(() => _loadingChips = true);
    try {
      final chips = await client.getAllCategoryChips();
      final categories = await client.getCategories();
      setState(() {
        _categoryChips = chips;
        _categories = categories.isNotEmpty ? categories : _getDefaultCategories();
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
    return ['Learning', 'Working', 'Side-project', 'Administrative', 'Meetings'];
  }

  Future<void> _addChip() async {
    final category = _selectedCategory;
    final chip = _chipController.text.trim();
    if (category == null || chip.isEmpty) return;

    // Always use fresh URL
    final url = await SettingsScreen.loadServerUrl();
    final client = AgentApiClient(baseUrl: url);

    final success = await client.addCategoryChip(category, chip);
    if (success) {
      _chipController.clear();
      await _loadChips();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "$chip" to $category')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add chip')),
        );
      }
    }
  }

  Future<void> _removeChip(String category, String chip) async {
    // Always use fresh URL
    final url = await SettingsScreen.loadServerUrl();
    final client = AgentApiClient(baseUrl: url);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove chip')),
        );
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
      final uri = Uri.parse('$url/api/health');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() => _testResult = 'Connected successfully!');
      } else {
        setState(
            () => _testResult = 'Connection failed: HTTP ${response.statusCode}');
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
    final client = AgentApiClient(baseUrl: url);

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
    _statusPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final client = AgentApiClient(baseUrl: url);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(snackMsg)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sync Server URL',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: kDefaultServerUrl,
                    border: OutlineInputBorder(),
                    helperText: 'Use your Tailscale IP, e.g. http://100.x.y.z:9847',
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
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Test Connection'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
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
          if (widget.crdtSyncService != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Server Connection',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Remove pairing with the current sync server.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _forgetting ? null : _forgetServer,
                      icon: _forgetting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.link_off, color: Colors.red),
                      label: Text(
                          _forgetting ? 'Forgetting...' : 'Forget This Server'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Comment Chip Presets',
                        style: Theme.of(context).textTheme.titleMedium),
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
                // Load chips when user taps the dropdown if not yet loaded
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _addChip(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addChip,
                    child: const Text('Add'),
                  ),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: Text('Avodah v$avodahVersion'),
          ),
          const Divider(),
          // Update App section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Updates',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Build and install the latest version on your device.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (_updateBuilding || _updateStatus != null) ...[
                  // Status display
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
          const SizedBox(height: 32),
        ],
      ),
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