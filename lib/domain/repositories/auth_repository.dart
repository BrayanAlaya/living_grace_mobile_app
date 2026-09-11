import '../entities/auth_credentials.dart';
import '../entities/user.dart';
import '../failures/auth_failure.dart';

/// Contrato de autenticación (Dependency Inversion).
abstract interface class AuthRepository {
  Future<({User? user, AuthFailure? failure})> login(AuthCredentials credentials);

  void logout();
}
