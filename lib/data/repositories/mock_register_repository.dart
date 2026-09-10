import '../../domain/entities/register_data.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/register_failure.dart';
import '../../domain/repositories/register_repository.dart';

/// Simula un servicio de registro remoto.
/// El correo `demo@livinggrace.com` ya está tomado (coincide con el del login).
class MockRegisterRepository implements RegisterRepository {
  MockRegisterRepository({
    this.delay = const Duration(milliseconds: 1800),
  });

  final Duration delay;

  static const _minPasswordLength = 6;
  static final _emailPattern = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');

  // "Base de datos" en memoria de correos ya registrados.
  final Set<String> _registeredEmails = {'demo@livinggrace.com'};

  @override
  Future<({User? user, RegisterFailure? failure})> register(
    RegisterData data,
  ) async {
    await Future<void>.delayed(delay);

    final displayName = data.displayName.trim();
    final identifier = data.identifier.trim();
    final password = data.password;
    final confirmPassword = data.confirmPassword;

    if (displayName.isEmpty ||
        identifier.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return (user: null, failure: const EmptyRegisterFieldsFailure());
    }

    if (!_emailPattern.hasMatch(identifier)) {
      return (user: null, failure: const InvalidEmailFailure());
    }

    if (password.length < _minPasswordLength) {
      return (user: null, failure: const WeakPasswordFailure());
    }

    if (password != confirmPassword) {
      return (user: null, failure: const PasswordMismatchFailure());
    }

    final normalizedEmail = identifier.toLowerCase();
    if (_registeredEmails.contains(normalizedEmail)) {
      return (user: null, failure: const EmailAlreadyRegisteredFailure());
    }

    _registeredEmails.add(normalizedEmail);

    return (
      user: User(
        id: 'usr_${_registeredEmails.length.toString().padLeft(3, '0')}',
        email: normalizedEmail,
        displayName: displayName,
      ),
      failure: null,
    );
  }
}
