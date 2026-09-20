import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/session/token_store.dart';
import '../domain/entities/user.dart';
import '../domain/failures/auth_failure.dart';
import 'login_api.dart';
import 'login_user_mapper.dart';
import 'login_validator.dart';

enum LoginStatus {
  idle,
  authenticating,
  authenticated,
  failure,
}

/// S — Single Responsibility: solo orquesta el caso de uso de login.
///
/// No pinta UI, no arma el HTTP y no define reglas de validación.
/// Usa clases concretas (no interfaces) a propósito: este flujo enseña
/// solo el principio S, no D.
class LoginController extends ChangeNotifier {
  LoginController({
    required this.validator,
    required this.api,
    required this.mapper,
    required this.tokenStore,
  });

  final LoginValidator validator;
  final LoginApi api;
  final LoginUserMapper mapper;
  final TokenStore tokenStore;

  LoginStatus status = LoginStatus.idle;
  AuthFailure? failure;
  User? user;

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    status = LoginStatus.authenticating;
    failure = null;
    notifyListeners();

    final validation = validator.validate(
      identifier: identifier,
      password: password,
    );
    if (validation != null) {
      status = LoginStatus.failure;
      failure = validation;
      user = null;
      notifyListeners();
      return false;
    }

    try {
      final token = await api.login(
        identifier: identifier.trim(),
        password: password,
      );
      tokenStore.save(
        accessToken: token.accessToken,
        tokenType: token.tokenType,
      );
      user = mapper.fromLogin(
        identifier: identifier.trim(),
        accessToken: token.accessToken,
      );
      status = LoginStatus.authenticated;
      failure = null;
      notifyListeners();
      return true;
    } on ApiNetworkException {
      return _fail(const NetworkFailure());
    } on ApiException catch (error) {
      return _fail(_mapApiFailure(error));
    } on FormatException {
      return _fail(const AuthUnexpectedFailure());
    }
  }

  void clearFailure() {
    if (failure == null && status != LoginStatus.failure) return;
    failure = null;
    status = LoginStatus.idle;
    notifyListeners();
  }

  void logout() {
    tokenStore.clear();
    user = null;
    failure = null;
    status = LoginStatus.idle;
    notifyListeners();
  }

  bool _fail(AuthFailure authFailure) {
    status = LoginStatus.failure;
    failure = authFailure;
    user = null;
    notifyListeners();
    return false;
  }

  AuthFailure _mapApiFailure(ApiException error) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const InvalidCredentialsFailure();
    }

    final message = _detailMessage(error.body);
    if (error.statusCode == 422) {
      final normalized = (message ?? '').toLowerCase();
      if (normalized.contains('credential') ||
          normalized.contains('password') ||
          normalized.contains('identifier')) {
        return const InvalidCredentialsFailure();
      }
    }

    if (message != null && message.isNotEmpty) {
      return AuthUnexpectedFailure(message);
    }
    return const AuthUnexpectedFailure();
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
