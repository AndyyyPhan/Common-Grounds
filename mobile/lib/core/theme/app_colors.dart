/// Design System - Color Palette
///
/// Defines the color scheme for Common Grounds app with support for light and dark themes.
/// Based on modern social app design with a fresh, approachable feel.
library;

import 'package:flutter/material.dart';

/// App color palette following Material Design 3 principles
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ===========================
  // PRIMARY COLORS
  // ===========================

  /// Primary brand color - Fresh green representing connection and growth
  static const Color primary = Color(0xFF00A86B); // Jade green
  static const Color primaryLight = Color(0xFF4CD694);
  static const Color primaryDark = Color(0xFF007849);

  /// Secondary accent color - Warm orange for energy and friendliness
  static const Color secondary = Color(0xFFFF7043);
  static const Color secondaryLight = Color(0xFFFF9E7B);
  static const Color secondaryDark = Color(0xFFC63F17);

  // ===========================
  // NEUTRAL COLORS
  // ===========================

  /// Background colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);

  /// Surface colors (cards, sheets, etc.)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Surface variant (slightly different from surface)
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);

  // ===========================
  // TEXT COLORS
  // ===========================

  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textDisabledDark = Color(0xFF5A5A5A);

  // ===========================
  // SEMANTIC COLORS
  // ===========================

  /// Success states
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  /// Error states
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFC62828);

  /// Warning states
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  /// Info states
  static const Color info = Color(0xFF29B6F6);
  static const Color infoLight = Color(0xFF4FC3F7);
  static const Color infoDark = Color(0xFF0288D1);

  // ===========================
  // CHAT-SPECIFIC COLORS
  // ===========================

  /// Message bubbles
  static const Color messageSent = Color(0xFF00A86B); // Primary green
  static const Color messageReceived = Color(0xFFE8E8E8); // Light gray
  static const Color messageReceivedDark = Color(0xFF2A2A2A); // Dark gray

  /// Online/Active status
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);

  // ===========================
  // DIVIDER & BORDER COLORS
  // ===========================

  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF3A3A3A);

  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF3A3A3A);

  // ===========================
  // OVERLAY COLORS
  // ===========================

  /// Semi-transparent overlays for modals, dialogs
  static const Color scrimLight = Color(0x80000000); // 50% black
  static const Color scrimDark = Color(0xB3000000); // 70% black

  /// Hover, pressed states
  static const Color hoverLight = Color(0x0A000000); // 4% black
  static const Color hoverDark = Color(0x14FFFFFF); // 8% white

  static const Color pressedLight = Color(0x1F000000); // 12% black
  static const Color pressedDark = Color(0x29FFFFFF); // 16% white
}
