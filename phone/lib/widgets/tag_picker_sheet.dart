import 'package:flutter/material.dart';

/// A bottom sheet for picking tags with multi-select support.
///
/// Shows all available [tags] with checkboxes. The [selectedTags] are
/// pre-checked. Calls [onSelect] with the updated list of selected tags.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => TagPickerSheet(
///     availableTags: allTags,
///     selectedTags: currentTags,
///     onSelect: (tags) { ... },
///   ),
/// );
/// ```
class TagPickerSheet extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final void Function(List<String> tags) onSelect;

  const TagPickerSheet({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onSelect,
  });

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  'Change Tags',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    widget.onSelect(_selected);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.availableTags.isEmpty
                ? Center(
                    child: Text(
                      'No tags available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.availableTags.length,
                    itemBuilder: (context, index) {
                      final tag = widget.availableTags[index];
                      final isSelected = _selected.contains(tag);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(tag),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(tag);
                            } else {
                              _selected.remove(tag);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}