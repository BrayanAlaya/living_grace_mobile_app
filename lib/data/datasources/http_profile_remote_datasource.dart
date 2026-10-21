import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/repositories/token_store.dart';
import '../models/user_profile_dto.dart';
import 'profile_remote_datasource.dart';
import 'profile_remote_exceptions.dart';

/// S — solo lee GET /users/me con el bearer de la sesión.
class HttpProfileRemoteDataSource implements ProfileRemoteDataSource {
  HttpProfileRemoteDataSource({
    required this._tokenStore,
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _timeout = timeout ?? ApiConfig.timeout;

  final TokenStore _tokenStore;
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  @override
  Future<UserProfileDto> getMine() async {
    final token = await _tokenStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ProfileUnauthorizedException();
    }

    final uri = Uri.parse('$_baseUrl/users/me');

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
      return _map(response);
    } on ProfileRemoteException {
      rethrow;
    } on Object catch (error) {
      throw ProfileNetworkException(error);
    }
  }

  UserProfileDto _map(http.Response response) {
    final status = response.statusCode;

    if (status == 200) {
      try {
        final body = jsonDecode(response.body);
        if (body is! Map) throw const FormatException('UserProfile');
        return UserProfileDto.fromJson(Map<String, dynamic>.from(body));
      } on FormatException {
        throw const ProfileParseException();
      }
    }

    if (status == 401 || status == 403) {
      throw const ProfileUnauthorizedException();
    }

    if (status >= 500) {
      throw ProfileServerException(status);
    }

    throw ProfileServerException(status);
  }
}
