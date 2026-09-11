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
  static final _peruPhonePattern = RegExp(r'^9\d{8}$');

  // "Base de datos" en memoria de correos ya registrados.
  final Set<String> _registeredEmails = {'demo@livinggrace.com'};

  @override
  Future<({User? user, RegisterFailure? failure})> register(
    RegisterData data,
  ) async {
    await Future<void>.delayed(delay);

    final firstName = data.firstName.trim();
    final lastName = data.lastName.trim();
    final phone = data.phone.trim();
    final birthDate = data.birthDate.trim();
    final email = data.email.trim();
    final password = data.password;
    final confirmPassword = data.confirmPassword;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        birthDate.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return (user: null, failure: const EmptyRegisterFieldsFailure());
    }

    if (!_emailPattern.hasMatch(email)) {
      return (user: null, failure: const InvalidEmailFailure());
    }

    if (!_peruPhonePattern.hasMatch(phone)) {
      return (user: null, failure: const InvalidPhoneFailure());
    }

    if (password.length < _minPasswordLength) {
      return (user: null, failure: const WeakPasswordFailure());
    }

    if (password != confirmPassword) {
      return (user: null, failure: const PasswordMismatchFailure());
    }

    final normalizedEmail = email.toLowerCase();
    if (_registeredEmails.contains(normalizedEmail)) {
      return (user: null, failure: const EmailAlreadyRegisteredFailure());
    }

    _registeredEmails.add(normalizedEmail);

    return (
      user: User(
        id: 'usr_${_registeredEmails.length.toString().padLeft(3, '0')}',
        email: normalizedEmail,
        displayName: '$firstName $lastName'.trim(),
      ),
      failure: null,
    );
  }
}
