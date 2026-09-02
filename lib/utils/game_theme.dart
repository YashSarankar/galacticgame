import 'package:flutter/material.dart';

/// Cyberpunk & Cosmic Neon Game Theme Palette and Styles
class GameTheme {
  // Primary Palette
  static const Color backgroundVoid = Color(0xFF070913);
  static const Color backgroundSurface = Color(0xFF0F172A);
  static const Color backgroundGlass = Color(0xCC131E36);
  static const Color cardSurface = Color(0xFF1E293B);
  static const Color cardBorder = Color(0xFF334155);

  // Neon Glow Accents
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonMagenta = Color(0xFFFF007F);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonGold = Color(0xFFFFB703);
  static const Color neonAmber = Color(0xFFFB8500);
  static const Color neonGreen = Color(0xFF06D6A0);
  static const Color neonEmerald = Color(0xFF10B981);
  static const Color neonCrimson = Color(0xFFFF3366);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textGlowCyan = Color(0xFFE0FCFF);

  /// Standard neon box shadow generator
  static List<BoxShadow> neonGlow(Color color, {double blur = 12, double spread = 1}) {
    return [
      BoxShadow(
        color: color.withAlpha((0.55 * 255).round()),
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: color.withAlpha((0.25 * 255).round()),
        blurRadius: blur * 2,
        spreadRadius: spread * 1.5,
      ),
    ];
  }

  /// Glassmorphic container decoration
  static BoxDecoration glassCard({
    Color? borderColor,
    Color? backgroundColor,
    double radius = 16,
    bool glow = false,
  }) {
    final borderCol = borderColor ?? neonCyan.withAlpha((0.35 * 255).round());
    return BoxDecoration(
      color: backgroundColor ?? backgroundGlass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderCol, width: 1.5),
      boxShadow: glow ? neonGlow(borderCol, blur: 8) : [
        BoxShadow(
          color: Colors.black.withAlpha((0.45 * 255).round()),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  /// Tier color generator based on ship tier
  static Color getTierColor(int tier) {
    const colors = [
      neonCyan,
      neonGreen,
      neonGold,
      neonCrimson,
      neonPurple,
      neonMagenta,
      neonAmber,
      neonEmerald,
      Color(0xFF38BDF8),
      Color(0xFFF43F5E),
      Color(0xFFA855F7),
      Color(0xFFEAB308),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF84CC16),
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
      Color(0xFFF97316),
      Color(0xFFA855F7),
      Color(0xFFFF0055),
    ];
    return colors[(tier - 1) % colors.length];
  }
}
