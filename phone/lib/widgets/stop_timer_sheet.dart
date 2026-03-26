import 'package:avodah_core/avodah_core.dart';
import 'package:flutter/material.dart';

import '../services/agent_api_client.dart';
import '../services/local_write_service.dart';

/// A bottom sheet that prompts the user for a worklog message before stopping
/// the active timer.
///
/// Shows quick comment chips (recent + per-category presets), a task picker
/// (planned first, then all active in category), and an option to save as orphan
/// (no task).
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => StopTimerSheet(
///     initialMessage: timer.note,
///     taskId: timer.taskId,
///     category: timer.category,
///     writeService: writeService,
///     apiClient: apiClient,
///     onSave: (message, markDone, taskId) async { ... },
///   ),
/// );
/// ```
class StopTimerSheet extends StatefulWidget {
  /// Pre-filled message text (from timer note). User can edit before saving.
  final String? initialMessage;

  /// Current task ID from the timer (null for orphan timers).
  final String? taskId;

  /// Category from the timer (required for orphan worklogs).
  final String? category;

  /// Service for local DB operations (loading comments and tasks).
  final LocalWriteService writeService;

  /// API client for fetching category chip presets (can be null).
  final AgentApiClient? apiClient;

  /// Called when user taps Save with a non-empty message.
  /// [taskId] is null if user chose "No task" (orphan worklog).
  final Future<void> Function(String message, bool markDone, String? taskId) onSave;

  const StopTimerSheet({
    super.key,
    this.initialMessage,
    this.taskId,
    this.category,
    required this.writeService,
    this.apiClient,
    required this.onSave,
  });

  @override
  State<StopTimerSheet> createState() => _StopTimerSheetState();
}

class _StopTimerSheetState extends State<StopTimerSheet> {
  late final TextEditingController _messageController;
  bool _markDone = false;
  bool _saving = false;
  bool _loading = true;
  String? _selectedTaskId;
  List<String> _chips = [];
  List<_TaskOption> _taskOptions = [];
  String? _selectedTaskTitle;

  @override
  void initState() {
    super.initState();
    _messageController =
        TextEditingController(text: widget.initialMessage ?? '');
    _messageController.addListener(_onMessageChanged);
    _selectedTaskId = widget.taskId;
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageChanged() => setState(() {});

  bool get _canSave =>
      _messageController.text.trim().isNotEmpty && !_saving;

  Future<void> _loadData() async {
    // Load chips from recent comments
    final recentComments = await widget.writeService.getRecentComments(limit: 10);
    final allChips = <String>{...recentComments};

    // Load category presets from API
    if (widget.category != null && widget.apiClient != null) {
      final categoryChips = await widget.apiClient!.getCategoryChips(widget.category!);
      allChips.addAll(categoryChips);
    }

    // Load task options
    final plannedIds = await widget.writeService.getTodayPlannedTaskIds();
    final categoryTasks = await widget.writeService.getTasksByCategory(widget.category);
    final allTasks = await _getAllActiveTasks();

    final options = <_TaskOption>[];

    // "No task" option (orphan)
    options.add(_TaskOption(
      id: null,
      title: 'No task (orphan)',
      isPlanned: false,
      isOrphan: true,
    ));

    // Planned tasks in today's plan
    for (final task in allTasks) {
      if (plannedIds.contains(task.id)) {
        final doc = TaskDocument.fromDrift(task: task, clock: widget.writeService.clock);
        options.add(_TaskOption(
          id: task.id,
          title: doc.title,
          isPlanned: true,
          isOrphan: false,
        ));
      }
    }

    // Category tasks (non-planned)
    for (final task in categoryTasks) {
      if (!plannedIds.contains(task.id)) {
        final doc = TaskDocument.fromDrift(task: task, clock: widget.writeService.clock);
        options.add(_TaskOption(
          id: task.id,
          title: doc.title,
          isPlanned: false,
          isOrphan: false,
        ));
      }
    }

    // Other active tasks not in this category
    for (final task in allTasks) {
      final doc = TaskDocument.fromDrift(task: task, clock: widget.writeService.clock);
      final isInOptions = options.any((o) => o.id == task.id);
      if (!isInOptions && !doc.isDone && !doc.isDeleted) {
        options.add(_TaskOption(
          id: task.id,
          title: doc.title,
          isPlanned: false,
          isOrphan: false,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _chips = allChips.toList();
        _taskOptions = options;
        _loading = false;
        // Set initial selection to current task or orphan
        if (_selectedTaskId != null) {
          final opt = options.firstWhere(
            (o) => o.id == _selectedTaskId,
            orElse: () => options.first,
          );
          _selectedTaskTitle = opt.isOrphan ? null : opt.title;
        } else {
          _selectedTaskTitle = null;
        }
      });
    }
  }

  Future<List<Task>> _getAllActiveTasks() async {
    final rows = await (widget.writeService.db.select(widget.writeService.db.tasks)).get();
    return rows.where((t) {
      final doc = TaskDocument.fromDrift(task: t, clock: widget.writeService.clock);
      return !doc.isDone && !doc.isDeleted;
    }).toList();
  }

  void _onChipTapped(String chip) {
    final text = _messageController.text;
    if (text.isEmpty) {
      _messageController.text = chip;
    } else if (!text.endsWith(' ') && !text.endsWith('\n')) {
      _messageController.text = '$text $chip';
    } else {
      _messageController.text = '$text$chip';
    }
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _onTaskSelected(_TaskOption option) {
    setState(() {
      _selectedTaskId = option.id;
      _selectedTaskTitle = option.isOrphan ? null : option.title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text('Stop Timer', style: theme.textTheme.titleLarge),
              if (widget.category != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Category: ${widget.category}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Loading indicator
              if (_loading) ...[
                const SizedBox(height: 48),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 48),
              ],

              // Task picker
              if (!_loading) ...[
                Text('Assign to task', style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _taskOptions.length,
                    itemBuilder: (ctx, index) {
                      final option = _taskOptions[index];
                      final isSelected = _selectedTaskId == option.id;
                      return ListTile(
                        dense: true,
                        leading: option.isOrphan
                            ? const Icon(Icons.block, size: 20)
                            : (option.isPlanned
                                ? const Icon(Icons.check_circle_outline, size: 20)
                                : const Icon(Icons.radio_button_unchecked, size: 20)),
                        title: Text(
                          option.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        subtitle: option.isOrphan
                            ? Text('Save as orphan with category',
                                style: theme.textTheme.bodySmall)
                            : (option.isPlanned
                                ? Text('In today\'s plan',
                                    style: theme.textTheme.bodySmall)
                                : null),
                        selected: isSelected,
                        onTap: _saving ? null : () => _onTaskSelected(option),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Worklog message
                Text('Worklog message', style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageController,
                  enabled: !_saving && !_loading,
                  minLines: 2,
                  maxLines: 5,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'What did you work on?',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),

                if (_selectedTaskId != null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Mark task as done',
                      style: theme.textTheme.bodyMedium,
                    ),
                    value: _markDone,
                    onChanged:
                        _saving ? null : (v) => setState(() => _markDone = v),
                  ),
                ],

                // Chips section
                if (_chips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Quick comments', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _chips.map((chip) {
                      return ActionChip(
                        label: Text(chip, style: theme.textTheme.bodySmall),
                        onPressed: _saving ? null : () => _onChipTapped(chip),
                      );
                    }).toList(),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSave && !_loading ? _save : null,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.stop_circle_outlined),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      // If user selected a task different from current, update timer first
      if (_selectedTaskId != null && _selectedTaskId != widget.taskId) {
        await widget.writeService.updateTimerTask(
          _selectedTaskId,
          _selectedTaskTitle,
        );
      } else if (_selectedTaskId == null && widget.taskId != null) {
        // User switched from task to orphan
        await widget.writeService.updateTimerTask(null, null);
      }
      await widget.onSave(_messageController.text.trim(), _markDone, _selectedTaskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TaskOption {
  final String? id;
  final String title;
  final bool isPlanned;
  final bool isOrphan;

  _TaskOption({
    required this.id,
    required this.title,
    required this.isPlanned,
    required this.isOrphan,
  });
}
