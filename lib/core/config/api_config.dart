/// Configuración de la API. Sobrescribe con:
/// `flutter run --dart-define=API_BASE_URL=https://tu-api.com`
abstract final class ApiConfig {
  static const String _fromEnvironment = String.fromEnvironment('API_BASE_URL');

  static const String _defaultBaseUrl = 'https://living-grace-back.onrender.com';

  static String get baseUrl {
    final raw =
        _fromEnvironment.isNotEmpty ? _fromEnvironment : _defaultBaseUrl;
    return raw.replaceAll(RegExp(r'/$'), '');
  }

  /// Render puede tardar en despertar la primera petición.
  static const Duration timeout = Duration(seconds: 60);
}
