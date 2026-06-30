import 'package:flutter/material.dart';

// ─── Color Tokens ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF0EA5E9);

  // Status
  static const Color statusOpen = Color(0xFFF59E0B);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusAssigned = Color(0xFF8B5CF6);
  static const Color statusResolved = Color(0xFF10B981);
  static const Color statusClosed = Color(0xFF6B7280);

  // Priority
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityCritical = Color(0xFF7C3AED);

  // Light
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightText1 = Color(0xFF0F172A);
  static const Color lightText2 = Color(0xFF64748B);
  static const Color lightText3 = Color(0xFF94A3B8);

  // Dark
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkDivider = Color(0xFF334155);
  static const Color darkText1 = Color(0xFFF1F5F9);
  static const Color darkText2 = Color(0xFF94A3B8);
  static const Color darkText3 = Color(0xFF475569);
}

// ─── Theme Builder ────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final text1 = isDark ? AppColors.darkText1 : AppColors.lightText1;
    final text2 = isDark ? AppColors.darkText2 : AppColors.lightText2;
    final text3 = isDark ? AppColors.darkText3 : AppColors.lightText3;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: bg,
        onSurface: text1,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text1,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: divider,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text1,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        hintStyle: TextStyle(color: text3, fontSize: 14),
        labelStyle: TextStyle(color: text2),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bg,
        side: BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(color: text1, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: text1, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: text1, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
          color: text1,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: text1,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: text1,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(color: text1, fontSize: 15),
        bodyMedium: TextStyle(color: text2, fontSize: 14),
        bodySmall: TextStyle(color: text3, fontSize: 12),
      ),
    );
  }
}
