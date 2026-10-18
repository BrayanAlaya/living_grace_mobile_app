import '../../domain/repositories/token_store.dart';

/// Almacenamiento en memoria del access token (sustituible por SecureStorage).
class InMemoryTokenStore implements TokenStore {
  String? _accessToken;
  String _tokenType = 'bearer';

  String get tokenType => _tokenType;

  @override
  Future<void> saveAccessToken(String token, {String tokenType = 'bearer'}) async {
    _accessToken = token;
    _tokenType = tokenType;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> clear() async {
    _accessToken = null;
    _tokenType = 'bearer';
  }
}
