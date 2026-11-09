import 'package:flutter/material.dart';

class AppColors {
  // Theme colors from CampusConnect specification
  static const Color deepNavy = Color(0xFF0B2D5B);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color teal = Color(0xFF06B6D4);
  static const Color lightAqua = Color(0xFFE0F2FE);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1E293B);
  static const Color grayText = Color(0xFF64748B);
  static const Color lightGray = Color(0xFFE2E8F0);

  // Status Colors
  static const Color statusOpen = Color(0xFF22C55E);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusClosed = Color(0xFFEF4444);

  // Backwards compatibility aliases
  static const Color primary = primaryBlue;
  static const Color primaryDark = deepNavy;
  static const Color surface = background;
  static const Color textPrimary = darkText;
  static const Color textSecondary = grayText;
  static const Color success = statusOpen;
  static const Color warning = statusPending;
  static const Color error = statusClosed;
}
