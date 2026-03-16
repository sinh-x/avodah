import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/deployment_screen.dart';
import 'screens/review_queue_screen.dart';
import 'screens/team_browser_screen.dart';
import 'screens/timers_screen.dart';
import 'services/agent_api_client.dart';
import 'services/deployment_provider.dart';
import 'services/review_provider.dart';
import 'services/team_browser_provider.dart';
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
  DeploymentProvider? _deploymentProvider;
  TeamBrowserProvider? _teamBrowserProvider;

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

    final deploymentProvider = DeploymentProvider(apiClient);
    deploymentProvider.refresh();

    final teamBrowserProvider = TeamBrowserProvider(apiClient);
    teamBrowserProvider.refreshTeams();
    teamBrowserProvider.loadPaTeams();

    setState(() {
      _syncClient = client;
      _apiClient = apiClient;
      _reviewProvider = reviewProvider;
      _deploymentProvider = deploymentProvider;
      _teamBrowserProvider = teamBrowserProvider;
    });
  }

  @override
  void dispose() {
    _teamBrowserProvider?.dispose();
    _deploymentProvider?.dispose();
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
              apiClient: _apiClient!,
              reviewProvider: _reviewProvider!,
              deploymentProvider: _deploymentProvider!,
              teamBrowserProvider: _teamBrowserProvider!,
            ),
    );
  }
}

/// Shell with bottom navigation between Dashboard, Agent Review, Deployments, and Teams.
class _HomeShell extends StatefulWidget {
  final SyncClient syncClient;
  final AgentApiClient apiClient;
  final ReviewProvider reviewProvider;
  final DeploymentProvider deploymentProvider;
  final TeamBrowserProvider teamBrowserProvider;

  const _HomeShell({
    required this.syncClient,
    required this.apiClient,
    required this.reviewProvider,
    required this.deploymentProvider,
    required this.teamBrowserProvider,
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
              reviewProvider: widget.reviewProvider,
              teamBrowserProvider: widget.teamBrowserProvider,
            ),
          ),
          Scaffold(
            appBar: AppBar(
              title: const Text('Deployments'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => widget.deploymentProvider.refresh(),
                ),
              ],
            ),
            body: DeploymentScreen(
                deploymentProvider: widget.deploymentProvider),
          ),
          Scaffold(
            appBar: AppBar(
              title: const Text('Teams'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.timer_outlined),
                  tooltip: 'PA Timers',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TimersScreen(apiClient: widget.apiClient),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => widget.teamBrowserProvider.refreshTeams(),
                ),
              ],
            ),
            body: TeamBrowserScreen(
                teamProvider: widget.teamBrowserProvider),
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
          const NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch),
            label: 'Deployments',
          ),
          const NavigationDestination(
            icon: Icon(Icons.group_work_outlined),
            selectedIcon: Icon(Icons.group_work),
            label: 'Teams',
          ),
        ],
      ),
    );
  }
}
