// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightGradientTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF00E5FF),
      // Pori app mein default Comic Neue font with large size
      textTheme: GoogleFonts.comicNeueTextTheme().copyWith(
        bodyLarge: GoogleFonts.comicNeue(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.comicNeue(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.comicNeue(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }
}
