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

  /// Misma host que [baseUrl], con esquema WebSocket.
  static String get wsBaseUrl {
    final http = baseUrl;
    if (http.startsWith('https://')) return 'wss://${http.substring(8)}';
    if (http.startsWith('http://')) return 'ws://${http.substring(7)}';
    return http;
  }

  /// Render puede tardar en despertar la primera petición.
  static const Duration timeout = Duration(seconds: 60);
}
