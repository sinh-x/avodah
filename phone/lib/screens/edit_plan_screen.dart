import 'package:avodah_core/avodah_core.dart';
import 'package:flutter/material.dart';

import '../services/agent_api_client.dart';
import '../services/local_write_service.dart';

/// Screen for editing today's daily plan (category hour budgets).
///
/// Shows current plan entries with edit/delete.
/// Fetches available categories from GET /api/config/categories.
/// All writes use CRDT via [LocalWriteService] and push deltas on change.
class EditPlanScreen extends StatefulWidget {
  final LocalWriteService writeService;
  final AgentApiClient? apiClient;
  final Future<void> Function(List<Map<String, dynamic>>)? onPushDeltas;

  const EditPlanScreen({
    super.key,
    required this.writeService,
    this.apiClient,
    this.onPushDeltas,
  });

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  List<DailyPlanDocument> _entries = [];
  List<String> _allCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([_loadEntries(), _loadCategories()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadEntries() async {
    final today = _today();
    final db = widget.writeService.db;
    final clock = widget.writeService.clock;
    final rows = await (db.select(db.dailyPlanEntries)
          ..where((p) => p.day.equals(today)))
        .get();
    final docs = rows
        .map((r) => DailyPlanDocument.fromDrift(entry: r, clock: clock))
        .where((d) => !d.isDeleted)
        .toList()
      ..sort((a, b) => a.category.compareTo(b.category));
    if (mounted) setState(() => _entries = docs);
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await widget.apiClient?.getCategories() ?? [];
      if (mounted) setState(() => _allCategories = cats);
    } catch (e) {
      debugPrint('[EditPlanScreen] Failed to load categories: $e');
    }
  }

  List<String> get _availableCategories {
    final planned = _entries.map((e) => e.category).toSet();
    return _allCategories.where((c) => !planned.contains(c)).toList();
  }

  Future<void> _addEntry(String category, int durationMs) async {
    final id = await widget.writeService.addPlanEntry(
      category: category,
      durationMs: durationMs,
    );
    final delta = await widget.writeService.getPlanEntryDelta(id);
    if (delta != null) widget.onPushDeltas?.call([delta]);
    await _loadEntries();
  }

  Future<void> _updateEntry(String id, int durationMs) async {
    await widget.writeService.updatePlanEntry(id: id, durationMs: durationMs);
    final delta = await widget.writeService.getPlanEntryDelta(id);
    if (delta != null) widget.onPushDeltas?.call([delta]);
    await _loadEntries();
  }

  Future<void> _removeEntry(String id) async {
    await widget.writeService.removePlanEntry(id);
    final delta = await widget.writeService.getPlanEntryDelta(id);
    if (delta != null) widget.onPushDeltas?.call([delta]);
    await _loadEntries();
  }

  void _showAddDialog() {
    final available = _availableCategories;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All categories already have plan entries.')),
      );
      return;
    }

    String? selectedCategory = available.first;
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Plan Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: available
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedCategory = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: '1h 30m',
                ),
                keyboardType: TextInputType.text,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final durationMs = _parseDuration(controller.text);
                if (durationMs <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Invalid duration. Use e.g. "1h 30m"')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                if (selectedCategory != null) {
                  _addEntry(selectedCategory!, durationMs);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(DailyPlanDocument entry) {
    final initialText = _formatDurationForEdit(entry.durationMs);
    final controller = TextEditingController(text: initialText);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${entry.category}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Duration',
            hintText: '1h 30m',
          ),
          keyboardType: TextInputType.text,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final durationMs = _parseDuration(controller.text);
              if (durationMs <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Invalid duration. Use e.g. "1h 30m"')),
                );
                return;
              }
              Navigator.pop(ctx);
              _updateEntry(entry.id, durationMs);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = _availableCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add category',
            onPressed: available.isNotEmpty ? _showAddDialog : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart,
                          size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('No plan entries yet',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 16),
                      if (available.isNotEmpty)
                        FilledButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add category'),
                        ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _entries.length,
                  separatorBuilder: (_, i) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final entry = _entries[i];
                    return Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red,
                        child:
                            const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _removeEntry(entry.id),
                      child: ListTile(
                        title: Text(entry.category),
                        subtitle: Text(_formatDuration(entry.durationMs)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit duration',
                          onPressed: () => _showEditDialog(entry),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  static String _formatDurationForEdit(int ms) => _formatDuration(ms);

  /// Parses "1h 30m", "2h", "45m", "90" (bare number → minutes) into ms.
  static int _parseDuration(String input) {
    final s = input.trim().toLowerCase();
    if (s.isEmpty) return 0;

    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(s);
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(s);

    int hours = 0;
    int minutes = 0;

    if (hourMatch != null) {
      hours = int.tryParse(hourMatch.group(1)!) ?? 0;
    }
    if (minMatch != null) {
      minutes = int.tryParse(minMatch.group(1)!) ?? 0;
    }

    // Bare number → treat as minutes
    if (hourMatch == null && minMatch == null) {
      minutes = int.tryParse(s) ?? 0;
    }

    return (hours * 60 + minutes) * 60 * 1000;
  }
}
