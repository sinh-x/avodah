import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences storage.
const kDisplayBrightnessKey = 'display_brightness';
const kDisplayAccentColorKey = 'display_accent_color';
const kDisplayContrastKey = 'display_contrast';

/// Brightness options.
enum DisplayBrightness {
  light,
  dark,
  system;

  String get key {
    switch (this) {
      case DisplayBrightness.light:
        return 'light';
      case DisplayBrightness.dark:
        return 'dark';
      case DisplayBrightness.system:
        return 'system';
    }
  }

  static DisplayBrightness fromKey(String key) {
    switch (key) {
      case 'light':
        return DisplayBrightness.light;
      case 'dark':
        return DisplayBrightness.dark;
      default:
        return DisplayBrightness.system;
    }
  }

  Brightness? toFlutterBrightness() {
    switch (this) {
      case DisplayBrightness.light:
        return Brightness.light;
      case DisplayBrightness.dark:
        return Brightness.dark;
      case DisplayBrightness.system:
        return null;
    }
  }
}

/// Contrast options.
enum DisplayContrast {
  normal,
  high;

  String get key {
    switch (this) {
      case DisplayContrast.normal:
        return 'normal';
      case DisplayContrast.high:
        return 'high';
    }
  }

  static DisplayContrast fromKey(String key) {
    switch (key) {
      case 'high':
        return DisplayContrast.high;
      default:
        return DisplayContrast.normal;
    }
  }
}

/// Predefined accent color swatches.
///
/// Order: Purple (default), Blue, Teal, Green, Orange, Red, Pink, Grey.
const List<Color> kAccentColors = [
  Color(0xFF6750A4), // Purple (default)
  Color(0xFF1976D2), // Blue
  Color(0xFF00796B), // Teal
  Color(0xFF388E3C), // Green
  Color(0xFFF57C00), // Orange
  Color(0xFFD32F2F), // Red
  Color(0xFFC2185B), // Pink
  Color(0xFF616161), // Grey
];

/// Default accent color (purple).
const Color kDefaultAccentColor = Color(0xFF6750A4);

/// SharedPreferences-backed display settings service.
///
/// Exposes reactive settings via ChangeNotifier so the UI rebuilds
/// automatically when any setting changes.
class DisplaySettingsService extends ChangeNotifier {
  SharedPreferences? _prefs;

  DisplayBrightness _brightness = DisplayBrightness.system;
  Color _accentColor = kDefaultAccentColor;
  DisplayContrast _contrast = DisplayContrast.normal;

  DisplayBrightness get brightness => _brightness;
  Color get accentColor => _accentColor;
  DisplayContrast get contrast => _contrast;

  /// Loads settings from SharedPreferences.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final brightnessKey = _prefs!.getString(kDisplayBrightnessKey) ?? 'system';
    _brightness = DisplayBrightness.fromKey(brightnessKey);

    final accentColorValue = _prefs!.getInt(kDisplayAccentColorKey);
    _accentColor =
        accentColorValue != null ? Color(accentColorValue) : kDefaultAccentColor;

    final contrastKey = _prefs!.getString(kDisplayContrastKey) ?? 'normal';
    _contrast = DisplayContrast.fromKey(contrastKey);

    notifyListeners();
  }

  Future<SharedPreferences> get _prefsReady async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> setBrightness(DisplayBrightness value) async {
    if (_brightness == value) return;
    _brightness = value;
    final prefs = await _prefsReady;
    await prefs.setString(kDisplayBrightnessKey, value.key);
    notifyListeners();
  }

  Future<void> setAccentColor(Color value) async {
    if (_accentColor == value) return;
    _accentColor = value;
    final prefs = await _prefsReady;
    await prefs.setInt(kDisplayAccentColorKey, value.toARGB32());
    notifyListeners();
  }

  Future<void> setContrast(DisplayContrast value) async {
    if (_contrast == value) return;
    _contrast = value;
    final prefs = await _prefsReady;
    await prefs.setString(kDisplayContrastKey, value.key);
    notifyListeners();
  }

  /// Builds the light ThemeData from current settings.
  ThemeData lightTheme() {
    return ThemeData(
      colorSchemeSeed: _accentColor,
      useMaterial3: true,
      brightness: _brightness.toFlutterBrightness() ?? Brightness.light,
    );
  }

  /// Builds the dark ThemeData from current settings.
  ThemeData darkTheme() {
    return ThemeData(
      colorSchemeSeed: _accentColor,
      useMaterial3: true,
      brightness: _brightness.toFlutterBrightness() ?? Brightness.dark,
    );
  }
}

/// Syntax highlighting colors based on contrast mode.
class SyntaxColors {
  final Color defaultColor;
  final Color keyword;
  final Color builtIn;
  final Color type;
  final Color literal;
  final Color number;
  final Color string;
  final Color comment;
  final bool isHighContrast;

  const SyntaxColors({
    required this.defaultColor,
    required this.keyword,
    required this.builtIn,
    required this.type,
    required this.literal,
    required this.number,
    required this.string,
    required this.comment,
    required this.isHighContrast,
  });

  /// Normal contrast syntax colors.
  static const normal = SyntaxColors(
    defaultColor: Color(0xFFE0E0E0),
    keyword: Color(0xFF9E9E9E),
    builtIn: Color(0xFF8D8D8D),
    type: Color(0xFF7A8B9A),
    literal: Color(0xFF8D8D8D),
    number: Color(0xFF9E9E9E),
    string: Color(0xFF8A8A8A),
    comment: Color(0xFF6B7B6B),
    isHighContrast: false,
  );

  /// High contrast syntax colors.
  static const high = SyntaxColors(
    defaultColor: Color(0xFFFFFFFF),
    keyword: Color(0xFFB0B0B0),
    builtIn: Color(0xFFA0A0A0),
    type: Color(0xFF90B0C0),
    literal: Color(0xFFA0A0A0),
    number: Color(0xFFB0B0B0),
    string: Color(0xFFA0A0A0),
    comment: Color(0xFF8B9B8B),
    isHighContrast: true,
  );

  Color forClass(String? className) {
    if (className == null || className.isEmpty) {
      return defaultColor;
    }

    final firstClass = className.split(' ').first;
    return switch (firstClass) {
      'keyword' => keyword,
      'built_in' => builtIn,
      'type' => type,
      'literal' => literal,
      'number' => number,
      'string' => string,
      'comment' || 'doctag' => comment,
      'meta' => defaultColor,
      'function' || 'class' || 'title' || 'attr' || 'variable' => type,
      'selector-tag' || 'selector-id' || 'selector-class' ||
      'bullet' || 'section' || 'subst' || 'emphasis' || 'strong' ||
      'tag' || 'name' => keyword,
      'template-variable' => keyword,
      _ => defaultColor,
    };
  }
}

/// Flutter ThemeExtension for syntax highlighting colors.
class SyntaxThemeExtension extends ThemeExtension<SyntaxThemeExtension> {
  final SyntaxColors syntaxColors;

  const SyntaxThemeExtension({required this.syntaxColors});

  @override
  SyntaxThemeExtension copyWith({SyntaxColors? syntaxColors}) {
    return SyntaxThemeExtension(syntaxColors: syntaxColors ?? this.syntaxColors);
  }

  @override
  SyntaxThemeExtension lerp(
    ThemeExtension<SyntaxThemeExtension>? other,
    double t,
  ) {
    if (other is! SyntaxThemeExtension) return this;
    return this;
  }
}

/// Extension on ThemeData to get SyntaxColors from the theme extension.
extension ThemeDataSyntaxColors on ThemeData {
  SyntaxColors get syntaxColors {
    final ext = extension<SyntaxThemeExtension>();
    return ext?.syntaxColors ?? SyntaxColors.normal;
  }
}
