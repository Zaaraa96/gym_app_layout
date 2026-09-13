import 'package:flutter/material.dart';

const _seed = Colors.deepPurple;

/// Light Material 3 theme for the gym app.
final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  brightness: Brightness.light,
);

/// Dark Material 3 theme for the gym app.
final ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  brightness: Brightness.dark,
);

/// Attention / warning accents that stay readable on light and dark surfaces.
Color attentionColor(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark
        ? scheme.tertiary
        : const Color(0xFFFFA000); // amber.shade700

Color attentionContainer(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark
        ? scheme.tertiaryContainer
        : const Color(0xFFFFF8E1); // amber.shade50

Color onAttention(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark
        ? scheme.onTertiaryContainer
        : const Color(0xFFFF8F00); // amber.shade800
