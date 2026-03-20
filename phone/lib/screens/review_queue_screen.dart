import 'dart:async';

import 'package:flutter/material.dart';

import '../config/document_type_config.dart';
import '../models/pa_team.dart';
import '../models/review_item.dart';
import '../services/agent_api_client.dart';
import '../services/review_provider.dart';
import '../services/team_browser_provider.dart';
import '../widgets/document_type_badge.dart';
import 'create_idea_screen.dart';
import 'folder_list_view.dart';
import 'item_detail_screen.dart';

/// Agent Review tab: 6 subtabs for all sinh-inputs folders.
///
/// Subtabs: Inbox | Approved | Rejected | Deferred | Done | Ideas
/// The Inbox subtab preserves the existing inbox + for-later review workflow.
/// The remaining tabs are placeholders; implemented in subsequent phases.
class ReviewQueueScreen extends StatelessWidget {
  final ReviewProvider reviewProvider;

  /// Optional — when provided, the deploy button appears in [ItemDetailScreen]
  /// for items that came from an agent team inbox.
  final TeamBrowserProvider? teamBrowserProvider;

  const ReviewQueueScreen({
    super.key,
    required this.reviewProvider,
    this.teamBrowserProvider,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Inbox'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
              Tab(text: 'Deferred'),
              Tab(text: 'Done'),
              Tab(text: 'Ideas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _InboxTabView(
                  reviewProvider: reviewProvider,
                  paTeams: teamBrowserProvider?.paTeams,
                  paRepos: teamBrowserProvider?.paRepos,
                ),
                FolderListView(
                    folder: 'approved', client: reviewProvider.client),
                FolderListView(
                    folder: 'rejected', client: reviewProvider.client),
                FolderListView(
                    folder: 'deferred', client: reviewProvider.client),
                _DoneTabView(client: reviewProvider.client),
                _IdeasTabView(client: reviewProvider.client),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ideas tab — browsable list of `ideas/` items with FAB to create new ideas (F16–F23).
///
/// Shows title (from `# Idea: <title>` header) and date, newest-first.
/// No Status badge (Q2 resolved: ideas are short-lived drafts).
/// FAB opens [CreateIdeaScreen]; tapping an item opens detail with
/// Append Section and Archive actions.
class _IdeasTabView extends StatefulWidget {
  final AgentApiClient client;

  const _IdeasTabView({required this.client});

  @override
  State<_IdeasTabView> createState() => _IdeasTabViewState();
}

class _IdeasTabViewState extends State<_IdeasTabView> {
  List<ReviewItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.client.listFolder('ideas');
      items.sort((a, b) {
        final aDate = a.modified ?? DateTime(2000);
        final bDate = b.modified ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(ReviewItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderItemDetailScreen(
          folder: 'ideas',
          item: item,
          client: widget.client,
          onActionDone: _load,
        ),
      ),
    );
  }

  Future<void> _openCreateIdea() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateIdeaScreen(client: widget.client),
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = _buildError(theme);
    } else if (_items.isEmpty) {
      body = _buildEmpty(theme);
    } else {
      body = _buildList(theme);
    }

    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateIdea,
        tooltip: 'New Idea',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              onTap: () => _openDetail(item),
              leading: CircleAvatar(
                backgroundColor:
                    theme.colorScheme.secondaryContainer,
                child: Icon(Icons.lightbulb_outline,
                    color: theme.colorScheme.onSecondaryContainer, size: 20),
              ),
              title: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: item.date != null
                  ? Text(
                      item.date!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    )
                  : null,
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.lightbulb_outline,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No ideas yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tap + to capture a new idea',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Unable to load',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inbox subtab — preserves the existing inbox + for-later review workflow.
///
/// Supports pull-to-refresh, auto-refresh (via [ReviewProvider]),
/// filter between inbox and for-later views, type filter chips,
/// sort by urgency (pending-reject → type priority → date desc),
/// and shows error/empty states.
class _InboxTabView extends StatefulWidget {
  final ReviewProvider reviewProvider;
  final List<PaTeam>? paTeams;
  final List<PaRepo>? paRepos;

  const _InboxTabView(
      {required this.reviewProvider, this.paTeams, this.paRepos});

  @override
  State<_InboxTabView> createState() => _InboxTabViewState();
}

class _InboxTabViewState extends State<_InboxTabView> {
  bool _showForLater = false;
  bool _forLaterLoading = false;
  DocumentType? _typeFilter; // null = All

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
        _buildViewFilterBar(theme),
        if (!_showForLater) _buildTypeFilterRow(theme, provider),
        Expanded(child: _buildBody(theme, provider)),
      ],
    );
  }

  /// Inbox / For Later toggle row.
  Widget _buildViewFilterBar(ThemeData theme) {
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

  /// Scrollable type filter chip row: All / REVIEW / PLAN / REPORT / FYI.
  ///
  /// Chips are ordered by urgency (sort priority). Each chip shows the count
  /// of items of that type in the current inbox. Selecting a chip filters the
  /// list to that type; selecting again (or "All") clears the filter.
  Widget _buildTypeFilterRow(ThemeData theme, ReviewProvider provider) {
    final items = provider.items;

    // Count items per type
    final counts = <DocumentType, int>{};
    for (final item in items) {
      counts[item.documentType] = (counts[item.documentType] ?? 0) + 1;
    }

    // Show types in urgency order (matches sortPriority in kDocumentTypeConfigs)
    const typeOrder = [
      DocumentType.reviewRequest,
      DocumentType.planDraft,
      DocumentType.workReport,
      DocumentType.fyi,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
      child: Row(
        children: [
          // "All" chip
          FilterChip(
            label: Text('All ${items.length}'),
            selected: _typeFilter == null,
            onSelected: (_) => setState(() => _typeFilter = null),
          ),
          ...typeOrder.map((type) {
            final config = kDocumentTypeConfigs[type];
            if (config == null) return const SizedBox.shrink();
            final count = counts[type] ?? 0;
            final isSelected = _typeFilter == type;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text('${config.badgeLabel} $count'),
                selected: isSelected,
                selectedColor: config.badgeColor.withValues(alpha: 0.18),
                checkmarkColor: config.badgeColor,
                labelStyle: isSelected
                    ? TextStyle(
                        color: config.badgeColor,
                        fontWeight: FontWeight.w600,
                      )
                    : null,
                onSelected: (_) => setState(
                  () => _typeFilter = isSelected ? null : type,
                ),
              ),
            );
          }),
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

    // Apply type filter
    final filtered = _typeFilter == null
        ? provider.items
        : provider.items
            .where((i) => i.documentType == _typeFilter)
            .toList();

    if (filtered.isEmpty) {
      return _buildTypeFilterEmpty(theme, provider);
    }

    // Sort: pending-reject-feedback first → type priority (urgency) → date desc
    final sorted = List<ReviewItem>.from(filtered)
      ..sort((a, b) {
        final aPending = a.status == 'pending-reject-feedback';
        final bPending = b.status == 'pending-reject-feedback';
        if (aPending && !bPending) return -1;
        if (!aPending && bPending) return 1;
        final aPriority =
            kDocumentTypeConfigs[a.documentType]?.sortPriority ?? 99;
        final bPriority =
            kDocumentTypeConfigs[b.documentType]?.sortPriority ?? 99;
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);
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

  /// Shown when a type filter is active but no items match.
  Widget _buildTypeFilterEmpty(ThemeData theme, ReviewProvider provider) {
    final config =
        _typeFilter != null ? kDocumentTypeConfigs[_typeFilter] : null;
    final label = config?.badgeLabel ?? 'this type';
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.filter_list, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No $label items',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _typeFilter = null),
              child: const Text('Show all'),
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
          paTeams: widget.paTeams,
          paRepos: widget.paRepos,
        ),
      ),
    );
  }
}

/// Done tab — paginated list with search bar and infinite scroll (F9, F10).
///
/// Fetches pages of 20 items from the done folder. Supports keyword search
/// via `?q=` server-side filter. Auto-loads the next page as the user scrolls
/// near the bottom, with a manual "Load More" fallback button.
class _DoneTabView extends StatefulWidget {
  final AgentApiClient client;

  const _DoneTabView({required this.client});

  @override
  State<_DoneTabView> createState() => _DoneTabViewState();
}

class _DoneTabViewState extends State<_DoneTabView> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<ReviewItem> _items = [];
  bool _hasMore = false;
  int _offset = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 && _hasMore && !_loadingMore) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = _searchController.text.trim();
      if (q != _query) {
        _query = q;
        _load(reset: true);
      }
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _items = [];
        _offset = 0;
        _hasMore = false;
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await widget.client.listFolderPaged(
        'done',
        q: _query.isEmpty ? null : _query,
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _items = result.items;
          _hasMore = result.hasMore;
          _offset = result.items.length;
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

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.client.listFolderPaged(
        'done',
        q: _query.isEmpty ? null : _query,
        limit: _pageSize,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
          _hasMore = result.hasMore;
          _offset += result.items.length;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openDetail(ReviewItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderItemDetailScreen(
          folder: 'done',
          item: item,
          client: widget.client,
          onActionDone: () => _load(reset: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildSearchBar(theme),
        Expanded(child: _buildBody(theme)),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search done items…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    _query = '';
                    _load(reset: true);
                  },
                )
              : null,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _buildError(theme);
    }
    if (_items.isEmpty) {
      return _buildEmpty(theme);
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildLoadMoreIndicator(theme);
          }
          return _FolderDoneItemTile(
            item: _items[index],
            onTap: () => _openDetail(_items[index]),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loadingMore
            ? const CircularProgressIndicator()
            : TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more'),
              ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.archive_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _query.isNotEmpty ? 'No results for "$_query"' : 'Nothing here yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 8),
          if (_query.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () {
                  _searchController.clear();
                  _query = '';
                  _load(reset: true);
                },
                child: const Text('Clear search'),
              ),
            )
          else
            Center(
              child: Text(
                'Pull to refresh',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Unable to load',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _load(reset: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

/// List tile for a done-folder item (type badge + date).
class _FolderDoneItemTile extends StatelessWidget {
  final ReviewItem item;
  final VoidCallback onTap;

  const _FolderDoneItemTile({required this.item, required this.onTap});

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
        subtitle: Row(
          children: [
            DocumentTypeBadge(type: item.documentType),
            if (item.date != null) ...[
              const SizedBox(width: 6),
              Text(
                item.date!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
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

    final config = kDocumentTypeConfigs[item.documentType];
    final color = config?.badgeColor ?? theme.colorScheme.outline;

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(Icons.description_outlined, color: color, size: 20),
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

    final from = item.from;
    final dateParts = <String>[];
    if (item.date != null) dateParts.add(item.date!);
    if (item.deployment != null) dateParts.add(item.deployment!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            DocumentTypeBadge(type: item.documentType),
            if (from != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  from,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
        if (dateParts.isNotEmpty)
          Text(
            dateParts.join(' \u00b7 '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
      ],
    );
  }
}
