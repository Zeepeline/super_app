import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette - Obsidian Rhythm
  static const Color kPrimaryColor = Color(0xFF72FE8F);
  static const Color kPrimaryContainerColor = Color(0xFF1CB853);
  static const Color kBackgroundColor = Color(0xFF0E0E0E);
  static const Color kSurfaceColor = Color(0xFF0E0E0E);
  static const Color kSurfaceContainerLowColor = Color(0xFF131313);
  static const Color kSurfaceContainerColor = Color(0xFF1A1A1A);
  static const Color kSurfaceContainerHighestColor = Color(0xFF262626);
  static const Color kOnBackgroundColor = Color(0xFFFFFFFF);
  static const Color kOnSurfaceVariantColor = Color(0xFFADAAAA);
  static const Color kOnPrimaryContainerColor = Color(0xFF002A0C);
  static const Color kOutlineVariantColor = Color(0xFF484847);
  static const Color kSurfaceContainerHighColor = Color(0xFF20201F);

  static TextStyle get curatedStyle => GoogleFonts.laBelleAurore(
    color: kPrimaryColor,
    fontSize: 80,
    height: 1.0,
    shadows: [
      Shadow(color: kPrimaryColor.withOpacity(0.4), blurRadius: 20),
      Shadow(color: kPrimaryColor.withOpacity(0.2), blurRadius: 40),
    ],
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackgroundColor,
    primaryColor: kPrimaryColor,
    colorScheme: const ColorScheme.dark(
      primary: kPrimaryColor,
      onPrimary: Color(0xFF005F26),
      secondary: Color(0xFF7CFBB5),
      onSecondary: Color(0xFF005E39),
      surface: kSurfaceColor,
      onSurface: kOnBackgroundColor,
      surfaceContainerHighest: kSurfaceContainerHighestColor,
      onSurfaceVariant: kOnSurfaceVariantColor,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: kOnBackgroundColor,
        letterSpacing: -0.64, // -2% of 32
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: kOnBackgroundColor,
        letterSpacing: -0.56,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: kOnBackgroundColor,
        letterSpacing: -0.48,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: kOnBackgroundColor),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: kOnSurfaceVariantColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        color: kOnSurfaceVariantColor,
        letterSpacing: 0.55, // 5% for technical labels
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: kOnSurfaceVariantColor,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
