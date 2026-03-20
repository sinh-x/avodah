import 'package:flutter/material.dart';

/// A bottom sheet that prompts the user for a worklog message before stopping
/// the active timer.
///
/// The message field is pre-filled from the timer note and is required —
/// the Save button is disabled until the field is non-empty.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => StopTimerSheet(
///     initialMessage: timer.note,
///     taskId: timer.taskId,
///     onSave: (message, markDone) async { ... },
///   ),
/// );
/// ```
class StopTimerSheet extends StatefulWidget {
  /// Pre-filled message text (from timer note). User can edit before saving.
  final String? initialMessage;

  /// Task ID for the mark-as-done toggle. If null, the toggle is hidden.
  final String? taskId;

  /// Called when user taps Save with a non-empty message.
  final Future<void> Function(String message, bool markDone) onSave;

  const StopTimerSheet({
    super.key,
    this.initialMessage,
    this.taskId,
    required this.onSave,
  });

  @override
  State<StopTimerSheet> createState() => _StopTimerSheetState();
}

class _StopTimerSheetState extends State<StopTimerSheet> {
  late final TextEditingController _messageController;
  bool _markDone = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _messageController =
        TextEditingController(text: widget.initialMessage ?? '');
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageChanged() => setState(() {});

  bool get _canSave =>
      _messageController.text.trim().isNotEmpty && !_saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
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
              const SizedBox(height: 16),

              Text('Worklog message', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                enabled: !_saving,
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

              if (widget.taskId != null) ...[
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

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSave ? _save : null,
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
      await widget.onSave(_messageController.text.trim(), _markDone);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
