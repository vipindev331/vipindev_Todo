import 'package:flutter/material.dart';

/// The whole app is built from exactly two colours:
///
///  * [primary] — the brand blue, used for every interactive/accent surface.
///  * [ink]     — the near-black navy, used for text, borders and surfaces.
///
/// Every other tone in the UI is one of those two blended with white or with
/// each other, so the palette never grows beyond two hues.
abstract final class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color ink = Color(0xFF0B1220);

  /// Background of the rounded header block on both screens.
  static Color header(Brightness brightness) => brightness == Brightness.light
      ? primary
      : Color.alphaBlend(primary.withValues(alpha: 0.22), ink);

  static const Color onHeader = Colors.white;
}

/// Shared shape/spacing constants so both screens stay visually identical.
abstract final class AppShape {
  const AppShape._();

  static const double screenPadding = 20;
  static const double headerRadius = 28;
  static const double cardRadius = 20;
  static const double fieldRadius = 16;

  static BorderRadius get card => BorderRadius.circular(cardRadius);
  static BorderRadius get field => BorderRadius.circular(fieldRadius);
}

abstract final class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(_lightScheme());
  static ThemeData dark() => _build(_darkScheme());

  static ColorScheme _lightScheme() {
    const surface = Colors.white;
    Color onWhite(Color color, double alpha) =>
        Color.alphaBlend(color.withValues(alpha: alpha), surface);

    return ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: onWhite(AppColors.primary, 0.10),
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: AppColors.ink,
      surfaceContainerLowest: surface,
      surfaceContainerLow: onWhite(AppColors.ink, 0.02),
      surfaceContainer: onWhite(AppColors.ink, 0.035),
      surfaceContainerHigh: onWhite(AppColors.ink, 0.05),
      surfaceContainerHighest: onWhite(AppColors.ink, 0.07),
      onSurfaceVariant: onWhite(AppColors.ink, 0.60),
      outline: onWhite(AppColors.ink, 0.28),
      outlineVariant: onWhite(AppColors.ink, 0.12),
      // Errors are expressed with ink + iconography rather than a third hue.
      error: AppColors.ink,
      onError: Colors.white,
    );
  }

  static ColorScheme _darkScheme() {
    const surface = AppColors.ink;
    Color onInk(Color color, double alpha) =>
        Color.alphaBlend(color.withValues(alpha: alpha), surface);

    return ColorScheme(
      brightness: Brightness.dark,
      primary: Color.lerp(AppColors.primary, Colors.white, 0.28)!,
      onPrimary: Colors.white,
      primaryContainer: onInk(AppColors.primary, 0.24),
      onPrimaryContainer: Color.lerp(AppColors.primary, Colors.white, 0.55)!,
      secondary: Color.lerp(AppColors.primary, Colors.white, 0.28)!,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onInk(Colors.white, 0.92),
      surfaceContainerLowest: surface,
      surfaceContainerLow: onInk(Colors.white, 0.04),
      surfaceContainer: onInk(Colors.white, 0.06),
      surfaceContainerHigh: onInk(Colors.white, 0.09),
      surfaceContainerHighest: onInk(Colors.white, 0.12),
      onSurfaceVariant: onInk(Colors.white, 0.62),
      outline: onInk(Colors.white, 0.32),
      outlineVariant: onInk(Colors.white, 0.14),
      error: onInk(Colors.white, 0.92),
      onError: AppColors.ink,
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppShape.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: base.textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppShape.field,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShape.field,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShape.field,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: AppShape.field),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: AppShape.field),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppShape.card),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.45,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppShape.field),
          ),
        ),
      ),
    );
  }
}
