import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const kServerUrlKey = 'sync_server_url';
const kDefaultServerUrl = 'http://100.64.0.1:9847';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
      await prefs.setString(kServerUrlKey, url);
    }
    return url;
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await SettingsScreen.loadServerUrl();
    _controller.text = url;
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
      final uri = Uri.parse('$url/api/sync/deltas?since=0');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
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
    );
  }
}
