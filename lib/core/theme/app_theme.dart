import 'package:flutter/material.dart';

import 'app_colors.dart';

/// خطوط التطبيق: Almarai للواجهة، Amiri لنصوص الأذكار.
class AppFonts {
  AppFonts._();

  static const String ui = 'Almarai';
  static const String quran = 'Amiri';
}

/// ثيم التطبيق (فاتح + داكن) مع دعم RTL الكامل.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color bg = isDark ? AppColors.backgroundDark : AppColors.background;
    final Color surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final Color textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final Color textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final Color divider = isDark ? AppColors.dividerDark : AppColors.divider;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.primaryLight : AppColors.primary,
      surface: surface,
    );

    final TextTheme textTheme = _textTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: AppFonts.ui,
      textTheme: textTheme,
      dividerColor: divider,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (isDark ? AppColors.textSecondaryDark : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: divider),
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceMutedDark : AppColors.primaryDark,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 15,
        height: 1.7,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 14,
        height: 1.7,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: secondary,
      ),
    );
  }

  /// زخرفة الكروت الموحّدة في التطبيق.
  /// (نستخدم Container بدل CardTheme لتفادي اختلاف واجهة CardTheme بين إصدارات Flutter.)
  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? color,
    Color? borderColor,
    double radius = 20,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.surfaceDark : AppColors.surface),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (isDark ? AppColors.dividerDark : AppColors.divider),
      ),
    );
  }

  /// نمط نص الذكر نفسه — خط نسخ بحجم مريح وتباعد أسطر واسع.
  static TextStyle dhikrTextStyle(BuildContext context, {double scale = 1.0}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: AppFonts.quran,
      fontSize: 21 * scale,
      height: 1.95,
      fontWeight: FontWeight.w400,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );
  }
}
