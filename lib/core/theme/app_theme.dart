import 'package:flutter/material.dart';

class AppTheme {
  // Obsidian-inspired colors
  static const Color primaryColor = Color(0xFF7C3AED);
  static const Color secondaryColor = Color(0xFF6366F1);
  static const Color accentColor = Color(0xFF06B6D4);

  // Light theme colors (Modern minimalist)
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSidebarBackground = Color(0xFFF8F9FA);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightOnSurface = Color(0xFF1E293B);
  static const Color lightOnBackground = Color(0xFF334155);
  static const Color lightSecondaryText = Color(0xFF64748B);
  static const Color lightHover = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Dark theme colors (Obsidian-inspired)
  static const Color darkBackground = Color(0xFF0B0D0F);
  static const Color darkSurface = Color(0xFF161719);
  static const Color darkSidebarBackground = Color(0xFF121315);
  static const Color darkBorder = Color(0xFF2A2D31);
  static const Color darkOnSurface = Color(0xFFE2E8F0);
  static const Color darkOnBackground = Color(0xFFCBD5E1);
  static const Color darkSecondaryText = Color(0xFF94A3B8);
  static const Color darkHover = Color(0xFF1E2124);
  static const Color darkCard = Color(0xFF1A1C1E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        background: lightBackground,
        onSurface: lightOnSurface,
        onBackground: lightOnBackground,
        tertiary: accentColor,
        outline: lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightOnSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: lightOnSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightOnSurface,
        ),
        bodyLarge: TextStyle(fontSize: 14, color: lightOnSurface),
        bodyMedium: TextStyle(fontSize: 13, color: lightSecondaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightSecondaryText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        background: darkBackground,
        onSurface: darkOnSurface,
        onBackground: darkOnBackground,
        tertiary: accentColor,
        outline: darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: darkOnSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkOnSurface,
        ),
        bodyLarge: TextStyle(fontSize: 14, color: darkOnSurface),
        bodyMedium: TextStyle(fontSize: 13, color: darkSecondaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkSecondaryText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
