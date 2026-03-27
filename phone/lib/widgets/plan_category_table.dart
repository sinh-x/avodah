import 'package:flutter/material.dart';

import '../models/snapshot.dart';

class PlanCategoryTable extends StatelessWidget {
  final PlanSnapshot plan;

  /// The category of the currently active timer, if any.
  /// When set, the matching category row will be visually highlighted.
  final String? activeCategory;

  /// Called when the user taps the Edit button in the card header.
  final VoidCallback? onEditPlan;

  /// Called when the user taps a category row to start a timer.
  final void Function(String category)? onCategoryTap;

  const PlanCategoryTable({
    super.key,
    required this.plan,
    this.activeCategory,
    this.onEditPlan,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (plan.categories.isEmpty && plan.nonCategorized == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No plan set for today',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.outline)),
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
                  '${plan.totalPlanned} planned / ${plan.totalActual} actual',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                if (onEditPlan != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit plan',
                    onPressed: onEditPlan,
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

            // Category rows
            ...plan.categories.map((c) => _CategoryRow(
                  category: c,
                  activeCategory: activeCategory,
                  onTap: onCategoryTap != null ? () => onCategoryTap!(c.category) : null,
                )),

            // Non-categorized
            if (plan.nonCategorized != null) ...[
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
                        child: Text(plan.nonCategorized!.actual,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall)),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final PlanCategorySnapshot category;
  final String? activeCategory;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.category,
    this.activeCategory,
    this.onTap,
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

    return InkWell(
      onTap: onTap,
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
                    Icon(
                      Icons.play_arrow,
                      size: 20,
                      color: theme.colorScheme.primary,
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
    );
  }
}
