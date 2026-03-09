import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  Future<void> _initClient() async {
    final url = await SettingsScreen.loadServerUrl();
    final client = SyncClient(serverUrl: url);
    client.connect();
    setState(() => _syncClient = client);
  }

  @override
  void dispose() {
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
          : DashboardScreen(syncClient: _syncClient!),
    );
  }
}
