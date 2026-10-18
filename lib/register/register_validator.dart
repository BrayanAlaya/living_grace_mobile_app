import '../domain/entities/register_data.dart';
import '../domain/failures/register_failure.dart';

/// S — Single Responsibility: solo valida el registro.
class RegisterValidator {
  static const _minPasswordLength = 8;
  static final _emailPattern = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
  static final _peruPhonePattern = RegExp(r'^9\d{8}$');

  bool isPersonalDataComplete({
    required String firstName,
    required String lastName,
    required String phone,
    required String birthDate,
    required String email,
  }) {
    return firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        _peruPhonePattern.hasMatch(phone.trim()) &&
        birthDate.trim().isNotEmpty &&
        _emailPattern.hasMatch(email.trim());
  }

  bool isCredentialsComplete({
    required String? ministryId,
    required String? serviceAreaId,
    required String password,
    required String confirmPassword,
  }) {
    return ministryId != null &&
        ministryId.isNotEmpty &&
        serviceAreaId != null &&
        serviceAreaId.isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty;
  }

  RegisterFailure? validatePersonalData({
    required String firstName,
    required String lastName,
    required String phone,
    required String birthDate,
    required String email,
  }) {
    if (firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        phone.trim().isEmpty ||
        birthDate.trim().isEmpty ||
        email.trim().isEmpty) {
      return const EmptyRegisterFieldsFailure();
    }
    if (!_emailPattern.hasMatch(email.trim())) {
      return const InvalidEmailFailure();
    }
    if (!_peruPhonePattern.hasMatch(phone.trim())) {
      return const InvalidPhoneFailure();
    }
    return null;
  }

  RegisterFailure? validateCredentials({
    required String? ministryId,
    required String? serviceAreaId,
    required String password,
    required String confirmPassword,
  }) {
    if (ministryId == null ||
        ministryId.isEmpty ||
        serviceAreaId == null ||
        serviceAreaId.isEmpty) {
      return const MissingMinistryFailure();
    }
    if (password.isEmpty || confirmPassword.isEmpty) {
      return const EmptyRegisterFieldsFailure();
    }
    if (password.length < _minPasswordLength) {
      return const WeakPasswordFailure();
    }
    if (password != confirmPassword) {
      return const PasswordMismatchFailure();
    }
    return null;
  }

  RegisterFailure? validate(RegisterData data) {
    return validatePersonalData(
          firstName: data.firstName,
          lastName: data.lastName,
          phone: data.phone,
          birthDate: data.birthDate,
          email: data.email,
        ) ??
        validateCredentials(
          ministryId: data.ministryId,
          serviceAreaId: data.serviceAreaId,
          password: data.password,
          confirmPassword: data.confirmPassword,
        );
  }
}
