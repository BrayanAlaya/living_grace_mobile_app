import '../../core/network/api_exception.dart';
import '../../domain/entities/register_data.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/register_failure.dart';
import '../../domain/repositories/register_repository.dart';
import '../datasources/living_grace_api.dart';

class ApiRegisterRepository implements RegisterRepository {
  ApiRegisterRepository({required this._api});

  final LivingGraceApi _api;

  static const _minPasswordLength = 8;
  static final _emailPattern = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
  static final _peruPhonePattern = RegExp(r'^9\d{8}$');

  // username no está en el front; se envía un valor estático válido.
  static const _staticUsername = 'usuario';

  @override
  Future<({User? user, RegisterFailure? failure})> register(
    RegisterData data,
  ) async {
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

    try {
      final response = await _api.register(
        email: email,
        username: _staticUsername,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        birthDate: birthDate,
      );

      return (user: response.toDomain(), failure: null);
    } on ApiNetworkException {
      return (user: null, failure: const RegisterNetworkFailure());
    } on ApiException catch (error) {
      return (user: null, failure: _mapFailure(error));
    } on FormatException {
      return (
        user: null,
        failure: const RegisterUnexpectedFailure(),
      );
    }
  }

  RegisterFailure _mapFailure(ApiException error) {
    final fields = _validationFields(error.body);
    final message = _detailMessage(error.body);
    final normalized = (message ?? '').toLowerCase();

    if (error.statusCode == 409 ||
        normalized.contains('already') ||
        normalized.contains('registered') ||
        normalized.contains('existe')) {
      return const EmailAlreadyRegisteredFailure();
    }

    if (fields.contains('phone') || normalized.contains('phone')) {
      return const InvalidPhoneFailure();
    }

    if (fields.contains('email') || normalized.contains('email')) {
      if (normalized.contains('already') || normalized.contains('exist')) {
        return const EmailAlreadyRegisteredFailure();
      }
      return const InvalidEmailFailure();
    }

    if (fields.contains('password') &&
        (normalized.contains('least') ||
            normalized.contains('short') ||
            normalized.contains('8'))) {
      return const WeakPasswordFailure();
    }

    if (message != null && message.isNotEmpty) {
      return RegisterValidationFailure(message);
    }

    return const RegisterUnexpectedFailure();
  }

  Set<String> _validationFields(dynamic body) {
    final fields = <String>{};
    if (body is! Map<String, dynamic>) return fields;

    final detail = body['detail'];
    if (detail is! List) return fields;

    for (final item in detail) {
      if (item is! Map) continue;
      final loc = item['loc'];
      if (loc is! List) continue;
      for (final part in loc) {
        if (part is String && part != 'body') {
          fields.add(part);
        }
      }
    }
    return fields;
  }

  String? _detailMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          return (first['msg'] as String).trim();
        }
      }
    }
    return null;
  }
}
