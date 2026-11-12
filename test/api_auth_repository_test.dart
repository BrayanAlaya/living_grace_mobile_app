import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/data/datasources/auth_remote_datasource.dart';
import 'package:living_grace/data/datasources/auth_remote_exceptions.dart';
import 'package:living_grace/data/models/login_request_dto.dart';
import 'package:living_grace/data/models/token_response_dto.dart';
import 'package:living_grace/data/repositories/api_auth_repository.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/domain/entities/auth_credentials.dart';
import 'package:living_grace/domain/entities/user_role.dart';
import 'package:living_grace/domain/failures/auth_failure.dart';

class _FakeAuthRemote implements AuthRemoteDataSource {
  _FakeAuthRemote(this._handler);

  final Future<TokenResponseDto> Function(LoginRequestDto request) _handler;

  @override
  Future<TokenResponseDto> login(LoginRequestDto request) => _handler(request);

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<String> resetPassword({
    required String accessToken,
    required int userId,
  }) async => 'temp-pass';
}

void main() {
  test('login exitoso guarda token y devuelve usuario', () async {
    final store = InMemoryTokenStore();
    final repository = ApiAuthRepository(
      remoteDataSource: _FakeAuthRemote(
        (_) async => const TokenResponseDto(accessToken: 'tok_123'),
      ),
      tokenStore: store,
    );

    final result = await repository.login(
      const AuthCredentials(
        identifier: 'demo@livinggrace.com',
        password: 'secret123',
      ),
    );

    expect(result.failure, isNull);
    expect(result.user?.email, 'demo@livinggrace.com');
    expect(result.user?.role, UserRole.user);
    expect(await store.readAccessToken(), 'tok_123');
  });

  test('idRol 2 deja la sesión como usuario', () async {
    final repository = ApiAuthRepository(
      remoteDataSource: _FakeAuthRemote(
        (_) async => const TokenResponseDto(
          accessToken: 'tok_user',
          role: UserRole.user,
        ),
      ),
      tokenStore: InMemoryTokenStore(),
    );

    final result = await repository.login(
      const AuthCredentials(identifier: 'ana', password: 'secret123'),
    );

    expect(result.failure, isNull);
    expect(result.user?.role, UserRole.user);
  });

  test('credenciales inválidas mapean a InvalidCredentialsFailure', () async {
    final repository = ApiAuthRepository(
      remoteDataSource: _FakeAuthRemote(
        (_) async => throw const AuthUnauthorizedException(),
      ),
      tokenStore: InMemoryTokenStore(),
    );

    final result = await repository.login(
      const AuthCredentials(identifier: 'x', password: 'y'),
    );

    expect(result.user, isNull);
    expect(result.failure, isA<InvalidCredentialsFailure>());
  });

  test('error de red mapea a NetworkFailure', () async {
    final repository = ApiAuthRepository(
      remoteDataSource: _FakeAuthRemote(
        (_) async => throw const AuthNetworkException(),
      ),
      tokenStore: InMemoryTokenStore(),
    );

    final result = await repository.login(
      const AuthCredentials(identifier: 'x', password: 'y'),
    );

    expect(result.failure, isA<NetworkFailure>());
  });

  test('422 de validación conserva el mensaje del servidor', () async {
    final repository = ApiAuthRepository(
      remoteDataSource: _FakeAuthRemote(
        (_) async => throw const AuthValidationException(
          'String should have at most 128 characters',
        ),
      ),
      tokenStore: InMemoryTokenStore(),
    );

    final result = await repository.login(
      const AuthCredentials(identifier: 'demo', password: 'secret'),
    );

    expect(result.user, isNull);
    expect(result.failure, isA<AuthUnexpectedFailure>());
    expect(
      result.failure?.message,
      'String should have at most 128 characters',
    );
  });

  test('resetPassword usa el user_id y devuelve la clave temporal', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('tok');
    var requestedId = 0;
    final repository = ApiAuthRepository(
      remoteDataSource: _ResetRemote((userId) {
        requestedId = userId;
        return 'Temp#1234';
      }),
      tokenStore: store,
    );

    final result = await repository.resetPassword(4);
    expect(requestedId, 4);
    expect(result.failure, isNull);
    expect(result.temporaryPassword, 'Temp#1234');
  });
}

class _ResetRemote implements AuthRemoteDataSource {
  _ResetRemote(this._reset);

  final String Function(int userId) _reset;

  @override
  Future<TokenResponseDto> login(LoginRequestDto request) async {
    return const TokenResponseDto(accessToken: 'tok');
  }

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<String> resetPassword({
    required String accessToken,
    required int userId,
  }) async {
    return _reset(userId);
  }
}
