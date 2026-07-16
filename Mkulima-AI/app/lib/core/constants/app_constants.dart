/// App-wide constants shared across feature modules.
///
/// Keeping these centralized avoids magic numbers/strings scattered across
/// 8+ feature folders and gives us one place to update when, e.g., a new
/// supported language or crop is added.
class AppConstants {
  AppConstants._();

  static const String appName = 'Mkulima AI';

  // Spacing scale used across the design system.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radiusMd = 14;
  static const double radiusLg = 20;

  // Languages supported by the AI Voice Assistant (Section 5 of the brief).
  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage(code: 'en-UG', label: 'English'),
    SupportedLanguage(code: 'lg-UG', label: 'Luganda'),
    SupportedLanguage(code: 'nyn-UG', label: 'Runyankole'),
    SupportedLanguage(code: 'xog-UG', label: 'Lusoga'),
    SupportedLanguage(code: 'luo-UG', label: 'Luo'),
    SupportedLanguage(code: 'teo-UG', label: 'Ateso'),
  ];

  // Crops supported by disease detection (Section 2 of the brief).
  static const List<String> supportedCrops = [
    'Maize',
    'Beans',
    'Coffee',
    'Bananas',
    'Cassava',
    'Tomatoes',
  ];

  static const Duration splashMinDuration = Duration(milliseconds: 1200);
  static const Duration debounceDuration = Duration(milliseconds: 400);
}

class SupportedLanguage {
  final String code;
  final String label;
  const SupportedLanguage({required this.code, required this.label});
}
