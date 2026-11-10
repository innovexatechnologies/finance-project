import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Palette (#0B2D5B, #2563EB, #06B6D4, #E0F2FE, #F8FAFC)
  static const Color deepNavy = Color(0xFF0B2D5B);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color teal = Color(0xFF06B6D4);
  static const Color lightAqua = Color(0xFFE0F2FE);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF0F172A);
  static const Color grayText = Color(0xFF64748B);
  static const Color lightGray = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Status Colors
  static const Color statusOpen = Color(0xFF16A34A);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusClosed = Color(0xFFEF4444);

  // Company Palette Aliases & Extensions
  static const Color darkNavy = deepNavy;
  static const Color accentTeal = teal;
  static const Color indigoAccent = Color(0xFF4F46E5);
  static const Color lightIceBlue = lightAqua;
  static const Color cardSurface = cardWhite;
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = lightGray;

  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = primaryBlue;
  static const Color infoBg = lightAqua;

  // General Aliases
  static const Color primary = primaryBlue;
  static const Color primaryDark = deepNavy;
  static const Color surface = cardWhite;
  static const Color textPrimary = darkText;
  static const Color textSecondary = grayText;
  static const Color success = statusOpen;
  static const Color warning = statusPending;
  static const Color error = statusClosed;

  static LinearGradient get brandGradient => const LinearGradient(
        colors: [deepNavy, primaryBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => const LinearGradient(
        colors: [primaryBlue, teal],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: deepNavy.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
