import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../session/token_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenStore,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 45),
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStore tokenStore;
  final http.Client _httpClient;
  final Duration timeout;

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final authorization = tokenStore.authorizationHeader;
      if (authorization != null) {
        headers['Authorization'] = authorization;
      }
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    _logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
    );

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: encodedBody,
          )
          .timeout(timeout);
      _logResponse(uri: uri, response: response);
      return response;
    } on ApiException {
      rethrow;
    } catch (error) {
      _logError(uri: uri, error: error);
      throw const ApiNetworkException();
    }
  }

  dynamic decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      return response.body;
    }
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic>? body,
  }) {
    debugPrint('┌──────── API REQUEST ────────');
    debugPrint('│ $method $uri');
    debugPrint('│ headers: ${_prettyJson(_redactHeaders(headers))}');
    debugPrint('│ body: ${_prettyJson(_redactBody(body))}');
    debugPrint('└─────────────────────────────');
  }

  void _logResponse({
    required Uri uri,
    required http.Response response,
  }) {
    debugPrint('┌──────── API RESPONSE ───────');
    debugPrint('│ $uri');
    debugPrint('│ status: ${response.statusCode}');
    debugPrint('│ body: ${_prettyBody(response.body)}');
    debugPrint('└─────────────────────────────');
  }

  void _logError({required Uri uri, required Object error}) {
    debugPrint('┌──────── API ERROR ──────────');
    debugPrint('│ $uri');
    debugPrint('│ $error');
    debugPrint('└─────────────────────────────');
  }

  Map<String, String> _redactHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      if (key.toLowerCase() == 'authorization') {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  Map<String, dynamic>? _redactBody(Map<String, dynamic>? body) {
    if (body == null) return null;
    return body.map((key, value) {
      if (key.toLowerCase() == 'password') {
        return MapEntry(key, '********');
      }
      return MapEntry(key, value);
    });
  }

  String _prettyJson(Object? value) {
    if (value == null) return 'null';
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  String _prettyBody(String body) {
    if (body.isEmpty) return '(empty)';
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } catch (_) {
      return body;
    }
  }
}
