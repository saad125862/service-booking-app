/// Build-time configuration.
///
/// Override the API with `--dart-define=API_BASE_URL=...`, for example:
/// - Android emulator + local Docker API: `http://10.0.2.2:3000/api/v1`
/// - Browser / desktop + local Docker API: `http://localhost:3000/api/v1`
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://seba-api-0062.onrender.com/api/v1',
  );

  static const String appName = 'Seba';
  static const String demoEmail = 'demo@example.com';
  static const String demoPassword = 'Demo@1234';
}
