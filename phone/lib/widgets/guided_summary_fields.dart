import 'package:flutter/material.dart';

import '../config/ticket_type_config.dart';

/// Widget that renders dynamic guided input fields based on the selected ticket type.
///
/// Shows a [GuidedField] for each field in the type's [TicketTypeConfig.fields].
/// Call [getValues] to retrieve the current field values as a map.
class GuidedSummaryFields extends StatefulWidget {
  /// The currently selected ticket type.
  final PhoneTicketType selectedType;

  /// Called when the field values change.
  final ValueChanged<Map<String, String>>? onChanged;

  const GuidedSummaryFields({
    super.key,
    required this.selectedType,
    this.onChanged,
  });

  @override
  GuidedSummaryFieldsState createState() => GuidedSummaryFieldsState();
}

class GuidedSummaryFieldsState extends State<GuidedSummaryFields> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(GuidedSummaryFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    final config = kTicketTypeConfigs[widget.selectedType]!;
    for (final field in config.fields) {
      _controllers[field.templateKey] = TextEditingController();
      _errors[field.templateKey] = null;
    }
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _errors.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged?.call(getValues());
  }

  /// Returns the current field values as a map of templateKey -> value.
  Map<String, String> getValues() {
    return _controllers.map((k, v) => MapEntry(k, v.text));
  }

  /// Validates all required fields. Returns true if valid.
  bool validate() {
    bool valid = true;
    final config = kTicketTypeConfigs[widget.selectedType]!;

    setState(() {
      for (final field in config.fields) {
        if (field.required) {
          final text = _controllers[field.templateKey]?.text.trim() ?? '';
          if (text.isEmpty) {
            _errors[field.templateKey] = '${field.label} is required';
            valid = false;
          } else {
            _errors[field.templateKey] = null;
          }
        }
      }
    });

    return valid;
  }

  Widget _buildTextField(GuidedField field) {
    final controller = _controllers[field.templateKey]!;
    final error = _errors[field.templateKey];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _NoSelectTextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          hintText: field.hint,
          border: const OutlineInputBorder(),
          isDense: true,
          errorText: error,
        ),
        maxLines: field.templateKey == 'REPRO' ? 4 : 2,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) {
          // Clear error on change
          if (_errors[field.templateKey] != null) {
            setState(() => _errors[field.templateKey] = null);
            _notifyChanged();
          }
        },
      ),
    );
  }

  Widget _buildDropdownField(GuidedField field) {
    final controller = _controllers[field.templateKey];
    final error = _errors[field.templateKey];
    final options = field.options!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: controller!.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          border: const OutlineInputBorder(),
          isDense: true,
          errorText: error,
        ),
        hint: Text(field.hint),
        items: options.map((o) {
          // Capitalize first letter for display
          final label = o[0].toUpperCase() + o.substring(1);
          return DropdownMenuItem(value: o, child: Text(label));
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
            if (_errors[field.templateKey] != null) {
              setState(() => _errors[field.templateKey] = null);
            }
            _notifyChanged();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = kTicketTypeConfigs[widget.selectedType]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in config.fields)
          if (field.options != null)
            _buildDropdownField(field)
          else
            _buildTextField(field),
      ],
    );
  }
}

/// A TextField that places cursor at tap position on single tap,
/// without selecting text. Preserves double-tap word selection.
///
/// Works around flutter/flutter#98720, #105185 where single taps in
/// TextFields can unexpectedly select words instead of placing cursor.
class _NoSelectTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  const _NoSelectTextField({
    required this.controller,
    this.decoration,
    this.maxLines,
    this.onChanged,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
  });

  @override
  State<_NoSelectTextField> createState() => _NoSelectTextFieldState();
}

class _NoSelectTextFieldState extends State<_NoSelectTextField> {
  Offset? _tapPosition;

  void _handleTapDown(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _handleTap() {
    if (_tapPosition == null) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(_tapPosition!);

    final textPainter = TextPainter(
      text: TextSpan(text: widget.controller.text),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: renderBox.size.width);

    final textPosition = textPainter.getPositionForOffset(localPosition);
    widget.controller.selection = TextSelection.collapsed(
      offset: textPosition.offset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: TextFormField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        textCapitalization: widget.textCapitalization,
      ),
    );
  }
}
