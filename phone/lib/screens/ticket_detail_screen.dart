import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/deploy_routing.dart';
import '../models/deployment.dart';
import '../models/repo_git_info.dart';
import '../models/ticket.dart';
import '../screens/document_viewer_screen.dart';
import '../services/agent_api_client.dart';
import '../services/board_provider.dart';
import '../widgets/deploy_sheet.dart';
import '../widgets/estimate_picker_sheet.dart';
import '../widgets/priority_picker_sheet.dart';
import '../widgets/status_picker_sheet.dart';
import '../widgets/assignee_picker_sheet.dart';
import '../widgets/image_attachment_picker.dart';
import '../widgets/no_select_text_field.dart';
import '../widgets/text_input_sheet.dart';
import '../widgets/ticket_deployments_section.dart';
import '../widgets/ticket_subtickets_section.dart';
import '../widgets/ticket_repo_info_section.dart';
import 'activity_timeline_screen.dart';

/// Full ticket detail view with read and edit modes.
///
/// Fetches the ticket by ID on init using [boardProvider.client].
/// In read mode, displays all ticket fields. Doc refs are tappable rows
/// with type badges — they navigate to [DocumentViewerScreen].
/// A comment input bar is fixed at the bottom of the read view.
/// Toggle to edit mode via the AppBar edit icon to change status, priority,
/// team, assignee, estimate, and tags. Save calls [boardProvider.client.updateTicket].
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final BoardProvider boardProvider;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.boardProvider,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Ticket? _ticket;
  bool _loading = true;
  String? _error;
  bool _submittingComment = false;

  // Per-field saving state (field name → true while saving)
  final Set<String> _savingFields = {};

  // Image attachment selection state
  bool _hasSelectedImages = false;

  // Deploy state
  DeployRouting? _deployRouting;
  DateTime? _deployRoutingFetchedAt;
  bool _fetchingRouting = false;

  // Repo & deployment state (lazy-loaded after ticket)
  RepoGitInfo? _repoGitInfo;
  List<Deployment>? _ticketDeployments;
  bool _repoLoading = false;
  bool _deploymentsLoading = false;
  String? _repoError;
  String? _deploymentsError;

  // Comment input
  final _commentController = TextEditingController();

  // Image attachment picker key
  final _imagePickerKey = GlobalKey<ImageAttachmentPickerState>();

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ticket =
          await widget.boardProvider.client.getTicket(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _loading = false;
        });
        // Fetch repo info and deployments in parallel — doesn't block initial render
        _fetchRepoAndDeployments(ticket.project, ticket.id);
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

  Future<void> _uploadAttachments() async {
    final picker = _imagePickerKey.currentState;
    if (picker == null || _ticket == null) return;
    final images = picker.selectedImages;
    if (images.isEmpty) return;

    picker.setUploading(true);
    try {
      final (successes: successes, failures: failures) =
          await picker.widget.onUpload(images, _ticket!.id);
      if (mounted) {
        if (successes.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${successes.length} image(s) attached')),
          );
          picker.clear();
          setState(() {
            _hasSelectedImages = false;
          });
          _loadTicket();
        }
        if (failures.isNotEmpty) {
          final names = failures.map((p) => p.split('/').last).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload: $names')),
          );
        }
      }
    } finally {
      picker.setUploading(false);
    }
  }

  /// Fetches repo git info and deployments in parallel for the given project.
  /// Deployments are filtered client-side to only those linked to [ticketId].
  Future<void> _fetchRepoAndDeployments(String project, String ticketId) async {
    setState(() {
      _repoLoading = true;
      _deploymentsLoading = true;
      _repoError = null;
      _deploymentsError = null;
    });

    await Future.wait([
      _fetchRepoInfo(project),
      _fetchDeployments(project, ticketId),
    ]);
  }

  Future<void> _fetchRepoInfo(String project) async {
    try {
      final repoInfo =
          await widget.boardProvider.client.getRepoGitInfo(project);
      if (mounted) {
        setState(() {
          _repoGitInfo = repoInfo;
          _repoLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _repoError = e.toString();
          _repoLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDeployments(String project, String ticketId) async {
    try {
      final all = await widget.boardProvider.client.getRepoDeployments(project);
      if (mounted) {
        setState(() {
          _ticketDeployments =
              all.where((d) => d.ticketId == ticketId).toList();
          _deploymentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deploymentsError = e.toString();
          _deploymentsLoading = false;
        });
      }
    }
  }

  // ─── Per-field save ────────────────────────────────────────────────────────

  /// Saves [field] with [value] via updateTicket(), showing per-field loading
  /// and handling errors + 409 conflicts.
  Future<void> _saveField(String field, dynamic value) async {
    if (_ticket == null) return;

    // Prevent double-saves for the same field
    if (_savingFields.contains(field)) return;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    setState(() => _savingFields.add(field));

    try {
      final updated = await widget.boardProvider.client
          .updateTicket(_ticket!.id, {field: value});
      if (!mounted) return;
      setState(() {
        _ticket = updated;
        _savingFields.remove(field);
      });
      // NF5: announce to screen reader
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${_fieldLabel(field)} saved',
        Directionality.of(context),
      );
      // Brief success feedback via snackbar
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_fieldLabel(field)} saved'),
          duration: const Duration(seconds: 1),
        ),
      );
    } on AgentApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingFields.remove(field));
      if (e.statusCode == 409) {
        // Conflict: fetch server version and show dialog
        await _showConflictDialog(field, value);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to save ${_fieldLabel(field)}: ${e.message}'),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _saveField(field, value),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingFields.remove(field));
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save ${_fieldLabel(field)}: $e'),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _saveField(field, value),
          ),
        ),
      );
    }
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'status':
        return 'Status';
      case 'priority':
        return 'Priority';
      case 'estimate':
        return 'Estimate';
      case 'team':
        return 'Team';
      case 'assignee':
        return 'Assignee';
      case 'tags':
        return 'Tags';
      case 'title':
        return 'Title';
      case 'summary':
        return 'Summary';
      default:
        return field;
    }
  }

  /// Shows a conflict dialog offering Reload (discard local) or Force save.
  Future<void> _showConflictDialog(String field, dynamic value) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Conflict Detected'),
        content: Text(
          'This ticket was updated on the server while you were editing. '
          'What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'reload'),
            child: const Text('Reload'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'force'),
            child: const Text('Force Save'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    if (result == 'reload') {
      await _loadTicket();
    } else if (result == 'force') {
      await _forceSaveField(field, value);
    }
  }

  /// Force-saves [field] with [value] by re-fetching the latest ticket and
  /// retrying the update.
  Future<void> _forceSaveField(String field, dynamic value) async {
    if (_ticket == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    setState(() => _savingFields.add(field));

    try {
      // Re-fetch latest ticket then save
      final latest =
          await widget.boardProvider.client.getTicket(_ticket!.id);
      if (!mounted) return;
      final updated = await widget.boardProvider.client.updateTicket(
        latest.id,
        {field: value},
      );
      if (!mounted) return;
      setState(() {
        _ticket = updated;
        _savingFields.remove(field);
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_fieldLabel(field)} saved (force)'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingFields.remove(field));
      messenger.showSnackBar(
        SnackBar(
          content: Text('Force save failed: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  // Phase 1: open sheet handlers (save wiring comes in Phase 2)

  void _openStatusPicker(Ticket ticket) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => StatusPickerSheet(
        currentStatus: ticket.status,
        onSelect: (newStatus) {
          Navigator.pop(context);
          _saveField('status', newStatus);
        },
      ),
    );
  }

  void _openPriorityPicker(Ticket ticket) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => PriorityPickerSheet(
        currentPriority: ticket.priority,
        onSelect: (newPriority) {
          Navigator.pop(context);
          _saveField('priority', newPriority);
        },
      ),
    );
  }

  void _openEstimatePicker(Ticket ticket) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => EstimatePickerSheet(
        currentEstimate: ticket.estimate ?? 'S',
        onSelect: (newEstimate) {
          Navigator.pop(context);
          _saveField('estimate', newEstimate);
        },
      ),
    );
  }

  void _openAssigneeSheet(Ticket ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AssigneePickerSheet(
        client: widget.boardProvider.client,
        currentAssignee: ticket.assignee,
        onSelect: (assignee) {
          _saveField('assignee', assignee);
        },
      ),
    );
  }

  void _openTitleSheet(Ticket ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TextInputSheet(
        label: 'Title',
        initialValue: ticket.title,
        onConfirm: (value) {
          _saveField('title', value);
        },
      ),
    );
  }

  void _openSummarySheet(Ticket ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TextInputSheet(
        label: 'Summary',
        initialValue: ticket.summary,
        onConfirm: (value) {
          _saveField('summary', value);
        },
      ),
    );
  }

  void _openTagSheet(Ticket ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TagSheet(
        tags: List.from(ticket.tags),
        onConfirm: (tags) {
          _saveField('tags', tags);
        },
      ),
    );
  }

  Future<void> _onDeploy() async {
    if (_ticket == null) return;
    final ticket = _ticket!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final client = widget.boardProvider.client;

    // Fetch routing if not cached or stale (>5 min).
    final routingStale = _deployRoutingFetchedAt != null &&
        DateTime.now().difference(_deployRoutingFetchedAt!).inMinutes >= 5;
    if (_deployRouting == null || routingStale) {
      setState(() => _fetchingRouting = true);
      try {
        final routing = await client.getDeployRouting();
        if (mounted) {
          setState(() {
            _deployRouting = routing;
            _deployRoutingFetchedAt = DateTime.now();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _fetchingRouting = false);
          messenger.showSnackBar(SnackBar(
            content: Text('Failed to load deploy routing: $e'),
            backgroundColor: errorColor,
          ));
        }
        return;
      }
      if (mounted) setState(() => _fetchingRouting = false);
    }

    if (!mounted) return;
    final routing = _deployRouting!;
    final paTeams = routing.toPaTeams();

    // Auto-suggest team: ticket.assignee only (team field is deprecated).
    String? initialTeam;
    if (ticket.assignee != null &&
        paTeams.any((t) => t.name == ticket.assignee)) {
      initialTeam = ticket.assignee;
    }

    // Pre-fill objective with ticket ID only (avoids validation issues with special chars in title).
    final initialObjective = ticket.id;
    final initialRepo = ticket.project.isNotEmpty ? ticket.project : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DeploySheet(
        paTeams: paTeams,
        paRepos: routing.repos,
        initialTeam: initialTeam,
        initialObjective: initialObjective,
        initialRepo: initialRepo,
        onDeploy: (team, mode, objective, {repo, provider, teamModel}) async {
          Navigator.pop(context);
          try {
            final result = await client.triggerDeployment(
              team,
              mode,
              objective: objective.isNotEmpty ? objective : null,
              repo: repo,
              ticket: ticket.id,
              provider: provider,
              teamModel: teamModel,
            );
            if (!mounted) return;
            if (!result.started) {
              final detail = result.reason.isNotEmpty
                  ? result.reason
                  : 'server did not start deployment';
              messenger.showSnackBar(SnackBar(
                content: Text(
                  'Deploy failed: $detail'
                  '${result.deploymentId.isNotEmpty ? ' (${result.deploymentId})' : ''}',
                ),
                backgroundColor: errorColor,
              ));
              return;
            }
            // Server may return empty deployment_id (ID generated async).
            // Poll listDeployments to find the real deployment.
            Deployment? deployment;
            final beforeDeploy = DateTime.now().subtract(const Duration(seconds: 5));
            for (var attempt = 0; attempt < 3; attempt++) {
              await Future<void>.delayed(const Duration(seconds: 2));
              if (!mounted) return;
              try {
                final deployments = await client.listDeployments();
                // Match by exact ID if available, else by team + recent start.
                if (result.deploymentId.isNotEmpty) {
                  deployment = deployments.cast<Deployment?>().firstWhere(
                        (d) => d!.deploymentId == result.deploymentId,
                        orElse: () => null,
                      );
                } else {
                  // Find most recent deployment for this team started after our trigger.
                  final candidates = deployments.where((d) {
                    if (d.team != team) return false;
                    final started = DateTime.tryParse(d.startedAt);
                    return started != null && started.isAfter(beforeDeploy);
                  }).toList()
                    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
                  if (candidates.isNotEmpty) {
                    deployment = candidates.first;
                  }
                }
                if (deployment != null) break;
              } catch (_) {
                // Retry on next attempt.
              }
            }
            if (!mounted) return;
            final displayId = deployment?.deploymentId ?? result.deploymentId;
            messenger.showSnackBar(SnackBar(
              content: Text(
                displayId.isNotEmpty
                    ? 'Deployed $displayId'
                    : 'Deployment launched',
              ),
              duration: const Duration(seconds: 8),
              action: deployment != null
                  ? SnackBarAction(
                      label: 'View',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ActivityTimelineScreen(
                              deployment: deployment!,
                              client: client,
                            ),
                          ),
                        );
                      },
                    )
                  : null,
            ));
          } catch (e) {
            if (mounted) {
              final message = e is AgentApiException ? e.message : 'Deploy failed: $e';
              messenger.showSnackBar(SnackBar(
                content: Text(message),
                backgroundColor: errorColor,
              ));
            }
          }
        },
      ),
    );
  }

  bool _isTerminalStatus(String status) {
    return status == 'done' || status == 'rejected' || status == 'cancelled';
  }

  Future<void> _onMoveToProject() async {
    if (_ticket == null) return;
    final ticket = _ticket!;
    final oldId = ticket.id;

    // Show project picker bottom sheet.
    final projects = widget.boardProvider.projects;
    final otherProjects = projects.where((p) => p.key != ticket.project).toList();

    if (otherProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other projects available')),
      );
      return;
    }

    final selectedProject = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(sheetCtx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Select Target Project',
                style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: otherProjects.length,
                itemBuilder: (context, index) {
                  final p = otherProjects[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(p.key),
                    onTap: () => Navigator.pop(sheetCtx, p.key),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedProject == null || !mounted) return;

    // Show confirmation dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move Ticket'),
        content: Text(
          'Move $oldId to project $selectedProject?\n'
          'This will re-key the ticket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Perform the move.
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    setState(() => _loading = true);

    try {
      final newTicket = await widget.boardProvider.client.moveTicket(
        oldId,
        selectedProject,
      );
      if (!mounted) return;
      setState(() {
        _ticket = newTicket;
        _loading = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('Moved: $oldId → ${newTicket.id}'),
        ),
      );
    } on AgentApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Move failed: ${e.message}'),
          backgroundColor: errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Move failed: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _ticket == null) return;
    setState(() => _submittingComment = true);
    try {
      final updated = await widget.boardProvider.client
          .addComment(_ticket!.id, content, 'sinh');
      if (mounted) {
        setState(() {
          _ticket = updated;
          _submittingComment = false;
        });
        _commentController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submittingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  Widget _buildCommentItem(TicketComment comment) {
    return Dismissible(
      key: Key('comment-${comment.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left → delete
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Comment'),
              content: const Text('Delete this comment?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.error),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed == true) await _deleteComment(comment);
          return false;
        } else {
          // Swipe right → edit
          _showEditCommentSheet(comment);
          return false;
        }
      },
      background: _buildSwipeBackground(isEdit: true),
      secondaryBackground: _buildSwipeBackground(isEdit: false),
      child: GestureDetector(
        onLongPress: () => _showCommentContextMenu(comment),
        child: _CommentCard(comment: comment),
      ),
    );
  }

  Widget _buildSwipeBackground({required bool isEdit}) {
    final color = isEdit ? Colors.blue : Colors.red;
    return Container(
      alignment: isEdit ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color.withValues(alpha: 0.15),
      child: Icon(
        isEdit ? Icons.edit_outlined : Icons.delete_outlined,
        color: color,
      ),
    );
  }

  void _showCommentContextMenu(TicketComment comment) {
    final errorColor = Theme.of(context).colorScheme.error;
    showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outlined, color: errorColor),
              title: Text('Delete',
                  style: TextStyle(color: errorColor)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    ).then((action) async {
      if (!mounted) return;
      if (action == 'edit') {
        _showEditCommentSheet(comment);
      } else if (action == 'delete') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text('Delete this comment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) await _deleteComment(comment);
      }
    });
  }

  void _showEditCommentSheet(TicketComment comment) {
    final editController = TextEditingController(text: comment.content);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Comment',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            NoSelectTextFieldRaw(
              controller: editController,
              autofocus: true,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final content = editController.text.trim();
                Navigator.pop(sheetCtx);
                if (content.isNotEmpty && content != comment.content) {
                  _editComment(comment, content);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editComment(TicketComment comment, String content) async {
    if (_ticket == null) return;
    try {
      final updated = await widget.boardProvider.client
          .editComment(_ticket!.id, comment.id, content, 'sinh');
      if (mounted) setState(() => _ticket = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit comment: $e')),
        );
      }
    }
  }

  Future<void> _deleteComment(TicketComment comment) async {
    if (_ticket == null) return;
    try {
      await widget.boardProvider.client
          .deleteComment(_ticket!.id, comment.id, 'sinh');
      if (mounted) {
        setState(() {
          _ticket = Ticket(
            id: _ticket!.id,
            project: _ticket!.project,
            title: _ticket!.title,
            summary: _ticket!.summary,
            description: _ticket!.description,
            status: _ticket!.status,
            priority: _ticket!.priority,
            type: _ticket!.type,
            team: _ticket!.team,
            assignee: _ticket!.assignee,
            estimate: _ticket!.estimate,
            from: _ticket!.from,
            to: _ticket!.to,
            tags: _ticket!.tags,
            blockedBy: _ticket!.blockedBy,
            docRefs: _ticket!.docRefs,
            comments: _ticket!.comments
                .where((c) => c.id != comment.id)
                .toList(),
            subTickets: _ticket!.subTickets,
            createdAt: _ticket!.createdAt,
            updatedAt: _ticket!.updatedAt,
            resolvedAt: _ticket!.resolvedAt,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket?.id ?? 'Ticket'),
        actions: [
          if (_ticket != null) ...[
            _fetchingRouting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.rocket_launch_outlined),
                    tooltip: 'Deploy agent',
                    onPressed: _onDeploy,
                  ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More actions',
              onSelected: (value) {
                if (value == 'move') {
                  _onMoveToProject();
                }
              },
              itemBuilder: (context) {
                final ticket = _ticket!;
                final items = <PopupMenuEntry<String>>[];
                if (!_isTerminalStatus(ticket.status)) {
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'move',
                      child: ListTile(
                        leading: Icon(Icons.drive_file_move_outlined),
                        title: Text('Move to Project'),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                }
                return items;
              },
            ),
          ],
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const _TicketSkeleton();
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loadTicket, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_ticket == null) return const SizedBox.shrink();
    return Column(
      children: [
        Expanded(child: _buildReadView(context)),
        _buildCommentInputBar(),
      ],
    );
  }

  Widget _buildReadView(BuildContext context) {
    final ticket = _ticket!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title — tappable (min 48dp tall for tap target)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: _FieldSavingIndicator(
              isSaving: _savingFields.contains('title'),
              child: Semantics(
                label: 'Title: ${ticket.title}. Tap to change.',
                button: true,
                child: InkWell(
                  onTap: _savingFields.contains('title')
                      ? null
                      : () => _openTitleSheet(ticket),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      ticket.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Status — tappable (shows spinner while saving)
              _FieldSavingIndicator(
                isSaving: _savingFields.contains('status'),
                child: Semantics(
                  label: 'Status: ${statusLabel(ticket.status)}. Tap to change.',
                  button: true,
                  child: InkWell(
                    onTap: _savingFields.contains('status')
                        ? null
                        : () => _openStatusPicker(ticket),
                    borderRadius: BorderRadius.circular(12),
                    child: _StatusChip(status: ticket.status),
                  ),
                ),
              ),
              // Priority — tappable
              _FieldSavingIndicator(
                isSaving: _savingFields.contains('priority'),
                child: Semantics(
                  label: 'Priority: ${priorityLabel(ticket.priority)}. Tap to change.',
                  button: true,
                  child: InkWell(
                    onTap: _savingFields.contains('priority')
                        ? null
                        : () => _openPriorityPicker(ticket),
                    borderRadius: BorderRadius.circular(12),
                    child: _PriorityChip(priority: ticket.priority),
                  ),
                ),
              ),
              if (ticket.type != null) _InfoChip(label: ticket.type!),
              // Estimate — tappable
              if (ticket.estimate != null)
                _FieldSavingIndicator(
                  isSaving: _savingFields.contains('estimate'),
                  child: Semantics(
                    label: 'Estimate: ${ticket.estimate}. Tap to change.',
                    button: true,
                    child: InkWell(
                      onTap: _savingFields.contains('estimate')
                          ? null
                          : () => _openEstimatePicker(ticket),
                      borderRadius: BorderRadius.circular(12),
                      child: _InfoChip(label: ticket.estimate!),
                    ),
                  ),
                ),
              // Deployment count chip — shows latest deploy status color (lazy-loaded)
              if (_ticketDeployments != null || _deploymentsLoading)
                _DeploymentCountChip(
                  deployments: _ticketDeployments,
                  isLoading: _deploymentsLoading,
                  error: _deploymentsError,
                ),
              // SubTicket count chip — only when > 0
              if (ticket.subTickets.isNotEmpty)
                _SubTicketCountChip(count: ticket.subTickets.length),
            ],
          ),
          const SizedBox(height: 10),
            // Assignee row — tappable (min 48dp tall for tap target)
            // Always show (even when null) so user can set an assignee
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: _FieldSavingIndicator(
                isSaving: _savingFields.contains('assignee'),
                child: Semantics(
                  label: ticket.assignee != null
                      ? 'Assignee: ${ticket.assignee}. Tap to change.'
                      : 'Assignee: not set. Tap to set.',
                  button: true,
                  child: InkWell(
                    onTap: _savingFields.contains('assignee')
                        ? null
                        : () => _openAssigneeSheet(ticket),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            ticket.assignee ?? 'Set assignee',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ticket.assignee != null
                                  ? null
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (ticket.summary != null && ticket.summary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Summary'),
            const SizedBox(height: 4),
            // Summary — tappable (min 48dp tall for tap target)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: _FieldSavingIndicator(
                isSaving: _savingFields.contains('summary'),
                child: Semantics(
                  label: 'Summary: ${ticket.summary}. Tap to change.',
                  button: true,
                  child: InkWell(
                    onTap: _savingFields.contains('summary')
                        ? null
                        : () => _openSummarySheet(ticket),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(ticket.summary!,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (ticket.description != null &&
              ticket.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Description'),
            const SizedBox(height: 4),
            MarkdownBody(data: ticket.description!),
          ],
          if (ticket.docRefs.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Doc Refs'),
            const SizedBox(height: 4),
            ...ticket.docRefs.map(
              (ref) => _DocRefRow(
                docRef: ref,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentViewerScreen(
                      path: ref.path,
                      client: widget.boardProvider.client,
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Image attachments — "Add photo" button + picker
          const SizedBox(height: 16),
          _SectionLabel('Attachments'),
          const SizedBox(height: 8),
          ImageAttachmentPicker(
            key: _imagePickerKey,
            onUpload: (images, ticketId) async {
              final successes = <String>[];
              final failures = <String>[];
              final picker = _imagePickerKey.currentState!;
              for (var i = 0; i < images.length; i++) {
                picker.setUploadProgress((i + 0.5) / images.length);
                try {
                  final docRef = await widget.boardProvider.client
                      .uploadAttachment(ticketId, images[i]);
                  successes.add(docRef);
                } catch (_) {
                  failures.add(images[i].path);
                }
              }
              picker.setUploadProgress(1.0);
              return (successes: successes, failures: failures);
            },
            onUploadingChanged: (uploading) {
              setState(() {});
            },
            onSelectionChanged: () {
              setState(() {
                _hasSelectedImages =
                    _imagePickerKey.currentState?.selectedImages.isNotEmpty ??
                        false;
              });
            },
          ),
          // Upload button — visible when images are selected
          if (_hasSelectedImages ||
              (_imagePickerKey.currentState?.uploading ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.icon(
                onPressed: _imagePickerKey.currentState?.uploading ?? false
                    ? null
                    : _uploadAttachments,
                icon: const Icon(Icons.cloud_upload, size: 18),
                label: Text(
                  _imagePickerKey.currentState?.uploading ?? false
                      ? 'Uploading...'
                      : 'Upload',
                ),
              ),
            ),
          const SizedBox(height: 8),
          TicketDeploymentsSection(
            deployments: _ticketDeployments ?? [],
            isLoading: _deploymentsLoading,
            error: _deploymentsError,
            client: widget.boardProvider.client,
          ),
          const SizedBox(height: 4),
          TicketSubTicketsSection(
            subTickets: ticket.subTickets,
          ),
          const SizedBox(height: 4),
          TicketRepoInfoSection(
            repoGitInfo: _repoGitInfo,
            isLoading: _repoLoading,
            error: _repoError,
            ticketId: ticket.id,
            apiClient: widget.boardProvider.client,
            linkedBranches: ticket.linkedBranches,
            linkedCommits: ticket.linkedCommits,
          ),
          const SizedBox(height: 8),
          // Tags — tappable
          _FieldSavingIndicator(
            isSaving: _savingFields.contains('tags'),
            child: Semantics(
              label: 'Tags: ${ticket.tags.join(", ")}. Tap to change.',
              button: true,
              child: InkWell(
                onTap: _savingFields.contains('tags')
                    ? null
                    : () => _openTagSheet(ticket),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.tags.isNotEmpty) ...[
                        _SectionLabel('Tags'),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: ticket.tags
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Comments'),
          const SizedBox(height: 6),
          if (ticket.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No comments yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...ticket.comments.map((c) => _buildCommentItem(c)),
          const SizedBox(height: 16),
          Text(
            'Created ${_formatDate(ticket.createdAt)}'
            ' · Updated ${_formatDate(ticket.updatedAt)}'
            '${ticket.resolvedAt != null ? ' · Resolved ${_formatDate(ticket.resolvedAt!)}' : ''}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCommentInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: NoSelectTextFieldRaw(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment…',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
              ),
            ),
            const SizedBox(width: 8),
            _submittingComment
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    tooltip: 'Send comment',
                    onPressed: _addComment,
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall
          ?.copyWith(color: theme.colorScheme.outline, letterSpacing: 0.5),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip({required this.priority});

  Color _color() {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Inline chip showing deployment count with latest deploy status color.
class _DeploymentCountChip extends StatelessWidget {
  final List<Deployment>? deployments;
  final bool isLoading;
  final String? error;

  const _DeploymentCountChip({
    this.deployments,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }

    final deps = deployments ?? [];
    final count = deps.length;
    final latestStatus = deps.isNotEmpty ? deps.first.status : null;
    final color = latestStatus != null ? _deploymentStatusColor(latestStatus) : theme.colorScheme.outline;

    return Semantics(
      label: '$count deployments. Latest status: $latestStatus.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          '$count deploy${count == 1 ? '' : 's'}',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Inline chip showing subticket count.
class _SubTicketCountChip extends StatelessWidget {
  final int count;

  const _SubTicketCountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$count sub-tickets.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count subticket${count == 1 ? '' : 's'}',
          style: TextStyle(
            color: theme.colorScheme.onSecondaryContainer,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Returns a color for a deployment status string.
Color _deploymentStatusColor(String status) {
  switch (status) {
    case 'success':
      return Colors.green;
    case 'running':
      return Colors.orange;
    case 'failed':
    case 'crashed':
      return Colors.red;
    case 'partial':
      return Colors.amber;
    default:
      return Colors.grey;
  }
}

/// A tappable row displaying a single [DocRef] with a type badge, optional
/// star for primary, and the ref path.
class _DocRefRow extends StatelessWidget {
  final DocRef docRef;
  final VoidCallback onTap;
  const _DocRefRow({required this.docRef, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _DocRefBadge(type: docRef.type),
            const SizedBox(width: 8),
            if (docRef.primary) ...[
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                docRef.path,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored badge chip showing the doc ref type abbreviation.
class _DocRefBadge extends StatelessWidget {
  final String type;
  const _DocRefBadge({required this.type});

  String get _label {
    switch (type) {
      case 'requirements':
        return 'REQ';
      case 'implementation':
        return 'IMPL';
      case 'spike':
        return 'SPIKE';
      case 'review-report':
        return 'REVIEW';
      default:
        return 'ATTACH';
    }
  }

  Color get _color {
    switch (type) {
      case 'requirements':
        return Colors.indigo;
      case 'implementation':
        return Colors.green;
      case 'spike':
        return Colors.teal;
      case 'review-report':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final TicketComment comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    comment.author,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${comment.timestamp.year}-'
                  '${comment.timestamp.month.toString().padLeft(2, '0')}-'
                  '${comment.timestamp.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                if (comment.editedAt != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    'edited',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(comment.content, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for managing ticket tags.
///
/// Shows existing tags as removable chips and an input field to add new tags.
/// [onConfirm] is called with the final tag list when the user dismisses.
///
/// Usage:
/// ```dart
/// showModalBottomSheet<void>(
///   context: context,
///   builder: (_) => _TagSheet(
///     tags: List.from(ticket.tags),
///     onConfirm: (tags) { ... },
///   ),
/// );
/// ```
class _TagSheet extends StatefulWidget {
  final List<String> tags;
  final void Function(List<String> tags) onConfirm;

  const _TagSheet({required this.tags, required this.onConfirm});

  @override
  State<_TagSheet> createState() => _TagSheetState();
}

class _TagSheetState extends State<_TagSheet> {
  late List<String> _tags;
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() => _tags.add(trimmed));
    }
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ..._tags.map(
                  (tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 36,
                  child: NoSelectTextFieldRaw(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Add tag…',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(_tags);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a field widget showing a small spinner overlaid when [isSaving] is true.
///
/// When saving, the child is wrapped in a Row with a trailing spinner so the
/// user can see which field is being saved without blocking the whole screen.
class _FieldSavingIndicator extends StatelessWidget {
  final bool isSaving;
  final Widget child;

  const _FieldSavingIndicator({
    required this.isSaving,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSaving) return child;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 6),
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }
}

/// Shimmer skeleton shown while the ticket is initially loading.
///
/// Mimics the layout of the ticket detail: title, chip row, team/assignee
/// rows, and timestamp line.
class _TicketSkeleton extends StatefulWidget {
  const _TicketSkeleton();

  @override
  State<_TicketSkeleton> createState() => _TicketSkeletonState();
}

class _TicketSkeletonState extends State<_TicketSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.outlineVariant;
    final bg = theme.colorScheme.surfaceContainerHighest;

    Widget shimmerBox({double width = double.infinity, double height = 16}) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(bg, muted, _animation.value),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shimmerBox(height: 24, width: 200),
          const SizedBox(height: 16),
          Row(children: [
            shimmerBox(width: 80, height: 28),
            const SizedBox(width: 8),
            shimmerBox(width: 70, height: 28),
            const SizedBox(width: 8),
            shimmerBox(width: 50, height: 28),
          ]),
          const SizedBox(height: 16),
          shimmerBox(height: 14, width: 120),
          const SizedBox(height: 8),
          shimmerBox(height: 14, width: 80),
          const SizedBox(height: 16),
          shimmerBox(height: 14),
          const SizedBox(height: 8),
          shimmerBox(height: 14, width: 250),
          const SizedBox(height: 24),
          shimmerBox(height: 14, width: 180),
        ],
      ),
    );
  }
}

