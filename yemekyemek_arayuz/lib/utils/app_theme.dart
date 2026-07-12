import 'package:flutter/material.dart';

/// Kırmızı - beyaz ana renk paleti. Farklı ton ihtiyacı olduğunda
/// (arka planlar, rozetler, ikincil metinler vb.) kırmızının daha açık
/// tonları kullanılır; palet dışına çıkılmaz.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFC62828); // ana kırmızı
  static const Color primaryDark = Color(0xFF8E1B1B); // koyu kırmızı (vurgular)
  static const Color primaryLight = Color(0xFFF6C6C6); // açık kırmızı (rozet, mint yerine)
  static const Color surface = Color(0xFFFFFFFF); // beyaz zemin
  static const Color cardBackground = Colors.white;
  static const Color sectionBackground = Color(0xFFFBE4E4); // çok açık kırmızı kutular
  static const Color textPrimary = Color(0xFF2A0E0E); // kırmızıya yakın koyu ton
  static const Color textSecondary = Color(0xFF9C6B6B); // soluk kırmızı-gri
  static const Color border = Color(0xFF2A0E0E);
  static const Color error = Color(0xFFB00020);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),
    );
  }
}
