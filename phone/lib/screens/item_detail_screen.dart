import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../config/document_type_config.dart';
import '../models/pa_team.dart';
import '../models/review_item.dart';
import '../services/review_provider.dart';
import '../widgets/deploy_sheet.dart';
import '../widgets/document_type_badge.dart';
import 'dialogs/acknowledge_dialog.dart';
import 'dialogs/approve_dialog.dart';
import 'dialogs/defer_dialog.dart';
import 'dialogs/plan_confirm_dialog.dart';
import 'dialogs/reject_dialog.dart';

/// Shows full markdown content for a review item with action buttons.
///
/// The action bar is type-conditional: review-request items get the full
/// d-40e61d rich feedback bar (Reject/Defer/SaveForLater/Approve); other types
/// get a lighter workflow (Acknowledge, Got It, Looks Good / Has Changes, etc.)
/// based on [DocumentTypeConfig].
class ItemDetailScreen extends StatefulWidget {
  final ReviewItem item;
  final ReviewProvider reviewProvider;

  /// PA teams with deploy modes. When non-null and item has a `from` team,
  /// a deploy icon button appears in the AppBar.
  final List<PaTeam>? paTeams;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.reviewProvider,
    this.paTeams,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ReviewItem? _detail;
  bool _loading = true;
  String? _error;
  bool _acting = false;
  List<String> _chips = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadChips();
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

  Future<void> _loadChips() async {
    try {
      final chips = await widget.reviewProvider.getFeedbackChips();
      if (mounted) setState(() => _chips = chips);
    } catch (_) {
      // Chips are best-effort; missing chips don't break the workflow
    }
  }

  bool get _isPendingReject =>
      (widget.item.status ?? _detail?.status) == 'pending-reject-feedback';

  /// True when the item came from an agent team inbox (has `from` field)
  /// and [paTeams] was provided — enables the deploy action.
  bool get _isTeamInboxItem =>
      widget.item.from != null && widget.paTeams != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_loading && _error == null && _isTeamInboxItem)
            IconButton(
              icon: const Icon(Icons.rocket_launch_outlined),
              tooltip: 'Deploy',
              onPressed: _acting ? null : _onDeploy,
            ),
          if (!_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Section',
              onPressed: _acting ? null : _onAddSection,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: _loading || _error != null ? null : _buildActionBar(),
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
          Text('Failed to load content', style: theme.textTheme.titleMedium),
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
    final content = _detail?.content ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetadataBar(),
        if (_isPendingReject) _buildPendingRejectBanner(),
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

  Widget _buildMetadataBar() {
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
    chips.add(DocumentTypeBadge(type: item.documentType));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildPendingRejectBanner() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.shade100,
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.amber.shade800, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rejected — feedback pending',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.amber.shade900),
            ),
          ),
          TextButton(
            onPressed: _acting ? null : _onReject,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Add feedback'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final theme = Theme.of(context);
    final docType = widget.item.documentType;

    Widget barContent;
    switch (docType) {
      case DocumentType.reviewRequest:
      case DocumentType.decisionNeeded:
        barContent = _buildReviewRequestBar(theme);
      case DocumentType.workReport:
        barContent = _buildWorkReportBar(theme);
      case DocumentType.planDraft:
        barContent = _buildPlanDraftBar(theme);
      case DocumentType.fyi:
        barContent = _buildFyiBar(theme);
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: barContent,
      ),
    );
  }

  /// Full d-40e61d action bar: [Reject] [⏳] [🔖] [Approve]
  Widget _buildReviewRequestBar(ThemeData theme) {
    return Row(
      children: [
        // Reject
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _acting ? null : _onReject,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Defer
        IconButton.outlined(
          onPressed: _acting ? null : _onDefer,
          icon: const Icon(Icons.schedule),
          tooltip: 'Defer',
          style: IconButton.styleFrom(
            foregroundColor: Colors.orange.shade800,
            side: BorderSide(color: Colors.orange.shade300),
          ),
        ),
        const SizedBox(width: 8),
        // Save for Later
        IconButton.outlined(
          onPressed: _acting ? null : _onSaveForLater,
          icon: const Icon(Icons.bookmark_outline),
          tooltip: 'Save for Later',
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.secondary,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: 8),
        // Approve
        Expanded(
          child: FilledButton.icon(
            onPressed: _acting ? null : _onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Work-report action bar: [✅ Acknowledge] [🔖 Later]
  ///
  /// Tap = fast-path acknowledge (no annotation, AC24).
  /// Long-press = open [AcknowledgeDialog] for optional note (AC25).
  Widget _buildWorkReportBar(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _acting ? null : _onAcknowledge,
            onLongPress: _acting ? null : _onAcknowledgeWithNote,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Acknowledge'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: _acting ? null : _onSaveForLater,
          icon: const Icon(Icons.bookmark_outline),
          tooltip: 'Save for Later',
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.secondary,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
      ],
    );
  }

  /// Plan-draft action bar: [✅ Looks Good] [📝 Has Changes] [⏳ Defer] [🔖 Later]
  Widget _buildPlanDraftBar(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _acting ? null : _onPlanLooksGood,
            icon: const Icon(Icons.thumb_up_outlined, size: 18),
            label: const Text('Looks Good'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _acting ? null : _onPlanHasChanges,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Has Changes'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: _acting ? null : _onDefer,
          icon: const Icon(Icons.schedule),
          tooltip: 'Defer',
          style: IconButton.styleFrom(
            foregroundColor: Colors.orange.shade800,
            side: BorderSide(color: Colors.orange.shade300),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: _acting ? null : _onSaveForLater,
          icon: const Icon(Icons.bookmark_outline),
          tooltip: 'Save for Later',
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.secondary,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
      ],
    );
  }

  /// FYI action bar: [👍 Got It]
  Widget _buildFyiBar(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _acting ? null : _onGotIt,
        icon: const Icon(Icons.thumb_up, size: 18),
        label: const Text('Got It'),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
        ),
      ),
    );
  }

  // --- New type-specific handlers ---

  /// Acknowledge fast-path: clean move to done/ with no annotation (AC24).
  Future<void> _onAcknowledge() async {
    setState(() => _acting = true);
    try {
      await widget.reviewProvider.acknowledge(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Acknowledged')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to acknowledge: $e')));
      }
    }
  }

  /// Acknowledge with optional note: opens [AcknowledgeDialog], then moves to done/ (AC25).
  Future<void> _onAcknowledgeWithNote() async {
    final note = await AcknowledgeDialog.show(context);
    if (note == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider
          .acknowledge(widget.item.id, note: note.isNotEmpty ? note : null);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Acknowledged')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to acknowledge: $e')));
      }
    }
  }

  /// Got It: clean move to done/ for FYI items.
  Future<void> _onGotIt() async {
    setState(() => _acting = true);
    try {
      await widget.reviewProvider.acknowledge(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Got it')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  /// Plan "Looks Good": clean move to done/ with no annotation (F19 / AC28).
  Future<void> _onPlanLooksGood() async {
    setState(() => _acting = true);
    try {
      await widget.reviewProvider.acknowledge(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Plan confirmed')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  /// Plan "Has Changes": opens [PlanConfirmDialog] for a note, then moves to done/ (F18 / AC29).
  ///
  /// Note: the server writes `action: acknowledged` in frontmatter; a future
  /// phase may add a dedicated API param to write `plan-confirmed-with-changes`.
  Future<void> _onPlanHasChanges() async {
    final note = await PlanConfirmDialog.show(context);
    if (note == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider
          .acknowledge(widget.item.id, note: note.isNotEmpty ? note : null);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Plan noted')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  // --- Existing d-40e61d handlers (unchanged) ---

  Future<void> _onApprove() async {
    final item = _detail ?? widget.item;
    final feedback = await ApproveDialog.show(
      context,
      availableChips: _chips,
      client: widget.reviewProvider.client,
      initialDestinationTeam: item.to,
    );
    if (feedback == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider.approve(
        widget.item.id,
        feedback: feedback.hasContent ? feedback : null,
      );
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
    final feedback = await DeferDialog.show(context, availableChips: _chips);
    if (feedback == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider.defer(
        widget.item.id,
        feedback: feedback.hasContent ? feedback : null,
      );
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
    final item = _detail ?? widget.item;
    final fromTeam =
        item.from != null ? _teamFromFrom(item.from!) : null;
    final feedback = await RejectDialog.show(
      context,
      availableChips: _chips,
      client: widget.reviewProvider.client,
      initialDestinationTeam: fromTeam,
    );
    if (feedback == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider.reject(widget.item.id, feedback);
      if (mounted) {
        if (feedback.pending) {
          // Item stays in inbox with pending status
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rejected — feedback pending')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item rejected')),
          );
          Navigator.pop(context);
        }
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

  Future<void> _onSaveForLater() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save for Later?'),
        content: const Text(
          'The item will be moved to your for-later folder. '
          'It will not count toward your inbox badge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.bookmark, size: 18),
            label: const Text('Save for Later'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider.saveForLater(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved for later')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save for later: $e')),
        );
      }
    }
  }

  /// Extracts team name from `from` field (e.g. "requirements / team-manager" → "requirements").
  String? _teamFromFrom(String from) {
    final parts = from.split(' / ');
    return parts.isNotEmpty ? parts.first.trim() : null;
  }

  /// Opens [DeploySheet] pre-filled with this item's team and filename as objective.
  void _onDeploy() {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final team = _teamFromFrom(widget.item.from!);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DeploySheet(
        paTeams: widget.paTeams!,
        initialTeam: team,
        initialObjective: widget.item.id,
        onDeploy: (t, mode, objective) async {
          Navigator.pop(context);
          try {
            final result = await widget.reviewProvider.client.triggerDeployment(
              t,
              mode,
              objective: objective.isNotEmpty ? objective : null,
            );
            if (mounted) {
              messenger.showSnackBar(SnackBar(
                content: Text(
                  result.deploymentId.isNotEmpty
                      ? '${result.deploymentId} started'
                      : 'Deployment started',
                ),
                duration: const Duration(seconds: 4),
              ));
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(SnackBar(
                content: Text('Deploy failed: $e'),
                backgroundColor: errorColor,
              ));
            }
          }
        },
      ),
    );
  }

  Future<void> _onAddSection() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _AddSectionDialog(),
    );

    if (result == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.reviewProvider.appendSection(
        widget.item.id,
        result['title']!,
        result['content']!,
      );
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section added')),
        );
        // Reload detail to show new section
        _loadDetail();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add section: $e')),
        );
      }
    }
  }
}

/// Inline dialog for appending a named section to a document.
class _AddSectionDialog extends StatefulWidget {
  const _AddSectionDialog();

  @override
  State<_AddSectionDialog> createState() => _AddSectionDialogState();
}

class _AddSectionDialogState extends State<_AddSectionDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool get _canAdd =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Section'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Section title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. "Follow-up Notes"',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const Text('Content'),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Section content...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canAdd
              ? () => Navigator.pop(context, {
                    'title': _titleController.text.trim(),
                    'content': _contentController.text.trim(),
                  })
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
