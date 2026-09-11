import 'dart:convert';

import '../../core/network/api_exception.dart';
import '../../core/session/token_store.dart';
import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/living_grace_api.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required this._api,
    required this._tokenStore,
  });

  final LivingGraceApi _api;
  final TokenStore _tokenStore;

  @override
  Future<({User? user, AuthFailure? failure})> login(
    AuthCredentials credentials,
  ) async {
    final identifier = credentials.identifier.trim();
    final password = credentials.password;

    if (identifier.isEmpty || password.isEmpty) {
      return (user: null, failure: const EmptyCredentialsFailure());
    }

    try {
      final token = await _api.login(
        identifier: identifier,
        password: password,
      );

      _tokenStore.save(
        accessToken: token.accessToken,
        tokenType: token.tokenType,
      );

      return (
        user: _userFromLogin(identifier, token.accessToken),
        failure: null,
      );
    } on ApiNetworkException {
      return (user: null, failure: const NetworkFailure());
    } on ApiException catch (error) {
      return (user: null, failure: _mapFailure(error));
    } on FormatException {
      return (user: null, failure: const AuthUnexpectedFailure());
    }
  }

  @override
  void logout() {
    _tokenStore.clear();
  }

  AuthFailure _mapFailure(ApiException error) {
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

  User _userFromLogin(String identifier, String accessToken) {
    final claims = _decodeJwtPayload(accessToken);
    final email = _stringClaim(claims, const ['email']) ??
        (identifier.contains('@') ? identifier : identifier);
    final displayName = _stringClaim(claims, const [
          'name',
          'full_name',
          'username',
          'preferred_username',
        ]) ??
        (identifier.contains('@') ? identifier.split('@').first : identifier);

    final id = _stringClaim(claims, const ['sub', 'id', 'user_id']) ?? identifier;

    return User(
      id: id,
      email: email,
      displayName: displayName,
    );
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) return json;
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _stringClaim(Map<String, dynamic>? claims, List<String> keys) {
    if (claims == null) return null;
    for (final key in keys) {
      final value = claims[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
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
