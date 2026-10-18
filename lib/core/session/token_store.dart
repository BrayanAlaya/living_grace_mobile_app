/// Guarda el token de sesión en memoria (sin persistir entre reinicios).
class TokenStore {
  String? accessToken;
  String tokenType = 'bearer';

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  String? get authorizationHeader {
    if (!hasToken) return null;
    return '${_normalizedType()} $accessToken';
  }

  void save({required String accessToken, String tokenType = 'bearer'}) {
    this.accessToken = accessToken;
    this.tokenType = tokenType;
  }

  void clear() {
    accessToken = null;
    tokenType = 'bearer';
  }

  String _normalizedType() {
    final value = tokenType.trim();
    if (value.isEmpty) return 'Bearer';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
