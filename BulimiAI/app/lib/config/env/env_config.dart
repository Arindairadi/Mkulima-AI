/// Centralized environment configuration.
///
/// Values are injected at build time via `--dart-define`, e.g.:
///
/// flutter run --dart-define=ENV=dev \
///   --dart-define=API_BASE_URL=https://dev-api.mkulima.ai \
///   --dart-define=WEATHER_API_KEY=xxxx
///
/// This keeps secrets out of source control and lets the same codebase
/// target dev / staging / production without code changes.
enum AppEnv { dev, staging, prod }

class EnvConfig {
  EnvConfig._();

  static const String _envName = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static AppEnv get env {
    switch (_envName) {
      case 'prod':
        return AppEnv.prod;
      case 'staging':
        return AppEnv.staging;
      default:
        return AppEnv.dev;
    }
  }

  static bool get isProd => env == AppEnv.prod;
  static bool get isDev => env == AppEnv.dev;

  /// Base URL for the Mkulima AI backend (FastAPI service — see
  /// `bulimi_ai_backend/`). Defaults to localhost for emulator dev; override
  /// with --dart-define=API_BASE_URL=https://your-deployed-url.onrender.com
  /// once deployed, since a real phone cannot reach your computer's
  /// localhost.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // 10.0.2.2 = host machine, from an Android emulator
  );

  /// Timeout applied to all outgoing requests.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Third-party keys — never hardcode real values here; always inject
  /// via --dart-define or a secrets manager in CI.
  static const String weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const bool enableLogging = !bool.fromEnvironment(
    'dart.vm.product', // true in release builds
  );
}
