import 'package:flutter/foundation.dart';

import '../../domain/entities/register_data.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/register_failure.dart';
import '../../domain/repositories/register_repository.dart';

enum RegisterStatus {
  idle,
  submitting,
  registered,
  failure,
}

/// Controlador de presentación: orquesta el registro sin conocer UI ni detalles de red.
class RegisterController extends ChangeNotifier {
  RegisterController({required this._registerRepository});

  final RegisterRepository _registerRepository;

  RegisterStatus status = RegisterStatus.idle;
  RegisterFailure? failure;
  User? user;

  Future<bool> register({
    required String displayName,
    required String identifier,
    required String password,
    required String confirmPassword,
  }) async {
    status = RegisterStatus.submitting;
    failure = null;
    notifyListeners();

    final result = await _registerRepository.register(
      RegisterData(
        displayName: displayName,
        identifier: identifier,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );

    if (result.failure != null) {
      status = RegisterStatus.failure;
      failure = result.failure;
      user = null;
      notifyListeners();
      return false;
    }

    status = RegisterStatus.registered;
    user = result.user;
    failure = null;
    notifyListeners();
    return true;
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
}
