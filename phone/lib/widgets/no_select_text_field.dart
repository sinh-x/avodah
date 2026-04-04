import 'package:flutter/material.dart';

/// A TextField that places cursor at tap position on single tap,
/// without selecting text. Preserves double-tap word selection.
///
/// Works around flutter/flutter#98720, #105185 where single taps in
/// TextFields can unexpectedly select words instead of placing cursor.
class NoSelectTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const NoSelectTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.maxLines,
    this.minLines,
    this.style,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  State<NoSelectTextField> createState() => _NoSelectTextFieldFormFieldState();
}

class _NoSelectTextFieldFormFieldState extends State<NoSelectTextField> {
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
        minLines: widget.minLines,
        style: widget.style,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        textCapitalization: widget.textCapitalization,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
        textInputAction: widget.textInputAction,
      ),
    );
  }
}

/// A TextField variant that uses [TextField] instead of [TextFormField],
/// for callers that do not need validation.
class NoSelectTextFieldRaw extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const NoSelectTextFieldRaw({
    super.key,
    required this.controller,
    this.decoration,
    this.maxLines,
    this.minLines,
    this.style,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  State<NoSelectTextFieldRaw> createState() => _NoSelectTextFieldRawState();
}

class _NoSelectTextFieldRawState extends State<NoSelectTextFieldRaw> {
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
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        style: widget.style,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        textCapitalization: widget.textCapitalization,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
