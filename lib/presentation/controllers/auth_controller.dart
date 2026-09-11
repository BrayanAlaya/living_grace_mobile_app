import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  idle,
  authenticating,
  authenticated,
  failure,
}

/// Controlador de presentación: orquesta el login sin conocer UI ni detalles de red.
class AuthController extends ChangeNotifier {
  AuthController({required this._authRepository});

  final AuthRepository _authRepository;

  AuthStatus status = AuthStatus.idle;
  AuthFailure? failure;
  User? user;

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    status = AuthStatus.authenticating;
    failure = null;
    notifyListeners();

    final result = await _authRepository.login(
      AuthCredentials(identifier: identifier, password: password),
    );

    if (result.failure != null) {
      status = AuthStatus.failure;
      failure = result.failure;
      user = null;
      notifyListeners();
      return false;
    }

    status = AuthStatus.authenticated;
    user = result.user;
    failure = null;
    notifyListeners();
    return true;
  }

  void clearFailure() {
    if (failure == null && status != AuthStatus.failure) return;
    failure = null;
    status = AuthStatus.idle;
    notifyListeners();
  }

  void logout() {
    _authRepository.logout();
    user = null;
    failure = null;
    status = AuthStatus.idle;
    notifyListeners();
  }
}
