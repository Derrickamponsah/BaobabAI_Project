import 'package:flutter/material.dart';

/// Baobab visual identity
class AppTheme {
  static const Color primary = Color(0xFF5D4037); // Deep brown text/headers
  static const Color secondary = Color(0xFF8D6E63);
  static const Color accent = Color(0xFFD84315); // Warm sunset orange
  static const Color danger = Color(0xFFE74C3C); // Red for "NOT SUITABLE"
  static const Color success = Color(0xFF2EBD85); // Green for "SUITABLE"
  static const Color bg = Color(0xFFF5EFE6); // Warm, light earthy/sandy background
  static const Color card = Color(0xFFFDFBF7); // Very light warm tint for cards
  static const Color textDark = Color(0xFF3E2723); // Dark earthy brown
  static const Color textLight = Color(0xFF795548); // Medium brown

  // Chart and category colors
  static const Color catFood = Color(0xFFF27A7A);
  static const Color catBeverage = Color(0xFF699BF7);
  static const Color catMedicine = Color(0xFF5DD39E);
  static const Color catAgronomic = Color(0xFFF5B041);

  // Gradient for buttons and progress bars
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8E44AD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0xFFE9ECEF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD7CCC8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD7CCC8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
      ),
    );
  }
}
