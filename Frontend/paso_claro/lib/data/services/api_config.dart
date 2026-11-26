/// Environment-driven backend configuration (never hardcode secrets or tokens).
/// Pass at runtime/build time without a trailing slash:
///   flutter run --dart-define=API_BASE_URL=https://tu-servicio.onrender.com
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
abstract final class ApiConfig {
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pasoclaro.onrender.com',
  );

  static String get baseUrl {
    final trimmed = _rawBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool get isBackendConfigured => baseUrl.isNotEmpty;
}
