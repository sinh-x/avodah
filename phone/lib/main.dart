import 'dart:async';

import 'package:avodah_core/avodah_core.dart';
import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/deployment_screen.dart';
import 'screens/review_queue_screen.dart';
import 'screens/team_browser_screen.dart';
import 'screens/timers_screen.dart';
import 'services/agent_api_client.dart';
import 'services/crdt_sync_service.dart';
import 'services/deployment_provider.dart';
import 'services/local_dashboard_provider.dart';
import 'services/review_provider.dart';
import 'services/team_browser_provider.dart';
import 'settings/settings_screen.dart';
import 'storage/database.dart';

void main() {
  runApp(const AvodahViewerApp());
}

class AvodahViewerApp extends StatefulWidget {
  const AvodahViewerApp({super.key});

  @override
  State<AvodahViewerApp> createState() => _AvodahViewerAppState();
}

class _AvodahViewerAppState extends State<AvodahViewerApp> {
  AppDatabase? _db;
  LocalDashboardProvider? _dashboardProvider;
  CrdtSyncService? _crdtSyncService;
  AgentApiClient? _apiClient;
  ReviewProvider? _reviewProvider;
  DeploymentProvider? _deploymentProvider;
  TeamBrowserProvider? _teamBrowserProvider;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Open local database
    final db = await openPhoneDatabase();

    // Node ID + HLC clock
    final nodeId = await CrdtSyncService.getOrCreateNodeId();
    final clock = HybridLogicalClock(nodeId: nodeId);

    // Dashboard reads from local DB
    final dashboardProvider = LocalDashboardProvider(db: db, clock: clock);

    // Load stored server URL and build HTTP base URL
    final wsUrl = await SettingsScreen.loadServerUrl();
    final httpBaseUrl = _wsToHttp(wsUrl);

    // CRDT sync service pulls deltas from desktop via HTTP
    final crdtSyncService = CrdtSyncService(
      baseUrl: httpBaseUrl,
      db: db,
      clock: clock,
    );

    // Agent workflow API
    final apiClient = AgentApiClient(baseUrl: httpBaseUrl);
    final reviewProvider = ReviewProvider(apiClient);
    reviewProvider.startAutoRefresh();

    final deploymentProvider = DeploymentProvider(apiClient);
    deploymentProvider.refresh();

    final teamBrowserProvider = TeamBrowserProvider(apiClient);
    teamBrowserProvider.refreshTeams();
    teamBrowserProvider.loadPaTeams();

    setState(() {
      _db = db;
      _dashboardProvider = dashboardProvider;
      _crdtSyncService = crdtSyncService;
      _apiClient = apiClient;
      _reviewProvider = reviewProvider;
      _deploymentProvider = deploymentProvider;
      _teamBrowserProvider = teamBrowserProvider;
    });

    // Initial pull + dashboard render
    await _syncAndRefresh();

    // Periodic sync + refresh every 5 seconds while app is running
    _syncTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _syncAndRefresh(),
    );
  }

  /// Pull CRDT deltas from desktop, then refresh the dashboard from local DB.
  Future<void> _syncAndRefresh() async {
    final sync = _crdtSyncService;
    final dashboard = _dashboardProvider;
    if (sync == null || dashboard == null) return;
    try {
      await sync.pullFromDesktop();
    } catch (e) {
      // Sync failure is non-fatal — dashboard still shows local data
    }
    await dashboard.refresh();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _teamBrowserProvider?.dispose();
    _deploymentProvider?.dispose();
    _reviewProvider?.dispose();
    _apiClient?.dispose();
    _crdtSyncService?.dispose();
    _dashboardProvider?.dispose();
    _db?.close();
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
      home: _dashboardProvider == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _HomeShell(
              dashboardProvider: _dashboardProvider!,
              apiClient: _apiClient!,
              reviewProvider: _reviewProvider!,
              deploymentProvider: _deploymentProvider!,
              teamBrowserProvider: _teamBrowserProvider!,
            ),
    );
  }

  /// Converts a WebSocket URL (ws://) to HTTP (http://).
  static String _wsToHttp(String wsUrl) {
    final uri = Uri.parse(wsUrl);
    final httpUrl = uri.replace(scheme: 'http').toString();
    return httpUrl.endsWith('/')
        ? httpUrl.substring(0, httpUrl.length - 1)
        : httpUrl;
  }
}

/// Shell with bottom navigation between Dashboard, Agent Review, Deployments, and Teams.
class _HomeShell extends StatefulWidget {
  final LocalDashboardProvider dashboardProvider;
  final AgentApiClient apiClient;
  final ReviewProvider reviewProvider;
  final DeploymentProvider deploymentProvider;
  final TeamBrowserProvider teamBrowserProvider;

  const _HomeShell({
    required this.dashboardProvider,
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
          DashboardScreen(dashboardProvider: widget.dashboardProvider),
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
