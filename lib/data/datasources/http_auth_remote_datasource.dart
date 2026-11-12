import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/login_request_dto.dart';
import '../models/token_response_dto.dart';
import 'auth_remote_datasource.dart';
import 'auth_remote_exceptions.dart';

/// Implementación HTTP de `/auth/login` según el OpenAPI.
class HttpAuthRemoteDataSource implements AuthRemoteDataSource {
  HttpAuthRemoteDataSource({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _timeout = timeout ?? ApiConfig.timeout;

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  @override
  Future<TokenResponseDto> login(LoginRequestDto request) async {
    final uri = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return _mapLoginResponse(response);
    } on AuthRemoteException {
      rethrow;
    } on Object catch (error) {
      throw AuthNetworkException(error);
    }
  }

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/change-password');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 204) return;
      _throwFor(response);
    } on AuthRemoteException {
      rethrow;
    } on Object catch (error) {
      throw AuthNetworkException(error);
    }
  }

  @override
  Future<String> resetPassword({
    required String accessToken,
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/reset-password');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: '{}',
          )
          .timeout(_timeout);
      if (response.statusCode != 200) _throwFor(response);
      final body = jsonDecode(response.body);
      if (body is! Map || body['temporary_password'] is! String) {
        throw const AuthServerException(200);
      }
      return body['temporary_password'] as String;
    } on AuthRemoteException {
      rethrow;
    } on Object catch (error) {
      throw AuthNetworkException(error);
    }
  }

  Never _throwFor(http.Response response) {
    final status = response.statusCode;
    if (status == 401 || status == 403) {
      throw const AuthUnauthorizedException();
    }
    if (status == 422) {
      throw AuthValidationException(_parseValidationMessage(response.body));
    }
    throw AuthServerException(status);
  }

  TokenResponseDto _mapLoginResponse(http.Response response) {
    final status = response.statusCode;

    if (status == 200) {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const AuthServerException(200);
      }
      return TokenResponseDto.fromJson(body);
    }

    if (status == 401 || status == 403) {
      throw const AuthUnauthorizedException();
    }

    if (status == 422) {
      throw AuthValidationException(_parseValidationMessage(response.body));
    }

    if (status >= 500) {
      throw AuthServerException(status);
    }

    // Varios backends responden 400 ante credenciales inválidas.
    if (status == 400) {
      throw const AuthUnauthorizedException();
    }

    throw AuthServerException(status);
  }

  String? _parseValidationMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final detail = decoded['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map<String, dynamic>) {
          return first['msg'] as String?;
        }
      }
      if (detail is String) return detail;
    } on Object {
      return null;
    }
    return null;
  }
}
