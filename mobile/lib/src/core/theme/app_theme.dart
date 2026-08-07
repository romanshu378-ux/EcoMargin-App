import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color emeraldPrimary = Color(0xFF10B981);
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF131A29);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: emeraldPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldPrimary,
        brightness: Brightness.light,
        primary: emeraldPrimary,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      textTheme: GoogleFonts.outfitTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: emeraldPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldPrimary,
        brightness: Brightness.dark,
        primary: emeraldPrimary,
        background: darkBg,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
