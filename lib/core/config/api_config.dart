/// URL base de Living Grace API.
///
/// Se puede sobrescribir en runtime:
/// `flutter run --dart-define=API_BASE_URL=https://otro-host`
abstract final class ApiConfig {
  static const _fromEnvironment = String.fromEnvironment('API_BASE_URL');
  static const _defaultBaseUrl = 'https://living-grace-back.onrender.com';

  static String get baseUrl {
    final configured = _fromEnvironment.trim();
    if (configured.isNotEmpty) {
      return _withoutTrailingSlash(configured);
    }
    return _defaultBaseUrl;
  }

  static String _withoutTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
