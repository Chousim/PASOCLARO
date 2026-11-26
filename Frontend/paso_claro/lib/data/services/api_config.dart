/// Environment-driven backend configuration (never hardcode secrets or tokens).
/// Pass at runtime/build time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static bool get isBackendConfigured => baseUrl.trim().isNotEmpty;
}
