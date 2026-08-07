import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF020617),
    primaryColor: const Color(0xFFF97316),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF97316),
      secondary: Color(0xFFEA580C),
      surface: Color(0xFF0F172A),
      background: Color(0xFF020617),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: true,
    ),
  );
}
