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
  // Demo accounts for reviewers (seeded by the backend); used by the quick sign-in buttons.
  static const String demoCustomerEmail = 'demo@example.com';
  static const String demoCustomerPassword = 'Demo@1234';
  static const String demoAdminEmail = 'admin@example.com';
  static const String demoAdminPassword = 'Admin@1234';
}
