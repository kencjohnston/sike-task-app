import 'package:flutter/material.dart';

/// Centralized color definitions for the Sike app.
/// To rebrand the app, update colors HERE ONLY.
class AppColors {
  // === Brand Colors ===
  static const Color brandPrimary = Color(0xFF275790); // Navy blue
  static const Color brandSecondary = Color(0xFF57AF62); // Green

  // === Dark Mode Brand Variants ===
  static const Color brandPrimaryDark = Color(0xFF1E4570);
  static const Color brandSecondaryDark = Color(0xFF3D8B4A);

  // === Semantic Colors ===
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF275790); // Uses brand primary

  // === Priority Colors ===
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityHigh = Color(0xFFF44336);

  // === Due Date Status Colors ===
  static const Color statusNone = Color(0xFF9E9E9E);
  static const Color statusOverdue = Color(0xFFF44336);
  static const Color statusDueToday = Color(0xFFFF9800);
  static const Color statusUpcoming = Color(0xFF275790); // Brand primary
  static const Color statusFuture = Color(0xFFBDBDBD);

  // === Recurring Task/Streak Colors ===
  static const Color streakActive = Color(0xFFFF5722);
  static const Color streakRecord = Color(0xFFFFC107);

  // === Energy Level Colors ===
  static const Color energyHigh = Color(0xFFF44336);
  static const Color energyMedium = Color(0xFFFF9800);
  static const Color energyLow = Color(0xFF4CAF50);

  // === Helper: Light ColorScheme ===
  static ColorScheme lightColorScheme() => ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        secondary: brandSecondary,
        brightness: Brightness.light,
      );

  // === Helper: Dark ColorScheme ===
  static ColorScheme darkColorScheme() => ColorScheme.fromSeed(
        seedColor: brandPrimaryDark,
        primary: brandPrimaryDark,
        secondary: brandSecondaryDark,
        brightness: Brightness.dark,
      );

  // === Helper: Get priority color ===
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return priorityHigh;
      case 1:
        return priorityMedium;
      case 0:
      default:
        return priorityLow;
    }
  }
}
