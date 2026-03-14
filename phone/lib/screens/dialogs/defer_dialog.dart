import 'package:flutter/material.dart';

import '../../models/feedback_payload.dart';

/// Dialog for deferring an inbox item with optional note and re-queue date.
///
/// Returns [DeferFeedback] on confirm (may have no content — fast-path).
/// Returns null if the user cancels.
///
/// Usage:
/// ```dart
/// final feedback = await DeferDialog.show(context, availableChips: chips);
/// if (feedback != null) { /* proceed */ }
/// ```
class DeferDialog extends StatefulWidget {
  final List<String> availableChips;

  const DeferDialog({super.key, required this.availableChips});

  static Future<DeferFeedback?> show(
    BuildContext context, {
    required List<String> availableChips,
  }) {
    return showDialog<DeferFeedback>(
      context: context,
      builder: (ctx) => DeferDialog(availableChips: availableChips),
    );
  }

  @override
  State<DeferDialog> createState() => _DeferDialogState();
}

class _DeferDialogState extends State<DeferDialog> {
  final _reasonController = TextEditingController();
  DateTime? _requeueAfter;
  final Set<String> _selectedChips = {};

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _toggleChip(String chip) {
    setState(() {
      if (_selectedChips.contains(chip)) {
        _selectedChips.remove(chip);
      } else {
        _selectedChips.add(chip);
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _requeueAfter ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _requeueAfter = picked);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _onDefer() {
    Navigator.pop(
      context,
      DeferFeedback(
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
        requeueAfter: _requeueAfter != null ? _formatDate(_requeueAfter!) : null,
        chips: _selectedChips.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        _requeueAfter != null ? _formatDate(_requeueAfter!) : 'Pick a date...';

    return AlertDialog(
      title: const Text('Defer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why? (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. "Pending Q2 budget"',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            const Text('Re-queue after (optional)'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  dateLabel,
                  style: _requeueAfter == null
                      ? TextStyle(color: theme.colorScheme.outline)
                      : null,
                ),
              ),
            ),
            if (widget.availableChips.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Quick chips'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.availableChips.map((chip) {
                  final selected = _selectedChips.contains(chip);
                  return FilterChip(
                    label: Text(chip),
                    selected: selected,
                    onSelected: (_) => _toggleChip(chip),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        // Defer button always enabled (fast-path: no fields = clean move)
        FilledButton.tonal(
          onPressed: _onDefer,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.withValues(alpha: 0.15),
            foregroundColor: Colors.orange.shade800,
          ),
          child: const Text('Defer'),
        ),
      ],
    );
  }
}
