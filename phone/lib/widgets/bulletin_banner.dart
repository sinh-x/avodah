import 'package:flutter/material.dart';

import '../models/bulletin.dart';

/// Banner widget displayed at the top of the Kanban board when active bulletins exist.
///
/// Collapses per-session via a dismiss button (does not resolve the bulletin).
/// When [onResolve] is provided, each bulletin shows a trailing resolve icon.
class BulletinBanner extends StatefulWidget {
  final List<Bulletin> bulletins;

  /// Called with the bulletin ID when the user requests resolution.
  final Future<void> Function(String id)? onResolve;

  const BulletinBanner({
    super.key,
    required this.bulletins,
    this.onResolve,
  });

  @override
  State<BulletinBanner> createState() => _BulletinBannerState();
}

class _BulletinBannerState extends State<BulletinBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || widget.bulletins.isEmpty) return const SizedBox.shrink();

    final isCritical = widget.bulletins.any((b) => b.blocksAll);
    final theme = Theme.of(context);
    final bgColor = isCritical
        ? theme.colorScheme.errorContainer
        : Colors.amber.shade100;
    final fgColor = isCritical
        ? theme.colorScheme.onErrorContainer
        : Colors.amber.shade900;

    return Container(
      width: double.infinity,
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Icon(
                  isCritical ? Icons.block : Icons.warning_amber,
                  size: 18,
                  color: fgColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.bulletins.length == 1
                        ? '1 active bulletin'
                        : '${widget.bulletins.length} active bulletins',
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: fgColor),
                  onPressed: () => setState(() => _dismissed = true),
                  tooltip: 'Dismiss',
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          ...widget.bulletins.map(
            (b) => _BulletinRow(
              bulletin: b,
              fgColor: fgColor,
              onResolve: widget.onResolve != null
                  ? () => widget.onResolve!(b.id)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// A single bulletin row inside the banner.
class _BulletinRow extends StatelessWidget {
  final Bulletin bulletin;
  final Color fgColor;
  final Future<void> Function()? onResolve;

  const _BulletinRow({
    required this.bulletin,
    required this.fgColor,
    this.onResolve,
  });

  String get _blockText {
    if (bulletin.blocksAll) return 'Blocking: all teams';
    final teams = bulletin.blockedTeams;
    if (teams.isEmpty) return '';
    return 'Blocking: ${teams.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final blockText = _blockText;
    final exceptText = bulletin.except.isNotEmpty
        ? 'Except: ${bulletin.except.join(', ')}'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bulletin.title,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (bulletin.message != null &&
                    bulletin.message!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bulletin.message!,
                    style: TextStyle(color: fgColor, fontSize: 12),
                  ),
                ],
                if (blockText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    blockText,
                    style: TextStyle(
                      color: fgColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (exceptText != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    exceptText,
                    style: TextStyle(
                      color: fgColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onResolve != null)
            _ResolveButton(fgColor: fgColor, onResolve: onResolve!),
        ],
      ),
    );
  }
}

class _ResolveButton extends StatefulWidget {
  final Color fgColor;
  final Future<void> Function() onResolve;

  const _ResolveButton({required this.fgColor, required this.onResolve});

  @override
  State<_ResolveButton> createState() => _ResolveButtonState();
}

class _ResolveButtonState extends State<_ResolveButton> {
  bool _resolving = false;

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.fgColor,
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(Icons.check_circle_outline, size: 18, color: widget.fgColor),
      onPressed: () async {
        setState(() => _resolving = true);
        try {
          await widget.onResolve();
        } finally {
          if (mounted) setState(() => _resolving = false);
        }
      },
      tooltip: 'Resolve bulletin',
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
