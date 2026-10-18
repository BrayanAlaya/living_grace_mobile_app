import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/user_response.dart';
import '../domain/entities/register_data.dart';
import '../domain/failures/register_failure.dart';

/// S — Single Responsibility: solo habla con POST /users/register.
class RegisterApi {
  const RegisterApi({required this.client});

  final ApiClient client;

  static const _staticUsername = 'usuario';

  Future<UserResponse> register(RegisterData data) async {
    final response = await client.post(
      '/users/register',
      body: {
        'email': data.email.trim(),
        'username': _staticUsername,
        'password': data.password,
        'first_name': data.firstName.trim(),
        'last_name': data.lastName.trim(),
        'phone': data.phone.trim(),
        'birth_date': data.birthDate.trim(),
      },
    );

    final decoded = client.decodeBody(response);
    if (response.statusCode == 201 && decoded is Map<String, dynamic>) {
      return UserResponse.fromJson(decoded);
    }

    throw ApiException(
      statusCode: response.statusCode,
      body: decoded,
      message: 'No se pudo crear la cuenta',
    );
  }

  RegisterFailure mapFailure(ApiException error) {
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
