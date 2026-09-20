import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/user_response.dart';
import '../domain/entities/register_data.dart';
import '../domain/entities/user.dart';
import '../domain/failures/register_failure.dart';

enum RegisterStatus {
  idle,
  submitting,
  registered,
  failure,
}

class RegisterController extends ChangeNotifier {
  RegisterController({required this.client});

  final ApiClient client;

  RegisterStatus status = RegisterStatus.idle;
  RegisterFailure? failure;
  User? user;

  bool showFailure(RegisterFailure registerFailure) {
    status = RegisterStatus.failure;
    failure = registerFailure;
    user = null;
    notifyListeners();
    return false;
  }

  RegisterFailure? validate(RegisterData data) {
    final emailOk = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$')
        .hasMatch(data.email.trim());
    final phoneOk = RegExp(r'^9\d{8}$').hasMatch(data.phone.trim());

    if (data.firstName.trim().isEmpty ||
        data.lastName.trim().isEmpty ||
        data.phone.trim().isEmpty ||
        data.birthDate.trim().isEmpty ||
        data.email.trim().isEmpty) {
      return const EmptyRegisterFieldsFailure();
    }
    if (!emailOk) return const InvalidEmailFailure();
    if (!phoneOk) return const InvalidPhoneFailure();
    if (data.ministryId.isEmpty || data.serviceAreaId.isEmpty) {
      return const MissingMinistryFailure();
    }
    if (data.password.isEmpty || data.confirmPassword.isEmpty) {
      return const EmptyRegisterFieldsFailure();
    }
    if (data.password.length < 8) return const WeakPasswordFailure();
    if (data.password != data.confirmPassword) {
      return const PasswordMismatchFailure();
    }
    return null;
  }

  Future<bool> register(RegisterData data) async {
    status = RegisterStatus.submitting;
    failure = null;
    notifyListeners();

    final validation = validate(data);
    if (validation != null) {
      return _fail(validation);
    }

    try {
      final response = await client.post(
        '/users/register',
        body: {
          'email': data.email.trim(),
          'username': 'usuario',
          'password': data.password,
          'first_name': data.firstName.trim(),
          'last_name': data.lastName.trim(),
          'phone': data.phone.trim(),
          'birth_date': data.birthDate.trim(),
        },
      );

      final decoded = client.decodeBody(response);
      if (response.statusCode == 201 && decoded is Map<String, dynamic>) {
        status = RegisterStatus.registered;
        user = UserResponse.fromJson(decoded).toDomain();
        failure = null;
        notifyListeners();
        return true;
      }

      throw ApiException(
        statusCode: response.statusCode,
        body: decoded,
        message: 'No se pudo crear la cuenta',
      );
    } on ApiNetworkException {
      return _fail(const RegisterNetworkFailure());
    } on ApiException catch (error) {
      return _fail(_mapFailure(error));
    } on FormatException {
      return _fail(const RegisterUnexpectedFailure());
    }
  }

  void clearFailure() {
    if (failure == null && status != RegisterStatus.failure) return;
    failure = null;
    status = RegisterStatus.idle;
    notifyListeners();
  }

  void reset() {
    user = null;
    failure = null;
    status = RegisterStatus.idle;
    notifyListeners();
  }

  bool _fail(RegisterFailure registerFailure) {
    status = RegisterStatus.failure;
    failure = registerFailure;
    user = null;
    notifyListeners();
    return false;
  }

  RegisterFailure _mapFailure(ApiException error) {
    final fields = <String>{};
    String? message;
    final body = error.body;
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        message = detail.trim();
      }
      if (detail is List) {
        if (detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] is String) {
            message = (first['msg'] as String).trim();
          }
        }
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
      }
    }

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
}
