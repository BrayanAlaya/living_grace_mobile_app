import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/repositories/token_store.dart';
import '../models/rehearsal_schedule_dto.dart';
import 'rehearsal_remote_datasource.dart';
import 'rehearsal_remote_exceptions.dart';

/// Habla con ministerios y POST /rehearsals.
class HttpRehearsalRemoteDataSource implements RehearsalRemoteDataSource {
  HttpRehearsalRemoteDataSource({
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
  Future<List<MinistryOptionDto>> listMinistries() async {
    final response = await _send('GET', '/ministries/registration-fields');
    _ensureOk(response, expected: 200);
    try {
      final body = jsonDecode(response.body);
      if (body is! List) throw const FormatException('ministries');
      return [
        for (final item in body)
          if (item is Map)
            MinistryOptionDto.fromJson(Map<String, dynamic>.from(item)),
      ];
    } on FormatException {
      throw const RehearsalParseException();
    }
  }

  @override
  Future<List<MinistryMemberDto>> listMembers(int ministryId) async {
    final response = await _send('GET', '/ministries/$ministryId/members');
    _ensureOk(response, expected: 200);
    try {
      final body = jsonDecode(response.body);
      if (body is! Map) throw const FormatException('members');
      final raw = body['members'];
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map)
            MinistryMemberDto.fromJson(Map<String, dynamic>.from(item)),
      ];
    } on FormatException {
      throw const RehearsalParseException();
    }
  }

  @override
  Future<void> create(RehearsalCreateDto request) async {
    final response = await _send('POST', '/rehearsals', body: request.toJson());
    _ensureOk(response, expected: 201);
  }

  @override
  Future<void> update(int rehearsalId, RehearsalUpdateDto request) async {
    final response = await _send(
      'PATCH',
      '/rehearsals/$rehearsalId',
      body: request.toJson(),
    );
    _ensureOk(response, expected: 200);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _tokenStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const RehearsalUnauthorizedException();
    }

    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    try {
      final future = switch (method) {
        'POST' => _client.post(uri, headers: headers, body: jsonEncode(body)),
        'PATCH' => _client.patch(uri, headers: headers, body: jsonEncode(body)),
        _ => _client.get(uri, headers: headers),
      };
      return await future.timeout(_timeout);
    } on RehearsalRemoteException {
      rethrow;
    } on Object catch (error) {
      throw RehearsalNetworkException(error);
    }
  }

  void _ensureOk(http.Response response, {required int expected}) {
    if (response.statusCode == expected) return;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const RehearsalUnauthorizedException();
    }
    if (response.statusCode == 422) {
      throw RehearsalServerException(422, _validationMessage(response.body));
    }
    throw RehearsalServerException(response.statusCode);
  }

  String? _validationMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          return (first['msg'] as String).trim();
        }
      }
    } on Object {
      return null;
    }
    return null;
  }
}
