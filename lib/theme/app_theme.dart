import 'package:flutter/material.dart';

class AppTheme {
  // Ana renkler
  static const Color primaryDark = Color(0xFF000000);    // Saf siyah arka plan
  static const Color surfaceDark = Color(0xFF1C1C1C);    // Biraz daha açık siyah
  static const Color accentColor = Color(0xFFBFE429);    // Lime yeşili accent
  
  // Metin renkleri
  static const Color textPrimary = Color(0xFFFFFFFF);    // Beyaz
  static const Color textSecondary = Color(0xFF9E9E9E);  // Gri

  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: primaryDark,
    brightness: Brightness.dark,
    primaryColor: accentColor,
    colorScheme: const ColorScheme.dark(
      primary: accentColor,
      surface: surfaceDark,
      background: primaryDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryDark,
      selectedItemColor: accentColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  // Custom Input Decoration
  static InputDecoration searchInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: Colors.grey[400])
          : null,
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }
} 