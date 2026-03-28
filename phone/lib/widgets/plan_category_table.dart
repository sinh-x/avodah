import 'package:flutter/material.dart';

import '../models/snapshot.dart';
import 'task_action_sheet.dart';

class PlanCategoryTable extends StatefulWidget {
  final PlanSnapshot plan;

  /// The category of the currently active timer, if any.
  /// When set, the matching category row will be visually highlighted.
  final String? activeCategory;

  /// Called when the user taps the Edit button in the card header.
  final VoidCallback? onEditPlan;

  /// Called when the user taps a category row to start a timer.
  final void Function(String category)? onCategoryTap;

  /// Planned tasks to render nested under their category headers.
  final List<PlannedTaskSnapshot>? plannedTasks;

  /// Current active timer — passed to the action sheet for confirmation.
  final TimerSnapshot? activeTimer;

  /// Called when user wants to toggle the done state of a task.
  final Future<void> Function(String taskId)? onToggleDone;

  /// Called when user wants to start the timer for a task.
  final Future<void> Function(String taskId, String taskTitle)? onStartTimer;

  const PlanCategoryTable({
    super.key,
    required this.plan,
    this.activeCategory,
    this.onEditPlan,
    this.onCategoryTap,
    this.plannedTasks,
    this.activeTimer,
    this.onToggleDone,
    this.onStartTimer,
  });

  @override
  State<PlanCategoryTable> createState() => _PlanCategoryTableState();
}

class _PlanCategoryTableState extends State<PlanCategoryTable> {
  /// Expand/collapse state keyed by category name.
  /// Defaults to expanded (true) for all categories.
  final Map<String, bool> _expandedState = {};

  bool _isExpanded(String category) => _expandedState[category] ?? true;

  void _toggleExpanded(String category) {
    setState(() {
      _expandedState[category] = !(_expandedState[category] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPlannedTasks =
        widget.plannedTasks != null && widget.plannedTasks!.isNotEmpty;

    // Group planned tasks by category
    final Map<String, List<PlannedTaskSnapshot>> tasksByCategory = {};
    final List<PlannedTaskSnapshot> uncategorizedTasks = [];
    if (hasPlannedTasks) {
      for (final task in widget.plannedTasks!) {
        if (task.category != null && task.category!.isNotEmpty) {
          tasksByCategory.putIfAbsent(task.category!, () => []).add(task);
        } else {
          uncategorizedTasks.add(task);
        }
      }
    }

    if (widget.plan.categories.isEmpty && widget.plan.nonCategorized == null && !hasPlannedTasks) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with edit button (empty state)
              Row(
                children: [
                  Icon(Icons.bar_chart, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Plan vs Actual',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '${widget.plan.totalPlanned} planned / ${widget.plan.totalActual} actual',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  if (widget.onEditPlan != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit plan',
                      onPressed: widget.onEditPlan,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.bar_chart, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Plan vs Actual',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '${widget.plan.totalPlanned} planned / ${widget.plan.totalActual} actual',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                if (widget.onEditPlan != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit plan',
                    onPressed: widget.onEditPlan,
                  ),
                ],
              ],
            ),
            const Divider(),

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text('Category',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline))),
                  Expanded(
                      child: Text('Plan',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline))),
                  Expanded(
                      child: Text('Actual',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline))),
                  Expanded(
                      child: Text('Delta',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline))),
                ],
              ),
            ),

            // Category rows with nested tasks
            for (final c in widget.plan.categories) ...[
              _CategoryRowWithTasks(
                category: c,
                tasks: tasksByCategory[c.category],
                expanded: _isExpanded(c.category),
                onToggleExpanded: () => _toggleExpanded(c.category),
                activeCategory: widget.activeCategory,
                onCategoryTap: widget.onCategoryTap != null
                    ? () => widget.onCategoryTap!(c.category)
                    : null,
                activeTimer: widget.activeTimer,
                onToggleDone: widget.onToggleDone,
                onStartTimer: widget.onStartTimer,
              ),
            ],

            // Non-categorized (from plan)
            if (widget.plan.nonCategorized != null) ...[
              const Divider(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Non-Categorized',
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.outline))),
                    const Expanded(child: SizedBox()),
                    Expanded(
                        child: Text(widget.plan.nonCategorized!.actual,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall)),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ],

            // Uncategorized planned tasks at the bottom
            if (uncategorizedTasks.isNotEmpty) ...[
              const Divider(height: 8),
              _UncategorizedTaskGroup(
                tasks: uncategorizedTasks,
                expanded: _isExpanded('__uncategorized__'),
                onToggleExpanded: () => _toggleExpanded('__uncategorized__'),
                activeTimer: widget.activeTimer,
                onToggleDone: widget.onToggleDone,
                onStartTimer: widget.onStartTimer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryRowWithTasks extends StatelessWidget {
  final PlanCategorySnapshot category;
  final List<PlannedTaskSnapshot>? tasks;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final String? activeCategory;
  final VoidCallback? onCategoryTap;
  final TimerSnapshot? activeTimer;
  final Future<void> Function(String taskId)? onToggleDone;
  final Future<void> Function(String taskId, String taskTitle)? onStartTimer;

  const _CategoryRowWithTasks({
    required this.category,
    this.tasks,
    required this.expanded,
    required this.onToggleExpanded,
    this.activeCategory,
    this.onCategoryTap,
    this.activeTimer,
    this.onToggleDone,
    this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = category.category == activeCategory;
    final deltaColor = category.deltaMs > 0
        ? Colors.green.shade700
        : category.deltaMs < 0
            ? Colors.red.shade700
            : theme.colorScheme.outline;

    return Column(
      children: [
        InkWell(
          onTap: onToggleExpanded,
          borderRadius: BorderRadius.circular(4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    decoration: isActive
                        ? BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          )
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                            flex: 3,
                            child: Text(category.category,
                                style: theme.textTheme.bodyMedium)),
                        Expanded(
                            child: Text(category.planned,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.bodySmall)),
                        Expanded(
                            child: Text(category.actual,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600))),
                        Expanded(
                            child: Text(category.delta,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: deltaColor))),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onCategoryTap,
                          child: Icon(
                            Icons.play_arrow,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress bar
                  if (category.plannedMs > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (category.actualMs / category.plannedMs).clamp(0.0, 1.0),
                          minHeight: 3,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            category.actualMs > category.plannedMs
                                ? Colors.red.shade400
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Nested tasks (expanded)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildTaskList(context),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildTaskList(BuildContext context) {
    if (tasks == null || tasks!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Column(
        children: tasks!
            .map((t) => _NestedTaskRow(
                  task: t,
                  activeTimer: activeTimer,
                  onToggleDone: onToggleDone,
                  onStartTimer: onStartTimer,
                ))
            .toList(),
      ),
    );
  }
}

class _UncategorizedTaskGroup extends StatelessWidget {
  final List<PlannedTaskSnapshot> tasks;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final TimerSnapshot? activeTimer;
  final Future<void> Function(String taskId)? onToggleDone;
  final Future<void> Function(String taskId, String taskTitle)? onStartTimer;

  const _UncategorizedTaskGroup({
    required this.tasks,
    required this.expanded,
    required this.onToggleExpanded,
    this.activeTimer,
    this.onToggleDone,
    this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: onToggleExpanded,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Uncategorized',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.outline),
                  ),
                ),
                Text(
                  '${tasks.where((t) => t.isDone).length}/${tasks.length}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            child: Column(
              children: tasks
                  .map((t) => _NestedTaskRow(
                        task: t,
                        activeTimer: activeTimer,
                        onToggleDone: onToggleDone,
                        onStartTimer: onStartTimer,
                      ))
                  .toList(),
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _NestedTaskRow extends StatelessWidget {
  final PlannedTaskSnapshot task;
  final TimerSnapshot? activeTimer;
  final Future<void> Function(String taskId)? onToggleDone;
  final Future<void> Function(String taskId, String taskTitle)? onStartTimer;

  const _NestedTaskRow({
    required this.task,
    this.activeTimer,
    this.onToggleDone,
    this.onStartTimer,
  });

  void _openActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => TaskActionSheet(
        task: task,
        activeTimer: activeTimer,
        onStartTimer: onStartTimer,
        onToggleDone: onToggleDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final IconData icon;
    final Color iconColor;
    if (task.isDone) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (task.isCancelled) {
      icon = Icons.cancel;
      iconColor = Colors.red.shade300;
    } else {
      icon = Icons.radio_button_unchecked;
      iconColor = theme.colorScheme.outline;
    }

    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      decoration: task.isDone || task.isCancelled
          ? TextDecoration.lineThrough
          : null,
      color: task.isDone || task.isCancelled
          ? theme.colorScheme.outline
          : null,
    );

    return InkWell(
      onTap: task.isCancelled ? null : () => _openActionSheet(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: titleStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (task.estimateMs > 0) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text(
                  task.estimate,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              child: Text(
                task.logged,
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
