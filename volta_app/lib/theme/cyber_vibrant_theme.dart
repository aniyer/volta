import 'package:flutter/material.dart';

/// VOLTA "Cyber-Vibrant" Theme - 2026 Edition
/// 
/// Dark Mode base with neon accent colors for a gaming aesthetic
class CyberVibrantTheme {
  // Base Colors
  static const Color darkBase = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);
  
  // Neon Accents
  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color electricTeal = Color(0xFF2DD4BF);
  static const Color magmaOrange = Color(0xFFF43F5E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  
  // Opacity variants for shadows
  static Color neonVioletShadow = const Color(0x4D8B5CF6); // 30% opacity
  static Color neonVioletGlow = const Color(0x808B5CF6); // 50% opacity
  static Color electricTealShadow = const Color(0x662DD4BF); // 40% opacity
  
  /// Helper function to create color with opacity (Flutter 3.38+ compatible)
  static Color withAlpha(Color color, double opacity) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return Color.fromRGBO(r, g, b, opacity);
  }
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonViolet, Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient spinButtonGradient = LinearGradient(
    colors: [magmaOrange, Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [electricTeal, Color(0xFF5EEAD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Main theme data
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBase,
    
    // Color scheme
    colorScheme: const ColorScheme.dark(
      primary: neonViolet,
      secondary: electricTeal,
      tertiary: magmaOrange,
      surface: darkSurface,
      error: magmaOrange,
      onPrimary: textPrimary,
      onSecondary: darkBase,
      onSurface: textPrimary,
    ),
    
    // App Bar
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBase,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: textPrimary,
      ),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 8,
      shadowColor: neonVioletShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Elevated Buttons (Primary Actions)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonViolet,
        foregroundColor: textPrimary,
        elevation: 8,
        shadowColor: neonVioletGlow,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    ),
    
    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: electricTeal,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: magmaOrange,
      foregroundColor: textPrimary,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonViolet, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textMuted),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: neonViolet,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 16,
    ),
    
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCard,
      contentTextStyle: const TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: electricTeal,
      linearTrackColor: darkCard,
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: textPrimary,
      ),
    ),
  );
  
  /// Box decoration for glowing cards
  static BoxDecoration glowingCard({Color? glowColor}) {
    final color = glowColor ?? neonViolet;
    return BoxDecoration(
      color: darkCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: withAlpha(color, 0.3),
          blurRadius: 20,
          spreadRadius: -5,
        ),
      ],
    );
  }
  
  /// Neon text style
  static TextStyle neonText({
    Color? color,
    double fontSize = 24,
  }) {
    final c = color ?? neonViolet;
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: c,
      shadows: [
        Shadow(
          color: withAlpha(c, 0.8),
          blurRadius: 20,
        ),
        Shadow(
          color: withAlpha(c, 0.5),
          blurRadius: 40,
        ),
      ],
    );
  }
}
