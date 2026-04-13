import 'dart:async';

import 'package:avodah_core/avodah_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'screens/dashboard_screen.dart';
import 'screens/deployment_screen.dart';
import 'screens/kanban_board_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/review_queue_screen.dart';
import 'screens/team_browser_screen.dart';
import 'screens/timers_screen.dart';
import 'services/agent_api_client.dart';
import 'services/board_provider.dart';
import 'services/crdt_sync_service.dart';
import 'services/crypto_sync_service.dart';
import 'services/deployment_provider.dart';
import 'services/display_settings_service.dart';
import 'services/focus_provider.dart';
import 'services/local_dashboard_provider.dart';
import 'services/local_write_service.dart';
import 'services/review_provider.dart';
import 'services/team_browser_provider.dart';
import 'settings/settings_screen.dart';
import 'storage/database.dart';
import 'widgets/connection_indicator.dart';

void main() {
  runApp(const AvodahViewerApp());
}

class AvodahViewerApp extends StatefulWidget {
  const AvodahViewerApp({super.key});

  @override
  State<AvodahViewerApp> createState() => _AvodahViewerAppState();
}

class _AvodahViewerAppState extends State<AvodahViewerApp>
    with WidgetsBindingObserver {
  AppDatabase? _db;
  LocalDashboardProvider? _dashboardProvider;
  LocalWriteService? _writeService;
  CrdtSyncService? _crdtSyncService;
  CryptoSyncService? _cryptoSyncService;
  AgentApiClient? _apiClient;
  ReviewProvider? _reviewProvider;
  DeploymentProvider? _deploymentProvider;
  TeamBrowserProvider? _teamBrowserProvider;
  BoardProvider? _boardProvider;
  FocusProvider? _focusProvider;
  DisplaySettingsService? _displaySettings;
  Timer? _syncTimer;
  bool _pairingInProgress = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final List<Map<String, dynamic>> _pendingTimerDeltas = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await _initAppInner();
    } catch (e, st) {
      debugPrint('[Init] Fatal error during app initialization: $e\n$st');
      // Show error state instead of infinite loading spinner
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  String? _initError;

  Future<void> _initAppInner() async {
    // Open local database
    final db = await openPhoneDatabase();

    // Node ID + HLC clock
    final nodeId = await CrdtSyncService.getOrCreateNodeId();
    final clock = HybridLogicalClock(nodeId: nodeId);

    // Dashboard reads from local DB
    final dashboardProvider = LocalDashboardProvider(db: db, clock: clock);

    // Write service for local CRDT mutations (timer, task, worklog)
    final writeService = LocalWriteService(db: db, clock: clock);

    // One-time backfill: set category on worklogs from task-level timers
    await writeService.backfillWorklogCategories();

    // Load stored server URL (already HTTP format)
    final httpBaseUrl = await SettingsScreen.loadServerUrl();

    // TLS-capable HTTP client with certificate verification.
    // dart:io HttpClient is not available on web — skip CryptoSyncService
    // entirely. On web, the browser handles TLS natively, and the Caddy
    // reverse proxy makes cert pinning unnecessary.
    CryptoSyncService? cryptoSyncService;
    if (!kIsWeb) {
      cryptoSyncService = CryptoSyncService(
        baseUrl: httpBaseUrl,
        nodeId: nodeId,
      );
      await cryptoSyncService.loadPersistedState();
    }

    // CRDT sync service with TLS + pairing integration
    final crdtSyncService = CrdtSyncService(
      baseUrl: httpBaseUrl,
      db: db,
      clock: clock,
      cryptoClient: cryptoSyncService,
      nodeId: nodeId,
      onNeedsPairing: _onNeedsPairing,
    );
    await crdtSyncService.loadPersistedState();

    // Agent workflow API — inject pairing credentials for authenticated proxy
    final apiClient = AgentApiClient(baseUrl: httpBaseUrl)
      ..pairingToken = cryptoSyncService?.pairingToken
      ..nodeId = nodeId;
    final reviewProvider = ReviewProvider(apiClient);
    reviewProvider.startAutoRefresh();

    final deploymentProvider = DeploymentProvider(apiClient);
    deploymentProvider.startAutoRefresh();

    final teamBrowserProvider = TeamBrowserProvider(apiClient);
    teamBrowserProvider.refreshTeams();
    teamBrowserProvider.loadPaTeams();

    final boardProvider = BoardProvider(apiClient);
    boardProvider.refresh();
    boardProvider.startPolling();

    final focusProvider = FocusProvider(apiClient);
    focusProvider.startPolling();

    // Display settings (brightness, accent color, contrast)
    final displaySettings = DisplaySettingsService();
    await displaySettings.load();

    setState(() {
      _db = db;
      _dashboardProvider = dashboardProvider;
      _writeService = writeService;
      _crdtSyncService = crdtSyncService;
      _cryptoSyncService = cryptoSyncService;
      _apiClient = apiClient;
      _reviewProvider = reviewProvider;
      _deploymentProvider = deploymentProvider;
      _teamBrowserProvider = teamBrowserProvider;
      _boardProvider = boardProvider;
      _focusProvider = focusProvider;
      _displaySettings = displaySettings;
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
  /// pullFromDesktop() is called on EVERY cycle regardless of prior failure state.
  /// When already disconnected, skip the pull to avoid 10s blocking timeout
  /// and just refresh the local dashboard.
  Future<void> _syncAndRefresh() async {
    final sync = _crdtSyncService;
    final dashboard = _dashboardProvider;
    if (sync == null || dashboard == null) return;
    var syncOk = false;

    // If already disconnected, skip pull to avoid blocking 10s TCP timeout.
    // Just refresh the local dashboard and retry pull on next cycle.
    final alreadyOffline =
        dashboard.connectionState.value == SyncConnectionState.disconnected;

    if (!alreadyOffline) {
      try {
        await sync.pullFromDesktop();
        syncOk = true;
        // Flush queued timer deltas after successful pull
        if (_pendingTimerDeltas.isNotEmpty) {
          final queued = List<Map<String, dynamic>>.from(_pendingTimerDeltas);
          _pendingTimerDeltas.clear();
          try {
            await sync.pushToDesktop(queued);
            debugPrint('[Sync] Flushed ${queued.length} queued timer delta(s)');
          } catch (e) {
            debugPrint('[Sync] Queued timer push failed: $e — re-queueing');
            _pendingTimerDeltas.addAll(queued);
          }
        }
      } catch (e) {
        debugPrint('[Sync] Pull failed: $e');
        // Surface pull failure to user via snackbar (AC4)
        final messenger = _scaffoldMessengerKey.currentState;
        if (messenger != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Sync failed — will retry on next cycle'),
                duration: Duration(seconds: 4),
              ),
            );
          });
        } else {
          debugPrint('[Sync] Pull failed but ScaffoldMessenger unavailable '
              'for snackbar notification');
        }
      }
    } else {
      debugPrint('[Sync] Skipping pull — already offline');
    }

    await dashboard.refresh();
    // Override the indicator to reflect actual sync status, not just local DB read
    if (!syncOk) {
      dashboard.connectionState.value = SyncConnectionState.disconnected;
    }
  }

  /// Push CRDT deltas from phone to desktop (non-fatal on failure).
  /// Timer deltas that fail to push are queued and retried on the next sync cycle.
  Future<void> _pushDeltas(List<Map<String, dynamic>> deltas) async {
    if (deltas.isEmpty) return;

    // Queue timer deltas on failure for later retry
    final timerDeltas = deltas.where((d) => d['type'] == 'timer').toList();

    try {
      // Always try to push all deltas together
      await _crdtSyncService?.pushToDesktop(deltas);
      // On success, flush any queued timer deltas too
      if (_pendingTimerDeltas.isNotEmpty) {
        final queued = List<Map<String, dynamic>>.from(_pendingTimerDeltas);
        _pendingTimerDeltas.clear();
        try {
          await _crdtSyncService?.pushToDesktop(queued);
        } catch (e) {
          debugPrint('[Sync] Queued timer push failed: $e');
          _pendingTimerDeltas.addAll(queued);
        }
      }
    } catch (e) {
      debugPrint('[Sync] Push failed: $e');
      // Queue timer deltas for retry; non-timer deltas are dropped (fire-and-forget)
      if (timerDeltas.isNotEmpty) {
        _pendingTimerDeltas.addAll(timerDeltas);
        debugPrint('[Sync] Queued ${timerDeltas.length} timer delta(s) for retry');
      }
      // Surface failure to user via snackbar (not spam — ScaffoldMessenger
      // only shows one snackbar at a time)
      final messenger = _scaffoldMessengerKey.currentState;
      if (messenger != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('Sync failed${_pendingTimerDeltas.isNotEmpty ? ' — timer will retry' : ''}'),
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }
    }
  }

  /// Shows the certificate approval dialog if a cert is pending approval.
  ///
  /// Returns true if approved, false if rejected.
  Future<bool> _handlePendingCertApproval() async {
    final crypto = _cryptoSyncService;
    if (crypto == null) return false;

    final fingerprint = crypto.checkPendingCertFingerprint();
    if (fingerprint == null) return false;

    if (!mounted) return false;
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return false;
    final approved = await showDialog<bool>(
      context: navContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.security, color: Colors.amber, size: 48),
        title: const Text('Certificate Not Trusted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The server\'s TLS certificate could not be verified. '
              'This may happen with self-signed certificates.',
            ),
            const SizedBox(height: 16),
            const Text(
              'SHA-256 Fingerprint:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fingerprint,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    final result = approved ?? false;
    if (result) {
      await crypto.approveCert(fingerprint);
    } else {
      crypto.rejectCert();
    }
    return result;
  }

  /// Called when sync reports needsPairing:true or HTTP 403.
  Future<void> _onNeedsPairing() async {
    // Guard against re-entrant calls from the periodic sync timer
    if (_pairingInProgress) return;
    if (!mounted) return;
    final crypto = _cryptoSyncService;
    final crdt = _crdtSyncService;
    if (crypto == null || crdt == null) return;

    _pairingInProgress = true;
    try {
      // Handle pending cert approval if any
      await _handlePendingCertApproval();

      final nodeId = await CrdtSyncService.getOrCreateNodeId();
      if (!mounted) return;

      final nav = _navigatorKey.currentState;
      if (nav == null) return;

      // Push the pairing screen as a blocking route
      final result = await nav.push<bool>(
        MaterialPageRoute(
          builder: (_) => PairingScreen(
            args: PairingScreenArgs(
              cryptoClient: crypto,
              nodeId: nodeId,
            ),
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        // Pairing succeeded — reload persisted state and trigger sync
        await crdt.loadPersistedState();
        // Update API client with new pairing token
        _apiClient?.pairingToken = crypto.pairingToken;
        await _syncAndRefresh();
      }
    } finally {
      _pairingInProgress = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Pull on resume: fetch any changes that happened on desktop
      // while phone was backgrounded
      _syncAndRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _focusProvider?.dispose();
    _boardProvider?.dispose();
    _teamBrowserProvider?.dispose();
    _deploymentProvider?.dispose();
    _reviewProvider?.dispose();
    _apiClient?.dispose();
    _crdtSyncService?.dispose();
    _cryptoSyncService?.dispose();
    _dashboardProvider?.dispose();
    _displaySettings?.dispose();
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = _displaySettings;
    final notifier = display ?? _NullNotifier();

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final syntaxColors = display?.contrast == DisplayContrast.high
            ? SyntaxColors.high
            : SyntaxColors.normal;
        final syntaxTheme = SyntaxThemeExtension(syntaxColors: syntaxColors);

        return MaterialApp(
          scaffoldMessengerKey: _scaffoldMessengerKey,
          navigatorKey: _navigatorKey,
          title: 'Avodah',
          debugShowCheckedModeBanner: false,
          theme: display?.lightTheme().copyWith(
                extensions: [syntaxTheme],
              ) ??
              ThemeData(
                colorSchemeSeed: const Color(0xFF6750A4),
                useMaterial3: true,
                brightness: Brightness.light,
                extensions: [syntaxTheme],
              ),
          darkTheme: display?.darkTheme().copyWith(
                extensions: [syntaxTheme],
              ) ??
              ThemeData(
                colorSchemeSeed: const Color(0xFF6750A4),
                useMaterial3: true,
                brightness: Brightness.dark,
                extensions: [syntaxTheme],
              ),
          themeMode: display != null ? ThemeMode.system : ThemeMode.light,
          home: _initError != null
              ? Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text('Failed to initialize',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text(_initError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              : _dashboardProvider == null
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : _HomeShell(
                  dashboardProvider: _dashboardProvider!,
                  writeService: _writeService!,
                  apiClient: _apiClient!,
                  reviewProvider: _reviewProvider!,
                  deploymentProvider: _deploymentProvider!,
                  teamBrowserProvider: _teamBrowserProvider!,
                  boardProvider: _boardProvider!,
                  focusProvider: _focusProvider,
                  onPushDeltas: _pushDeltas,
                  crdtSyncService: _crdtSyncService,
                  displaySettings: _displaySettings,
                ),
        );
      },
    );
  }
}

/// A no-op Listenable used when display settings hasn't loaded yet.
class _NullNotifier extends ChangeNotifier {
  _NullNotifier();
}

/// Shell with bottom navigation between Kanban, Dashboard, Agent Review, Deployments, and Teams.
class _HomeShell extends StatefulWidget {
  final LocalDashboardProvider dashboardProvider;
  final LocalWriteService writeService;
  final AgentApiClient apiClient;
  final ReviewProvider reviewProvider;
  final DeploymentProvider deploymentProvider;
  final TeamBrowserProvider teamBrowserProvider;
  final BoardProvider boardProvider;
  final FocusProvider? focusProvider;
  final Future<void> Function(List<Map<String, dynamic>>)? onPushDeltas;
  final CrdtSyncService? crdtSyncService;
  final DisplaySettingsService? displaySettings;

  const _HomeShell({
    required this.dashboardProvider,
    required this.writeService,
    required this.apiClient,
    required this.reviewProvider,
    required this.deploymentProvider,
    required this.teamBrowserProvider,
    required this.boardProvider,
    this.focusProvider,
    this.onPushDeltas,
    this.crdtSyncService,
    this.displaySettings,
  });

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.reviewProvider.addListener(_onUpdate);
    widget.boardProvider.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.reviewProvider.removeListener(_onUpdate);
    widget.boardProvider.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.reviewProvider.pendingCount;
    final actionableCount = widget.boardProvider.actionableCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          KanbanBoardScreen(
              boardProvider: widget.boardProvider,
              dashboardProvider: widget.dashboardProvider,
              focusProvider: widget.focusProvider,
              deploymentProvider: widget.deploymentProvider,
              crdtSyncService: widget.crdtSyncService,
              apiClient: widget.apiClient,
              displaySettings: widget.displaySettings,
            ),
          DashboardScreen(
            dashboardProvider: widget.dashboardProvider,
            writeService: widget.writeService,
            apiClient: widget.apiClient,
            onPushDeltas: widget.onPushDeltas,
            crdtSyncService: widget.crdtSyncService,
            displaySettings: widget.displaySettings,
          ),
          Scaffold(
            appBar: AppBar(
              title: const Text('Agent Review'),
              actions: [
                ValueListenableBuilder<SyncConnectionState>(
                  valueListenable: widget.dashboardProvider.connectionState,
                  builder: (_, state, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConnectionIndicator(state: state),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                        apiClient: widget.apiClient,
                        crdtSyncService: widget.crdtSyncService,
                        displaySettings: widget.displaySettings)),
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
                ValueListenableBuilder<SyncConnectionState>(
                  valueListenable: widget.dashboardProvider.connectionState,
                  builder: (_, state, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConnectionIndicator(state: state),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                        apiClient: widget.apiClient,
                        crdtSyncService: widget.crdtSyncService,
                        displaySettings: widget.displaySettings)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => widget.deploymentProvider.refresh(),
                ),
              ],
            ),
            body: DeploymentScreen(
              deploymentProvider: widget.deploymentProvider,
              apiClient: widget.apiClient,
            ),
          ),
          Scaffold(
            appBar: AppBar(
              title: const Text('Teams'),
              actions: [
                ValueListenableBuilder<SyncConnectionState>(
                  valueListenable: widget.dashboardProvider.connectionState,
                  builder: (_, state, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConnectionIndicator(state: state),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                        apiClient: widget.apiClient,
                        crdtSyncService: widget.crdtSyncService,
                        displaySettings: widget.displaySettings)),
                  ),
                ),
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
          NavigationDestination(
            icon: actionableCount > 0
                ? Badge(
                    label: Text('$actionableCount'),
                    child: const Icon(Icons.view_kanban_outlined),
                  )
                : const Icon(Icons.view_kanban_outlined),
            selectedIcon: actionableCount > 0
                ? Badge(
                    label: Text('$actionableCount'),
                    child: const Icon(Icons.view_kanban),
                  )
                : const Icon(Icons.view_kanban),
            label: 'Kanban',
          ),
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
