import '../models/login_request_dto.dart';
import '../models/token_response_dto.dart';

/// Fuente remota de autenticación (DIP: el repositorio no conoce HTTP).
abstract interface class AuthRemoteDataSource {
  Future<TokenResponseDto> login(LoginRequestDto request);

  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  });

  Future<String> resetPassword({
    required String accessToken,
    required int userId,
  });
}
