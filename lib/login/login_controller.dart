import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/session/token_store.dart';
import '../domain/entities/user.dart';
import '../domain/failures/auth_failure.dart';

enum LoginStatus {
  idle,
  authenticating,
  authenticated,
  failure,
}

class LoginController extends ChangeNotifier {
  LoginController({
    required this.client,
    required this.tokenStore,
  });

  final ApiClient client;
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

    if (identifier.trim().isEmpty || password.isEmpty) {
      status = LoginStatus.failure;
      failure = const EmptyCredentialsFailure();
      user = null;
      notifyListeners();
      return false;
    }

    try {
      final response = await client.post(
        '/auth/login',
        body: {
          'identifier': identifier.trim(),
          'password': password,
        },
      );

      final decoded = client.decodeBody(response);
      if (response.statusCode != 200 || decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          body: decoded,
          message: 'No se pudo iniciar sesión',
        );
      }

      final accessToken = decoded['access_token'];
      if (accessToken is! String || accessToken.isEmpty) {
        throw const FormatException('TokenResponse sin access_token');
      }
      final tokenType =
          (decoded['token_type'] as String?)?.trim().isNotEmpty == true
              ? decoded['token_type'] as String
              : 'bearer';

      tokenStore.save(accessToken: accessToken, tokenType: tokenType);

      Map<String, dynamic>? claims;
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        try {
          final normalized = base64Url.normalize(parts[1]);
          final json = jsonDecode(utf8.decode(base64Url.decode(normalized)));
          if (json is Map<String, dynamic>) claims = json;
        } catch (_) {}
      }

      String? claim(List<String> keys) {
        final payload = claims;
        if (payload == null) return null;
        for (final key in keys) {
          final value = payload[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
        return null;
      }

      final trimmed = identifier.trim();
      user = User(
        id: claim(const ['sub', 'id', 'user_id']) ?? trimmed,
        email: claim(const ['email']) ?? trimmed,
        displayName: claim(const [
              'name',
              'full_name',
              'username',
              'preferred_username',
            ]) ??
            (trimmed.contains('@') ? trimmed.split('@').first : trimmed),
      );
      status = LoginStatus.authenticated;
      failure = null;
      notifyListeners();
      return true;
    } on ApiNetworkException {
      return _fail(const NetworkFailure());
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return _fail(const InvalidCredentialsFailure());
      }

      String? message;
      final body = error.body;
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          message = detail.trim();
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] is String) {
            message = (first['msg'] as String).trim();
          }
        }
      }

      if (error.statusCode == 422) {
        final normalized = (message ?? '').toLowerCase();
        if (normalized.contains('credential') ||
            normalized.contains('password') ||
            normalized.contains('identifier')) {
          return _fail(const InvalidCredentialsFailure());
        }
      }

      if (message != null && message.isNotEmpty) {
        return _fail(AuthUnexpectedFailure(message));
      }
      return _fail(const AuthUnexpectedFailure());
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
}
