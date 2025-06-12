import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF2563EB); // Blue
  static const Color secondary = Color(0xFF7C3AED); // Purple
  static const Color accent = Color(0xFF22D3EE); // Cyan

  // Status colors
  static const Color success = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Light Blue

  // Background and surface colors
  static const Color background = Color(0xFF0F172A); // Dark blue/slate
  static const Color surface = Color(0xFF1E293B); // Slightly lighter blue/slate
  static const Color cardBackground = Color(0xFF1E293B);
  static const Color inputBackground = Color(0xFF334155);
  static const Color chipBackground = Color(0xFF334155);
  static const Color tooltipBackground = Color(0xFF475569);

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);

  // Border and divider colors
  static const Color divider = Color(0xFF334155);
  static const Color border = Color(0xFF334155);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Purple
    Color(0xFF22D3EE), // Cyan
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF472B6), // Pink
    Color(0xFF64748B), // Slate
    Color(0xFF10B981), // Emerald
  ];

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}