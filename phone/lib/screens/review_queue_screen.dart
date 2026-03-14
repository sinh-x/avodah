import 'package:flutter/material.dart';

import '../models/review_item.dart';
import '../services/review_provider.dart';
import 'item_detail_screen.dart';

/// Lists inbox items for agent workflow review.
///
/// Supports pull-to-refresh, auto-refresh (via [ReviewProvider]),
/// filter between inbox and for-later views, and shows error/empty states.
class ReviewQueueScreen extends StatefulWidget {
  final ReviewProvider reviewProvider;

  const ReviewQueueScreen({super.key, required this.reviewProvider});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  bool _showForLater = false;
  bool _forLaterLoading = false;

  @override
  void initState() {
    super.initState();
    widget.reviewProvider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    widget.reviewProvider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _switchToForLater() async {
    setState(() {
      _showForLater = true;
      _forLaterLoading = true;
    });
    await widget.reviewProvider.fetchForLater();
    if (mounted) setState(() => _forLaterLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.reviewProvider;
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildFilterBar(theme),
        Expanded(child: _buildBody(theme, provider)),
      ],
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Inbox'),
            selected: !_showForLater,
            onSelected: (_) {
              if (_showForLater) setState(() => _showForLater = false);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('For Later'),
            avatar: const Icon(Icons.bookmark_outline, size: 16),
            selected: _showForLater,
            onSelected: (_) {
              if (!_showForLater) _switchToForLater();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ReviewProvider provider) {
    if (_showForLater) {
      return _buildForLaterView(theme, provider);
    }
    return _buildInboxView(theme, provider);
  }

  Widget _buildInboxView(ThemeData theme, ReviewProvider provider) {
    if (provider.error != null && provider.items.isEmpty) {
      return _buildError(theme, provider);
    }

    if (provider.loading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.items.isEmpty) {
      return _buildEmpty(theme, provider);
    }

    // Sort: pending-reject-feedback items first, then by date descending
    final sorted = List<ReviewItem>.from(provider.items)
      ..sort((a, b) {
        final aPending = a.status == 'pending-reject-feedback';
        final bPending = b.status == 'pending-reject-feedback';
        if (aPending && !bPending) return -1;
        if (!aPending && bPending) return 1;
        final aDate = a.modified ?? DateTime(2000);
        final bDate = b.modified ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Column(
        children: [
          if (provider.error != null)
            _buildErrorBanner(theme, provider.error!),
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (context, index) {
                return _ReviewItemTile(
                  item: sorted[index],
                  onTap: () => _openDetail(sorted[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForLaterView(ThemeData theme, ReviewProvider provider) {
    if (_forLaterLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = provider.forLaterItems;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.fetchForLater(),
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.bookmark_outline,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Center(
              child: Text('No saved items',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Pull to refresh',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
          ],
        ),
      );
    }

    final sorted = List<ReviewItem>.from(items)
      ..sort((a, b) {
        final aDate = a.modified ?? DateTime(2000);
        final bDate = b.modified ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

    return RefreshIndicator(
      onRefresh: () => provider.fetchForLater(),
      child: ListView.builder(
        itemCount: sorted.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          return _ReviewItemTile(
            item: sorted[index],
            onTap: () => _openDetail(sorted[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, ReviewProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.inbox_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Center(
            child: Text('No items to review',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Pull to refresh',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, ReviewProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Center(
            child: Text('Unable to connect',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.error)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Check server address in settings',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.warning_amber,
              size: 16, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — showing cached data',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(ReviewItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          item: item,
          reviewProvider: widget.reviewProvider,
        ),
      ),
    );
  }
}

class _ReviewItemTile extends StatelessWidget {
  final ReviewItem item;
  final VoidCallback onTap;

  const _ReviewItemTile({required this.item, required this.onTap});

  bool get _isPendingFeedback => item.status == 'pending-reject-feedback';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildSubtitle(theme),
        trailing: const Icon(Icons.chevron_right),
        leading: _buildLeadingIcon(theme),
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    if (_isPendingFeedback) {
      return CircleAvatar(
        backgroundColor: theme.colorScheme.errorContainer,
        child: Icon(Icons.warning_amber,
            color: theme.colorScheme.error, size: 20),
      );
    }

    final IconData icon;
    final Color color;

    switch (item.type?.toLowerCase()) {
      case 'review & feedback':
        icon = Icons.rate_review;
        color = theme.colorScheme.primary;
      case 'implementation':
      case 'implementation (multi-phase)':
        icon = Icons.build;
        color = theme.colorScheme.tertiary;
      default:
        icon = Icons.description;
        color = theme.colorScheme.outline;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    if (_isPendingFeedback) {
      return Text(
        'Rejected \u2014 feedback pending',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final parts = <String>[];
    if (item.from != null) parts.add(item.from!);
    if (item.date != null) parts.add(item.date!);
    if (item.deployment != null) parts.add(item.deployment!);

    return Text(
      parts.join(' \u00b7 '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall,
    );
  }
}
