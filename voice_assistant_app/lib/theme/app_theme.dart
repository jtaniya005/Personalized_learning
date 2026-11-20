import 'package:flutter/material.dart';

class AppColors {
  // Dark Background Palette
  static const Color bgPrimary = Color(0xFF090D16);
  static const Color bgSecondary = Color(0xFF0F172A);
  static const Color bgSurface = Color(0xFF131D31);
  static const Color bgCard = Color(0xFF1E293B);

  // Vibrant Accents
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color accentNeon = Color(0xFF38BDF8);

  // Status Colors
  static const Color statusOnline = Color(0xFF10B981); // Emerald
  static const Color statusOffline = Color(0xFFEF4444); // Crimson
  static const Color statusWarning = Color(0xFFF59E0B); // Amber
  static const Color recordingRed = Color(0xFFF43F5E); // Rose

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Glassmorphic styling constants
  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color glassBorderHighlight = Color(0x4038BDF8);

  // Gradients
  static const LinearGradient purpleCyanGradient = LinearGradient(
    colors: [primaryPurple, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoPurpleGradient = LinearGradient(
    colors: [primaryIndigo, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient recordingGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient ambientRadial = RadialGradient(
    center: Alignment(0.0, -0.4),
    radius: 1.2,
    colors: [
      Color(0x286366F1),
      Color(0x1006B6D4),
      Color(0x00090D16),
    ],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      primaryColor: AppColors.primaryIndigo,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryIndigo,
        secondary: AppColors.primaryCyan,
        surface: AppColors.bgSurface,
        error: AppColors.statusOffline,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardTheme(
        color: AppColors.bgCard.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface.withOpacity(0.8),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide:
              const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
      ),
    );
  }
}
