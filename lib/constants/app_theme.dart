import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFFD4847A); // Mauve-Rose
  static const Color primaryLight   = Color(0xFFF2C4BB); // Light Blush
  static const Color primaryDark    = Color(0xFFB86560); // Deep Rose
  static const Color accent         = Color(0xFFCDA96E); // Golden Crown
  static const Color accentLight    = Color(0xFFE8CCA0); // Soft Gold
  static const Color goldAccent     = Color(0xFFCDA96E); // Alias for accent — use for achievement/reward moments
  static const Color goldGlow       = Color(0x33CDA96E); // 20% opacity gold for shadows/glows
  static const Color glassSurface   = Color(0xF0FFFFFF); // 94% opaque white for glassmorphism

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const Color gradientTop    = Color(0xFFE8A49C);
  static const Color gradientMid    = Color(0xFFE8B8A8);
  static const Color gradientBottom = Color(0xFFE8C89A);

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientMid, gradientBottom],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  // ── Neutrals & Surfaces ────────────────────────────────────────────────────
  static const Color textDark       = Color(0xFF2D2520);
  static const Color textMedium     = Color(0xFF6B5B55);
  static const Color textLight      = Color(0xFF9E8A84);
  static const Color textOnDark     = Color(0xFFFFF8F5);
  static const Color surface        = Color(0xFFFFF8F5);
  static const Color surfaceCard    = Color(0xFFFFFFFF);
  static const Color divider        = Color(0xFFE8D5CF);
  static const Color error          = Color(0xFFD4615A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme(),
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: textOnDark,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        secondary: accent,
        onSecondary: textOnDark,
        secondaryContainer: accentLight,
        onSecondaryContainer: textDark,
        surface: surface,
        onSurface: textDark,
        error: error,
        onError: textOnDark,
        outline: divider,
        shadow: textDark.withOpacity(0.08),
      ),
      scaffoldBackgroundColor: surface,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input / TextField ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: textMedium,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: textLight,
          fontSize: 14,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: divider, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom Nav ──────────────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        elevation: 12,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
