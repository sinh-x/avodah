import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/review_item.dart';
import '../services/review_provider.dart';

/// Shows full markdown content for a review item with action buttons.
///
/// Actions: Approve (green), Defer (orange), Reject (red with reason dialog).
class ItemDetailScreen extends StatefulWidget {
  final ReviewItem item;
  final ReviewProvider reviewProvider;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.reviewProvider,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ReviewItem? _detail;
  bool _loading = true;
  String? _error;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await widget.reviewProvider.getDetail(widget.item.id);
      if (mounted) {
        setState(() {
          _detail = detail;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : _buildContent(theme),
      bottomNavigationBar: _loading || _error != null
          ? null
          : _buildActionBar(theme),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load content',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadDetail();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final content = _detail?.content ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata bar
        _buildMetadataBar(theme),
        // Markdown content
        Expanded(
          child: Markdown(
            data: content,
            selectable: true,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataBar(ThemeData theme) {
    final item = _detail ?? widget.item;
    final chips = <Widget>[];

    if (item.from != null) {
      chips.add(Chip(
        avatar: const Icon(Icons.group, size: 16),
        label: Text(item.from!),
        visualDensity: VisualDensity.compact,
      ));
    }
    if (item.deployment != null) {
      chips.add(Chip(
        avatar: const Icon(Icons.rocket_launch, size: 16),
        label: Text(item.deployment!),
        visualDensity: VisualDensity.compact,
      ));
    }
    if (item.type != null) {
      chips.add(Chip(
        avatar: const Icon(Icons.label, size: 16),
        label: Text(item.type!),
        visualDensity: VisualDensity.compact,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            // Reject
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _acting ? null : _onReject,
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Defer
            Expanded(
              child: FilledButton.tonal(
                onPressed: _acting ? null : _onDefer,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                  foregroundColor: Colors.orange.shade800,
                ),
                child: const Text('Defer'),
              ),
            ),
            const SizedBox(width: 8),
            // Approve
            Expanded(
              child: FilledButton.icon(
                onPressed: _acting ? null : _onApprove,
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve item?'),
        content: Text('This will approve "${widget.item.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider.approve(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item approved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    }
  }

  Future<void> _onDefer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Defer item?'),
        content: Text('This will defer "${widget.item.title}" for later review.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Defer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider.defer(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deferred')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to defer: $e')),
        );
      }
    }
  }

  Future<void> _onReject() async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting "${widget.item.title}".'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Why are you rejecting this?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    reasonController.dispose();

    if (reason == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider.reject(
        widget.item.id,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item rejected')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    }
  }
}
