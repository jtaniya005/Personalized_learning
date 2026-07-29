import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_settings.dart';

/// ─────────────────────────────────────────────────────────
/// DESIGN SYSTEM — "Notebook & Marigold"
/// Inspired by the Indian school notebook: cream ruled pages,
/// ink, and the marigold-orange of exam-season highlighter caps.
/// Warm, handwritten-feeling, never corporate-edtech-blue.
///
/// Surface/text colors below are dynamic getters that read
/// [isDarkNotifier] — dark mode keeps the same warm notebook
/// feeling (warm near-black paper, not cold pure black) rather
/// than swapping to a generic Material dark theme.
/// ─────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static bool get _dark => isDarkNotifier.value;

  static Color get paper => _dark ? const Color(0xFF1C1A16) : const Color(0xFFFBF7EF);
  static Color get paperCard => _dark ? const Color(0xFF29261F) : const Color(0xFFF3EBDA);
  static Color get rule => _dark ? const Color(0xFF3E3A30) : const Color(0xFFDCD0B4);
  static Color get ink => _dark ? const Color(0xFFF5F1E7) : const Color(0xFF20262B);
  static Color get inkSoft => _dark ? const Color(0xFFAFA894) : const Color(0xFF5C6670);

  // Accents stay consistent across themes — they're bright enough to
  // read clearly on both warm-cream and warm-dark backgrounds.
  static const Color marigold = Color(0xFFFFA531);
  static const Color marigoldDeep = Color(0xFFE8890A);
  static const Color coral = Color(0xFFFF6F59);
  static const Color sage = Color(0xFF3FA06A);
  static const Color skyInk = Color(0xFF5B9BB0);
  static const Color teal = Color(0xFF20B2A6);
  static const Color grape = Color(0xFF8C6FE6);
}

class AppText {
  AppText._();

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.fraunces(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          height: 1.15,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: AppColors.inkSoft,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.spaceMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: AppColors.inkSoft,
        ),
      );
}

class AppTheme {
  AppTheme._();

  /// Rebuilt fresh every time this is read. Call it inside something
  /// that rebuilds when [isDarkNotifier] changes (see main.dart).
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: isDarkNotifier.value ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.marigold,
          primary: AppColors.marigold,
          secondary: AppColors.coral,
          surface: AppColors.paperCard,
          brightness: isDarkNotifier.value ? Brightness.dark : Brightness.light,
        ),
        textTheme: AppText.textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.paper,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: AppText.textTheme.titleMedium,
          iconTheme: IconThemeData(color: AppColors.ink),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.paperCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.rule),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.marigold, width: 1.6),
          ),
        ),
      );
}
