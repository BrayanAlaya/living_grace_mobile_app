import '../domain/failures/auth_failure.dart';

/// S — Single Responsibility: solo valida las credenciales de login.
class LoginValidator {
  AuthFailure? validate({
    required String identifier,
    required String password,
  }) {
    if (identifier.trim().isEmpty || password.isEmpty) {
      return const EmptyCredentialsFailure();
    }
    return null;
  }
}
