import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/token_response.dart';

/// S — Single Responsibility: solo habla con POST /auth/login.
class LoginApi {
  const LoginApi({required this.client});

  final ApiClient client;

  Future<TokenResponse> login({
    required String identifier,
    required String password,
  }) async {
    final response = await client.post(
      '/auth/login',
      body: {
        'identifier': identifier,
        'password': password,
      },
    );

    final decoded = client.decodeBody(response);
    if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
      return TokenResponse.fromJson(decoded);
    }

    throw ApiException(
      statusCode: response.statusCode,
      body: decoded,
      message: 'No se pudo iniciar sesión',
    );
  }
}
