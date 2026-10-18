import '../models/login_request_dto.dart';
import '../models/token_response_dto.dart';

/// Fuente remota de autenticación (DIP: el repositorio no conoce HTTP).
abstract interface class AuthRemoteDataSource {
  Future<TokenResponseDto> login(LoginRequestDto request);
}
