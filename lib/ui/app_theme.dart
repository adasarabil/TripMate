import 'package:material_ui/material_ui.dart';

abstract final class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const lightGray = Color(0xFFF2F2F2);
  static const charcoal = Color(0xFF262626);
  static const action = Color(0xFF3E3E3E);
  static const muted = Color(0xFF666666);
  static const outline = Color(0xFF999999);
  static const error = Color(0xFFBB2424);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const page = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final family = ColorScheme.fromSeed(
      seedColor: AppColors.action,
      brightness: brightness,
    );
    final colors = family.copyWith(
      primary: isDark ? const Color(0xFFE7E7E7) : AppColors.action,
      onPrimary: isDark ? AppColors.charcoal : AppColors.white,
      surface: isDark ? const Color(0xFF1B1B1B) : AppColors.white,
      surfaceContainerHighest: isDark
          ? const Color(0xFF292929)
          : AppColors.lightGray,
      onSurface: isDark ? const Color(0xFFF2F2F2) : AppColors.charcoal,
      onSurfaceVariant: isDark ? const Color(0xFFBDBDBD) : AppColors.muted,
      outline: isDark ? const Color(0xFF767676) : AppColors.outline,
      outlineVariant: isDark
          ? const Color(0xFF4B4B4B)
          : const Color(0xFFD6D6D6),
      error: isDark ? const Color(0xFFFFB4A9) : AppColors.error,
    );
    final base = ThemeData(
      colorScheme: colors,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: colors.surface,
    );
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
    );
    OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarThemeData(
        toolbarHeight: 58,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(color: colors.onSurface),
        shape: Border(bottom: BorderSide(color: colors.outline)),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.outline),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        isDense: true,
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        enabledBorder: inputBorder(colors.outline),
        focusedBorder: inputBorder(colors.primary, width: 2),
        errorBorder: inputBorder(colors.error),
        focusedErrorBorder: inputBorder(colors.error, width: 2),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.primary),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(BorderSide(color: colors.outline)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: colors.surfaceContainerHighest,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        selectedLabelStyle: text.labelSmall,
        unselectedLabelStyle: text.labelSmall,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: colors.primary,
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: text.labelLarge,
      ),
    );
  }
}
