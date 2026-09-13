import 'package:flutter/material.dart';

/// CueLift brand and theme tokens. See [docs/design-system.md](../../docs/design-system.md).
abstract final class CueLiftColors {
  static const navy = Color(0xFF0B1D36);
  static const coral = Color(0xFFFF4D3D);
  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F6FA);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const text = Color(0xFF0B1D36);
  static const textMuted = Color(0xFF6B7280);
  static const darkSurface = Color(0xFF121826);
  static const darkElevated = Color(0xFF1A2336);
  static const textMutedDark = Color(0xFF9AA3B2);
  static const outline = Color(0xFFD7DCE5);
  static const outlineDark = Color(0xFF2A3448);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

const _radius = 12.0;

ColorScheme _lightScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: CueLiftColors.coral,
    onPrimary: CueLiftColors.white,
    primaryContainer: Color(0xFFFFDAD4),
    onPrimaryContainer: Color(0xFF3B0600),
    secondary: CueLiftColors.navy,
    onSecondary: CueLiftColors.white,
    secondaryContainer: Color(0xFFD4DCE8),
    onSecondaryContainer: CueLiftColors.navy,
    tertiary: CueLiftColors.warning,
    onTertiary: CueLiftColors.navy,
    tertiaryContainer: Color(0xFFFFE8B8),
    onTertiaryContainer: Color(0xFF3B2A00),
    error: CueLiftColors.error,
    onError: CueLiftColors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: CueLiftColors.surface,
    onSurface: CueLiftColors.text,
    onSurfaceVariant: CueLiftColors.textMuted,
    outline: CueLiftColors.outline,
    outlineVariant: Color(0xFFC5CAD6),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: CueLiftColors.navy,
    onInverseSurface: CueLiftColors.white,
    inversePrimary: Color(0xFFFFB4A8),
    surfaceTint: CueLiftColors.coral,
  );
}

ColorScheme _darkScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: CueLiftColors.coral,
    onPrimary: CueLiftColors.white,
    primaryContainer: Color(0xFF8B1E12),
    onPrimaryContainer: Color(0xFFFFDAD4),
    secondary: Color(0xFFB8C4D6),
    onSecondary: CueLiftColors.navy,
    secondaryContainer: Color(0xFF2A3448),
    onSecondaryContainer: Color(0xFFD4DCE8),
    tertiary: CueLiftColors.warning,
    onTertiary: CueLiftColors.navy,
    tertiaryContainer: Color(0xFF5C4300),
    onTertiaryContainer: Color(0xFFFFE8B8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: CueLiftColors.darkSurface,
    onSurface: CueLiftColors.white,
    onSurfaceVariant: CueLiftColors.textMutedDark,
    outline: CueLiftColors.outlineDark,
    outlineVariant: Color(0xFF3D475C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: CueLiftColors.surface,
    onInverseSurface: CueLiftColors.text,
    inversePrimary: CueLiftColors.coral,
    surfaceTint: CueLiftColors.coral,
  );
}

ThemeData _buildTheme(ColorScheme scheme) {
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_radius),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardThemeData(
      color: scheme.brightness == Brightness.light
          ? CueLiftColors.surfaceElevated
          : CueLiftColors.darkElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
  );
}

/// Light Material 3 theme for CueLift.
final ThemeData lightTheme = _buildTheme(_lightScheme());

/// Dark Material 3 theme for CueLift.
final ThemeData darkTheme = _buildTheme(_darkScheme());

/// Fixed navy brand field for Welcome / splash (Welcome rule).
ThemeData welcomeBrandTheme() {
  final base = darkTheme;
  final scheme = base.colorScheme.copyWith(
    surface: CueLiftColors.navy,
    onSurface: CueLiftColors.white,
    onSurfaceVariant: const Color(0xFFB8C4D6),
    outline: CueLiftColors.white.withValues(alpha: 0.55),
  );
  return base.copyWith(
    scaffoldBackgroundColor: CueLiftColors.navy,
    colorScheme: scheme,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: CueLiftColors.navy,
      foregroundColor: CueLiftColors.white,
      iconTheme: const IconThemeData(color: CueLiftColors.white),
      actionsIconTheme: const IconThemeData(color: CueLiftColors.white),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CueLiftColors.white,
        side: const BorderSide(color: CueLiftColors.white, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
  );
}

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
