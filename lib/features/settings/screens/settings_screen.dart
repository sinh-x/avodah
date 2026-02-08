import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: const Text('System'),
            onTap: () {
              // TODO: Theme picker
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('Sync'),
            subtitle: const Text('Not configured'),
            onTap: () {
              // TODO: Sync settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.integration_instructions_outlined),
            title: const Text('Jira'),
            subtitle: const Text('Not connected'),
            onTap: () {
              // TODO: Jira settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('GitHub'),
            subtitle: const Text('Not connected'),
            onTap: () {
              // TODO: GitHub settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Avodah v0.1.0'),
            onTap: () {
              // TODO: About dialog
            },
          ),
        ],
      ),
    );
  }
}
