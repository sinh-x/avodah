import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/review_queue_screen.dart';
import 'services/agent_api_client.dart';
import 'services/review_provider.dart';
import 'services/sync_client.dart';
import 'settings/settings_screen.dart';

void main() {
  runApp(const AvodahViewerApp());
}

class AvodahViewerApp extends StatefulWidget {
  const AvodahViewerApp({super.key});

  @override
  State<AvodahViewerApp> createState() => _AvodahViewerAppState();
}

class _AvodahViewerAppState extends State<AvodahViewerApp> {
  SyncClient? _syncClient;
  AgentApiClient? _apiClient;
  ReviewProvider? _reviewProvider;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  Future<void> _initClient() async {
    final url = await SettingsScreen.loadServerUrl();
    final client = SyncClient(serverUrl: url);
    client.connect();

    final apiClient = AgentApiClient.fromWsUrl(url);
    final reviewProvider = ReviewProvider(apiClient);
    reviewProvider.startAutoRefresh();

    setState(() {
      _syncClient = client;
      _apiClient = apiClient;
      _reviewProvider = reviewProvider;
    });
  }

  @override
  void dispose() {
    _reviewProvider?.dispose();
    _apiClient?.dispose();
    _syncClient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avodah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: _syncClient == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _HomeShell(
              syncClient: _syncClient!,
              reviewProvider: _reviewProvider!,
            ),
    );
  }
}

/// Shell with bottom navigation between Dashboard and Agent Review.
class _HomeShell extends StatefulWidget {
  final SyncClient syncClient;
  final ReviewProvider reviewProvider;

  const _HomeShell({
    required this.syncClient,
    required this.reviewProvider,
  });

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.reviewProvider.addListener(_onReviewUpdate);
  }

  @override
  void dispose() {
    widget.reviewProvider.removeListener(_onReviewUpdate);
    super.dispose();
  }

  void _onReviewUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.reviewProvider.pendingCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(syncClient: widget.syncClient),
          Scaffold(
            appBar: AppBar(
              title: const Text('Agent Review'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            body: ReviewQueueScreen(
                reviewProvider: widget.reviewProvider),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: pendingCount > 0
                ? Badge(
                    label: Text('$pendingCount'),
                    child: const Icon(Icons.assignment_outlined),
                  )
                : const Icon(Icons.assignment_outlined),
            selectedIcon: pendingCount > 0
                ? Badge(
                    label: Text('$pendingCount'),
                    child: const Icon(Icons.assignment_turned_in),
                  )
                : const Icon(Icons.assignment_turned_in),
            label: 'Agent Review',
          ),
        ],
      ),
    );
  }
}
