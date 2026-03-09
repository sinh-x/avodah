import 'package:flutter/material.dart';

import '../services/sync_client.dart';

class ConnectionIndicator extends StatelessWidget {
  final SyncConnectionState state;

  const ConnectionIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String tooltip;

    switch (state) {
      case SyncConnectionState.connected:
        color = Colors.green;
        tooltip = 'Connected';
      case SyncConnectionState.connecting:
        color = Colors.amber;
        tooltip = 'Connecting...';
      case SyncConnectionState.disconnected:
        color = Colors.red;
        tooltip = 'Disconnected';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
