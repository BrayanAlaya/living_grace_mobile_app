import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/data/datasources/auth_remote_datasource.dart';
import 'package:living_grace/data/datasources/auth_remote_exceptions.dart';
import 'package:living_grace/data/models/login_request_dto.dart';
import 'package:living_grace/data/models/token_response_dto.dart';
import 'package:living_grace/data/repositories/api_auth_repository.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/domain/entities/auth_credentials.dart';
import 'package:living_grace/domain/failures/auth_failure.dart';

class _FakeAuthRemote implements AuthRemoteDataSource {
  _FakeAuthRemote(this._handler);

  final Future<TokenResponseDto> Function(LoginRequestDto request) _handler;

  @override
  Future<TokenResponseDto> login(LoginRequestDto request) => _handler(request);
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
    expect(await store.readAccessToken(), 'tok_123');
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
}
