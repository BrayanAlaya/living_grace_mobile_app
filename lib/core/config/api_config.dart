import 'package:flutter/foundation.dart';

/// Configuración de la API. Sobrescribe con:
/// `flutter run --dart-define=API_BASE_URL=https://tu-api.com`
abstract final class ApiConfig {
  static const String _fromEnvironment = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnvironment.isNotEmpty) {
      return _fromEnvironment.replaceAll(RegExp(r'/$'), '');
    }

    // Emulador Android: el host de la máquina es 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static const Duration timeout = Duration(seconds: 20);
}
