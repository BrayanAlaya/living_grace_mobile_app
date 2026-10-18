/// Contrato para persistir el token de sesión (ISP / DIP).
abstract interface class TokenStore {
  Future<void> saveAccessToken(String token, {String tokenType = 'bearer'});

  Future<String?> readAccessToken();

  Future<void> clear();
}
