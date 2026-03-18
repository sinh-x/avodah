import 'dart:async';

import 'package:flutter/material.dart';

import '../models/snapshot.dart';

class TimerStatusBar extends StatefulWidget {
  final TimerSnapshot? timer;

  /// Called when user taps stop on a running timer.
  final Future<void> Function()? onStop;

  const TimerStatusBar({super.key, required this.timer, this.onStop});

  @override
  State<TimerStatusBar> createState() => _TimerStatusBarState();
}

class _TimerStatusBarState extends State<TimerStatusBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(TimerStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTickerIfNeeded();
  }

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    final timer = widget.timer;
    if (timer != null && timer.isRunning && !timer.isPaused) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = widget.timer;
    final theme = Theme.of(context);

    if (timer == null) {
      return Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.timer_off, color: theme.colorScheme.outline),
              const SizedBox(width: 12),
              Text('No timer running',
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    final Color cardColor;
    final Color textColor;
    final IconData icon;

    if (timer.isPaused) {
      cardColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
      icon = Icons.pause_circle;
    } else {
      cardColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
      icon = Icons.play_circle;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timer.taskTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (timer.note != null)
                    Text(
                      timer.note!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: textColor.withAlpha(180)),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              timer.liveElapsedFormatted,
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [const FontFeature.tabularFigures()]),
            ),
            if (widget.onStop != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.stop_circle, color: textColor, size: 28),
                tooltip: 'Stop timer',
                onPressed: widget.onStop,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
