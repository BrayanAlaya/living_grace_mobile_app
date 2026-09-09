import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Simula un servicio de login remoto.
/// Credenciales válidas: `demo@livinggrace.com` / `grace123`
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    this.delay = const Duration(milliseconds: 1800),
  });

  final Duration delay;

  static const _validEmail = 'demo@livinggrace.com';
  static const _validPassword = 'grace123';

  @override
  Future<({User? user, AuthFailure? failure})> login(
    AuthCredentials credentials,
  ) async {
    await Future<void>.delayed(delay);

    final identifier = credentials.identifier.trim();
    final password = credentials.password;

    if (identifier.isEmpty || password.isEmpty) {
      return (user: null, failure: const EmptyCredentialsFailure());
    }

    final matches = identifier.toLowerCase() == _validEmail &&
        password == _validPassword;

    if (!matches) {
      return (user: null, failure: const InvalidCredentialsFailure());
    }

    return (
      user: User(
        id: 'usr_001',
        email: _validEmail,
        displayName: 'Living Grace',
      ),
      failure: null,
    );
  }
}
