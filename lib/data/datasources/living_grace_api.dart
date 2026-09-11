import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/token_response.dart';
import '../models/user_response.dart';

class LivingGraceApi {
  const LivingGraceApi({required this.client});

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

  Future<UserResponse> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String birthDate,
  }) async {
    final response = await client.post(
      '/users/register',
      body: {
        'email': email,
        'username': username,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'birth_date': birthDate,
      },
    );

    final decoded = client.decodeBody(response);
    if (response.statusCode == 201 && decoded is Map<String, dynamic>) {
      return UserResponse.fromJson(decoded);
    }

    throw ApiException(
      statusCode: response.statusCode,
      body: decoded,
      message: 'No se pudo crear la cuenta',
    );
  }
}
