import 'package:flutter/material.dart';
class AppColors {
  // Primary — baseado na logo LavaMax
  static const Color primary = Color(0xFF1A1A1A);       // fundo escuro da logo
  static const Color primaryDark = Color(0xFF0D0D0D);
  static const Color primaryLight = Color(0xFF2E2E2E);
  // Accent — verde-limão da logo
  static const Color accent = Color(0xFFAECC2E);
  static const Color accentDark = Color(0xFF6EA820);
  static const Color accentLight = Color(0xFFCCE05A);
  // Secondary (mantido para compatibilidade)
  static const Color secondary = Color(0xFFAECC2E);
  static const Color secondaryDark = Color(0xFF6EA820);
  static const Color secondaryLight = Color(0xFFCCE05A);
  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  // Status
  static const Color success = Color(0xFF6EA820);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFFAECC2E);
  // Transparency
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color blackWithOpacity(double opacity) =>
      black.withValues(alpha: opacity);
  static Color whiteWithOpacity(double opacity) =>
      white.withValues(alpha: opacity);
  static Color accentWithOpacity(double opacity) =>
      accent.withValues(alpha: opacity);
}
