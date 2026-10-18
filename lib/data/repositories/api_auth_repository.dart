import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/token_store.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_remote_exceptions.dart';
import '../models/login_request_dto.dart';

/// Adaptador que implementa [AuthRepository] contra la API real.
/// No cambia el contrato de dominio; solo traduce token ↔ sesión local.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required this._remoteDataSource,
    required this._tokenStore,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStore _tokenStore;

  @override
  Future<({User? user, AuthFailure? failure})> login(
    AuthCredentials credentials,
  ) async {
    final identifier = credentials.identifier.trim();
    final password = credentials.password;

    if (identifier.isEmpty || password.isEmpty) {
      return (user: null, failure: const EmptyCredentialsFailure());
    }

    try {
      final token = await _remoteDataSource.login(
        LoginRequestDto(identifier: identifier, password: password),
      );

      await _tokenStore.saveAccessToken(
        token.accessToken,
        tokenType: token.tokenType,
      );

      return (
        user: User(
          id: identifier,
          email: identifier,
          displayName: identifier,
        ),
        failure: null,
      );
    } on AuthUnauthorizedException {
      return (user: null, failure: const InvalidCredentialsFailure());
    } on AuthValidationException {
      return (user: null, failure: const InvalidCredentialsFailure());
    } on AuthNetworkException {
      return (user: null, failure: const NetworkFailure());
    } on AuthServerException {
      return (user: null, failure: const NetworkFailure());
    }
  }

  @override
  Future<void> logout() => _tokenStore.clear();
}
