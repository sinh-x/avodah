import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/review_item.dart';
import '../services/agent_api_client.dart';
import '../widgets/document_type_badge.dart';
import 'dialogs/confirm_action_dialog.dart';

/// Available actions per folder.
///
/// Each folder exposes a contextually appropriate subset.
enum _FolderAction { requeue, saveForLater, archive }

/// Returns the ordered set of actions available for [folder].
List<_FolderAction> _actionsForFolder(String folder) {
  switch (folder) {
    case 'approved':
      return [_FolderAction.requeue, _FolderAction.saveForLater, _FolderAction.archive];
    case 'rejected':
      return [_FolderAction.requeue, _FolderAction.archive];
    case 'deferred':
      return [_FolderAction.requeue, _FolderAction.saveForLater, _FolderAction.archive];
    case 'done':
      return [_FolderAction.requeue];
    default:
      return [_FolderAction.requeue, _FolderAction.archive];
  }
}

/// Generic list view for a sinh-inputs folder (approved / rejected / deferred).
///
/// Fetches items via [AgentApiClient.listFolder], shows per-folder action sets,
/// supports pull-to-refresh. Tapping an item opens [FolderItemDetailScreen].
class FolderListView extends StatefulWidget {
  final String folder;
  final AgentApiClient client;

  const FolderListView({
    super.key,
    required this.folder,
    required this.client,
  });

  @override
  State<FolderListView> createState() => _FolderListViewState();
}

class _FolderListViewState extends State<FolderListView> {
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
      final items = await widget.client.listFolder(widget.folder);
      // Sort newest-first (F11)
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
          folder: widget.folder,
          item: item,
          client: widget.client,
          onActionDone: _load,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError(theme);
    }

    if (_items.isEmpty) {
      return _buildEmpty(theme);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          return _FolderItemTile(
            folder: widget.folder,
            item: _items[index],
            onTap: () => _openDetail(_items[index]),
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
          Icon(Icons.folder_open, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No items in ${widget.folder}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 8),
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

/// List tile for a single folder item.
///
/// Shows title, document type badge, date, and for deferred items the
/// requeue_after date with a red indicator when overdue (F8).
class _FolderItemTile extends StatelessWidget {
  final String folder;
  final ReviewItem item;
  final VoidCallback onTap;

  const _FolderItemTile({
    required this.folder,
    required this.item,
    required this.onTap,
  });

  bool get _isOverdue {
    if (folder != 'deferred') return false;
    final ra = item.requeueAfter;
    if (ra == null) return false;
    final date = DateTime.tryParse(ra);
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = _isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: overdue
            ? CircleAvatar(
                backgroundColor: theme.colorScheme.errorContainer,
                child: Icon(Icons.schedule,
                    color: theme.colorScheme.error, size: 20),
              )
            : null,
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildSubtitle(theme, overdue),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme, bool overdue) {
    final requeueAfter = item.requeueAfter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
        if (folder == 'deferred' && requeueAfter != null)
          Text(
            overdue ? 'Overdue · due $requeueAfter' : 'Due $requeueAfter',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: overdue ? theme.colorScheme.error : theme.colorScheme.outline,
              fontWeight: overdue ? FontWeight.w600 : null,
            ),
          ),
      ],
    );
  }
}

/// Detail screen for a sinh-inputs folder item (read-only markdown + actions).
///
/// Actions are folder-appropriate: approved gets Re-queue, Save for Later,
/// Archive; rejected gets Re-queue and Archive; deferred gets all three.
/// Performing an action pops this screen and triggers [onActionDone] to
/// refresh the parent list.
class FolderItemDetailScreen extends StatefulWidget {
  final String folder;
  final ReviewItem item;
  final AgentApiClient client;

  /// Called after a successful action so the parent list can reload.
  final VoidCallback onActionDone;

  const FolderItemDetailScreen({
    super.key,
    required this.folder,
    required this.item,
    required this.client,
    required this.onActionDone,
  });

  @override
  State<FolderItemDetailScreen> createState() => _FolderItemDetailScreenState();
}

class _FolderItemDetailScreenState extends State<FolderItemDetailScreen> {
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
      final detail = await widget.client.getFolderItem(
          widget.folder, widget.item.id);
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

  Future<void> _doRequeue() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Re-queue to Inbox?',
      message:
          'This item will be moved back to your inbox for review. '
          'A "requeued_from: ${widget.folder}" note will be added.',
      confirmLabel: 'Re-queue',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _acting = true);
    try {
      await widget.client.requeueItem(widget.folder, widget.item.id);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onActionDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Re-queue failed: $e')),
        );
        setState(() => _acting = false);
      }
    }
  }

  Future<void> _doSaveForLater() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Save for Later?',
      message: 'This item will be moved to your For Later list.',
      confirmLabel: 'Save for Later',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _acting = true);
    try {
      await widget.client.saveApprovedForLater(widget.item.id);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onActionDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save for Later failed: $e')),
        );
        setState(() => _acting = false);
      }
    }
  }

  Future<void> _doArchive() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Move to Done?',
      message: 'This item will be archived in the Done folder.',
      confirmLabel: 'Archive',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _acting = true);
    try {
      await widget.client.archiveItem(widget.folder, widget.item.id);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onActionDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archive failed: $e')),
        );
        setState(() => _acting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar:
          (_loading || _error != null) ? null : _buildActionBar(),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
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

  Widget _buildContent() {
    String content = _detail?.content ?? '';

    // F7: for rejected items, move ## Human Review section to top
    if (widget.folder == 'rejected') {
      content = _promoteHumanReview(content);
    }

    return Markdown(
      data: content,
      selectable: true,
      padding: const EdgeInsets.all(16),
    );
  }

  /// Moves the `## Human Review` section (if present) to the top of the
  /// rendered content for rejected items (F7).
  String _promoteHumanReview(String content) {
    const marker = '## Human Review';
    final idx = content.indexOf(marker);
    if (idx <= 0) return content; // not found or already at top

    // Find the end of the Human Review section (next ## or end of file)
    final afterSection = content.indexOf('\n## ', idx + marker.length);
    final sectionEnd =
        afterSection == -1 ? content.length : afterSection;

    final section = content.substring(idx, sectionEnd).trim();
    final rest = (content.substring(0, idx) +
            content.substring(sectionEnd))
        .trim();

    return '$section\n\n---\n\n$rest';
  }

  Widget _buildActionBar() {
    final actions = _actionsForFolder(widget.folder);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (actions.contains(_FolderAction.requeue))
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _acting ? null : _doRequeue,
                  icon: const Icon(Icons.redo, size: 18),
                  label: const Text('Re-queue'),
                ),
              ),
            if (actions.contains(_FolderAction.requeue) &&
                (actions.contains(_FolderAction.saveForLater) ||
                    actions.contains(_FolderAction.archive)))
              const SizedBox(width: 8),
            if (actions.contains(_FolderAction.saveForLater))
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _acting ? null : _doSaveForLater,
                  icon: const Icon(Icons.bookmark_outline, size: 18),
                  label: const Text('For Later'),
                ),
              ),
            if (actions.contains(_FolderAction.saveForLater) &&
                actions.contains(_FolderAction.archive))
              const SizedBox(width: 8),
            if (actions.contains(_FolderAction.archive))
              Expanded(
                child: FilledButton.icon(
                  onPressed: _acting ? null : _doArchive,
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: const Text('Archive'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
