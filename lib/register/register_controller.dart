import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../domain/entities/register_data.dart';
import '../domain/entities/user.dart';
import '../domain/failures/register_failure.dart';
import 'register_api.dart';
import 'register_validator.dart';

enum RegisterStatus {
  idle,
  submitting,
  registered,
  failure,
}

/// S — Single Responsibility: solo orquesta el caso de uso de registro.
class RegisterController extends ChangeNotifier {
  RegisterController({
    required this.validator,
    required this.api,
  });

  final RegisterValidator validator;
  final RegisterApi api;

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

  Future<bool> register(RegisterData data) async {
    status = RegisterStatus.submitting;
    failure = null;
    notifyListeners();

    final validation = validator.validate(data);
    if (validation != null) {
      status = RegisterStatus.failure;
      failure = validation;
      user = null;
      notifyListeners();
      return false;
    }

    try {
      final response = await api.register(data);
      status = RegisterStatus.registered;
      user = response.toDomain();
      failure = null;
      notifyListeners();
      return true;
    } on ApiNetworkException {
      return _fail(const RegisterNetworkFailure());
    } on ApiException catch (error) {
      return _fail(api.mapFailure(error));
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
}
