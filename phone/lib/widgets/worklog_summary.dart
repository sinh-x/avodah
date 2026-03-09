import 'package:flutter/material.dart';

import '../models/snapshot.dart';

class WorklogSummary extends StatelessWidget {
  final WorklogSummarySnapshot worklog;

  const WorklogSummary({super.key, required this.worklog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Time Logged',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(worklog.total,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            if (worklog.tasks.isNotEmpty) ...[
              const Divider(),
              ...worklog.tasks.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(t.title,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(t.total,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
