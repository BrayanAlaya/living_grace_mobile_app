import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/token_store.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_remote_exceptions.dart';
import '../models/login_request_dto.dart';

/// Adaptador que implementa [AuthRepository] contra la API real.
/// No cambia el contrato de dominio; solo traduce token ↔ sesión local.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required this._remoteDataSource,
    required this._tokenStore,
  });

  final AuthRemoteDataSource _remoteDataSource;
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

    if (password.length > 128) {
      return (
        user: null,
        failure: const AuthUnexpectedFailure(
          'La contraseña no puede superar 128 caracteres.',
        ),
      );
    }

    try {
      final token = await _remoteDataSource.login(
        LoginRequestDto(identifier: identifier, password: password),
      );

      await _tokenStore.saveAccessToken(
        token.accessToken,
        tokenType: token.tokenType,
      );
      debugPrint('Token: ${token.accessToken}');

      return (
        user: User(
          id: identifier,
          email: identifier,
          displayName: _displayName(identifier),
          role: token.role,
          mustChangePassword: token.mustChangePassword,
        ),
        failure: null,
      );
    } on AuthUnauthorizedException {
      return (user: null, failure: const InvalidCredentialsFailure());
    } on AuthValidationException catch (error) {
      return (user: null, failure: _mapValidationFailure(error.message));
    } on AuthNetworkException {
      return (user: null, failure: const NetworkFailure());
    } on AuthServerException {
      return (user: null, failure: const NetworkFailure());
    }
  }

  @override
  Future<AuthFailure?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStore.readAccessToken();
    if (token == null || token.isEmpty) {
      return const AuthUnexpectedFailure('Tu sesión expiró. Inicia sesión otra vez.');
    }
    try {
      await _remoteDataSource.changePassword(
        accessToken: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on AuthUnauthorizedException {
      return const InvalidCredentialsFailure();
    } on AuthValidationException catch (error) {
      return _mapValidationFailure(error.message);
    } on AuthNetworkException {
      return const NetworkFailure();
    } on AuthServerException {
      return const NetworkFailure();
    }
  }

  @override
  Future<({String? temporaryPassword, AuthFailure? failure})> resetPassword(
    int userId,
  ) async {
    final token = await _tokenStore.readAccessToken();
    if (token == null || token.isEmpty) {
      return (
        temporaryPassword: null,
        failure: const AuthUnexpectedFailure(
          'Tu sesión expiró. Inicia sesión otra vez.',
        ),
      );
    }
    try {
      final password = await _remoteDataSource.resetPassword(
        accessToken: token,
        userId: userId,
      );
      return (temporaryPassword: password, failure: null);
    } on AuthUnauthorizedException {
      return (
        temporaryPassword: null,
        failure: const AuthUnexpectedFailure(
          'No tienes permiso para restablecer esta contraseña.',
        ),
      );
    } on AuthValidationException catch (error) {
      return (
        temporaryPassword: null,
        failure: _mapValidationFailure(error.message),
      );
    } on AuthNetworkException {
      return (temporaryPassword: null, failure: const NetworkFailure());
    } on AuthServerException {
      return (temporaryPassword: null, failure: const NetworkFailure());
    }
  }

  @override
  Future<void> logout() => _tokenStore.clear();

  AuthFailure _mapValidationFailure(String? message) {
    final text = message?.trim() ?? '';
    if (text.isEmpty) return const InvalidCredentialsFailure();

    final normalized = text.toLowerCase();
    if (normalized.contains('credential') ||
        normalized.contains('password') ||
        normalized.contains('identifier') ||
        normalized.contains('incorrect')) {
      return const InvalidCredentialsFailure();
    }

    return AuthUnexpectedFailure(text);
  }

  String _displayName(String identifier) {
    if (!identifier.contains('@')) return identifier;
    final local = identifier.split('@').first.trim();
    return local.isEmpty ? identifier : local;
  }
}
