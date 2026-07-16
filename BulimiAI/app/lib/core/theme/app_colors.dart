import 'package:flutter/material.dart';

/// Mkulima AI brand palette.
///
/// - Green  → growth, crop health, positive actions
/// - Blue   → technology, weather, trust
/// - Brown  → soil, groundedness, farm-management contexts
/// - White  → simplicity, breathing room for low-literacy / low-end-device UX
class AppColors {
  AppColors._();

  // Primary — growth green
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);

  // Secondary — weather/tech blue
  static const Color secondary = Color(0xFF0277BD);
  static const Color secondaryLight = Color(0xFF58A5F0);
  static const Color secondaryDark = Color(0xFF004C8C);

  // Tertiary — soil brown
  static const Color tertiary = Color(0xFF6D4C41);
  static const Color tertiaryLight = Color(0xFF9C786C);
  static const Color tertiaryDark = Color(0xFF40241A);

  // Neutrals
  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF1F1EC);

  static const Color textPrimary = Color(0xFF1B1B18);
  static const Color textSecondary = Color(0xFF5F5F58);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic / status
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF0277BD);

  // Weather-alert specific (used in banners/notifications)
  static const Color droughtAlert = Color(0xFFEF6C00);
  static const Color floodAlert = Color(0xFF01579B);

  // Disease-detection confidence gradient
  static const Color diseaseHighConfidence = Color(0xFFC62828);
  static const Color diseaseMedConfidence = Color(0xFFF9A825);
  static const Color diseaseLowConfidence = Color(0xFF2E7D32);
}
