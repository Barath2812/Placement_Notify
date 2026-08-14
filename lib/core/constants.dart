import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppColors {
  // Brand color guidelines
  static const Color primary = Color(0xFF1E3A8A); // Deep Blue
  static const Color accent = Color(0xFF2563EB);  // Bright Blue
  static const Color background = Color(0xFFF8FAFC); // Slate White
  static const Color cardBackground = Colors.white;
  
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  
  // Category specific colors
  static const Map<String, Color> categoryColors = {
    'Exam': Color(0xFFEF4444),       // Red
    'Placement': Color(0xFF10B981),  // Emerald
    'Fee': Color(0xFFF59E0B),        // Amber
    'Event': Color(0xFF8B5CF6),      // Purple
    'Holiday': Color(0xFFEC4899),    // Pink
    'Academic': Color(0xFF3B82F6),   // Blue
  };
}

class AppTheme {
  static const double cardRadius = 16.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ApiConfig {
  static const String baseUrl = 'https://placement-notify.onrender.com';
  
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get noticesEndpoint => '$baseUrl/notices';
  static String get fcmTokenEndpoint => '$baseUrl/users/token';
  static String get bookmarksEndpoint => '$baseUrl/bookmarks';
}
