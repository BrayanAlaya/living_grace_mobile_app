import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../attendance/attendance_qr.dart';
import '../core/config/api_config.dart';
import '../data/session/in_memory_token_store.dart';
import '../domain/entities/rehearsal_draft.dart';
import 'rehearsal.dart';

/// Consume los endpoints de ensayos, QR y check-in del backend.
class RehearsalApi {
  RehearsalApi({required this.tokenStore, http.Client? client})
    : _client = client ?? http.Client();

  final InMemoryTokenStore tokenStore;
  final http.Client _client;

  /// `GET /rehearsals`: ensayos visibles para el usuario, ordenados por fecha.
  Future<List<Rehearsal>> fetchAll() async {
    final page = await fetchPage(limit: 100, offset: 0);
    return page.items;
  }

  /// `GET /rehearsals?limit=&offset=&ministry_id=`
  Future<({List<Rehearsal> items, int total})> fetchPage({
    int limit = 20,
    int offset = 0,
    int? ministryId,
  }) async {
    final query = {
      'limit': '$limit',
      'offset': '$offset',
      if (ministryId != null) 'ministry_id': '$ministryId',
    };
    final path = '/rehearsals?${Uri(queryParameters: query).query}';
    final json = await _send(
      'GET',
      path,
      expected: 200,
    );
    debugPrint('GET $path => ${jsonEncode(json)}', wrapWidth: 1024);
    final items = json['items'] as List? ?? const [];
    return (
      items: [
        for (final item in items)
          if (item is Map)
            Rehearsal.fromJson(Map<String, dynamic>.from(item)),
      ],
      total: json['total'] as int? ?? items.length,
    );
  }

  /// Lista completa de ensayos que envía la API, sin filtrar por fecha.
  Future<List<Rehearsal>> fetchUpcoming() => fetchAll();

  /// `GET /rehearsals/{id}`
  Future<Rehearsal> fetchDetail(int id) async {
    final json = await _send('GET', '/rehearsals/$id', expected: 200);
    return Rehearsal.fromJson(json);
  }

  /// `GET /ministries/registration-fields`
  Future<List<MinistryOption>> listMinistries() async {
    final token = await tokenStore.readAccessToken();
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/ministries/registration-fields'),
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar los ministerios (${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body);
    if (body is! List) return const [];
    return [
      for (final item in body)
        if (item is Map)
          MinistryOption(
            id: item['id'] as int,
            name: item['name'] as String,
          ),
    ];
  }

  /// `POST /rehearsals/{id}/qr-sessions`
  Future<AttendanceQr> createQrSession(Rehearsal rehearsal) async {
    try {
      return await _createQrSession(rehearsal);
    } catch (_) {
      await revokeActiveQrSession(rehearsal.id);
      return _createQrSession(rehearsal);
    }
  }

  Future<AttendanceQr> _createQrSession(Rehearsal rehearsal) async {
    final window = _qrWindow(rehearsal);
    final json = await _send(
      'POST',
      '/rehearsals/${rehearsal.id}/qr-sessions',
      expected: 201,
      body: {
        'opens_at': window.opensAt.toUtc().toIso8601String(),
        'expires_at': window.expiresAt.toUtc().toIso8601String(),
      },
    );
    return AttendanceQr(
      rehearsal: rehearsal,
      payload: json['check_in_url'] as String,
      generatedAt: DateTime.parse(json['opens_at'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
    );
  }

  /// `DELETE /rehearsals/{id}/qr-sessions/active`
  Future<void> revokeActiveQrSession(int rehearsalId) async {
    final token = await tokenStore.readAccessToken();
    final response = await _client
        .delete(
          Uri.parse(
            '${ApiConfig.baseUrl}/rehearsals/$rehearsalId/qr-sessions/active',
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 204 || response.statusCode == 404) return;
    if (response.statusCode != 204) {
      throw Exception(
        'No se pudo revocar el QR (${response.statusCode}).',
      );
    }
  }

  /// `POST /attendance/check-in`
  Future<AttendanceCheckIn> checkIn({
    required Rehearsal rehearsal,
    required String token,
  }) async {
    final sessionToken = checkInTokenFromQr(token);
    if (sessionToken.isEmpty) {
      throw const AttendanceCheckInException('No se leyó el código QR.');
    }
    try {
      final json = await _send(
        'POST',
        '/attendance/check-in',
        expected: 201,
        accepted: const {200, 201},
        body: {'token': sessionToken},
      );
      final rehearsalId = json['rehearsal_id'] as int;
      if (rehearsalId != rehearsal.id) {
        throw const AttendanceCheckInException(
          'Este código no corresponde a este ensayo.',
        );
      }
      final status = AttendanceStatusLabel.fromApi(json['attendance_status']);
      if (status == null) {
        throw const AttendanceCheckInException(
          'El servidor no devolvió un estado de asistencia válido.',
        );
      }
      return AttendanceCheckIn(
        rehearsal: rehearsal,
        status: status,
        markedAt: DateTime.parse(json['arrival_at'] as String).toLocal(),
      );
    } on AttendanceCheckInException {
      rethrow;
    } on _ApiFailure catch (error) {
      throw AttendanceCheckInException(
        _checkInError(error.statusCode, error.message),
      );
    } on Exception catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      throw AttendanceCheckInException(message);
    }
  }

  /// `DELETE /rehearsals/{id}`
  Future<void> delete(int id) async {
    final token = await tokenStore.readAccessToken();
    final response = await _client
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/rehearsals/$id'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 204) {
      throw Exception(
        'No se pudo eliminar el ensayo (${response.statusCode}).',
      );
    }
  }

  ({DateTime opensAt, DateTime expiresAt}) _qrWindow(Rehearsal rehearsal) {
    final now = DateTime.now();
    final opensAt = rehearsal.startAt.isAfter(now) ? rehearsal.startAt : now;
    final expiresAt = rehearsal.endAt.isAfter(opensAt)
        ? rehearsal.endAt
        : opensAt.add(
            Duration(
              minutes: rehearsal.toleranceMinutes <= 0
                  ? 60
                  : rehearsal.toleranceMinutes,
            ),
          );
    return (opensAt: opensAt, expiresAt: expiresAt);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    required int expected,
    Set<int> accepted = const {},
    Map<String, dynamic>? body,
  }) async {
    final token = await tokenStore.readAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final encoded = body == null ? null : jsonEncode(body);
    final response = await switch (method) {
      'POST' => _client.post(uri, headers: headers, body: encoded),
      'PATCH' => _client.patch(uri, headers: headers, body: encoded),
      'DELETE' => _client.delete(uri, headers: headers),
      _ => _client.get(uri, headers: headers),
    }.timeout(ApiConfig.timeout);

    final allowed = accepted.isEmpty ? {expected} : accepted;
    if (!allowed.contains(response.statusCode)) {
      throw _ApiFailure(response.statusCode, _errorMessage(response));
    }
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('La respuesta del servidor no se pudo leer.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) return detail.trim();
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] is String) {
            return (first['msg'] as String).trim();
          }
        }
      }
    } on Object {
      // Usa el código HTTP si el cuerpo no es JSON.
    }
    return 'No se pudo completar la solicitud (${response.statusCode}).';
  }
}

class _ApiFailure implements Exception {
  const _ApiFailure(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

String _checkInError(int statusCode, String fallback) {
  return switch (statusCode) {
    400 => 'La sesión del QR no es válida o ya no está disponible.',
    403 => 'No tienes permiso para marcar esta asistencia.',
    409 => 'La asistencia ya estaba registrada.',
    500 => 'No se pudo registrar la asistencia.',
    _ => fallback,
  };
}

/// Extrae el token de asistencia del QR (`check_in_url` o el valor crudo).
String checkInTokenFromQr(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return trimmed;
  final fromQuery = uri.queryParameters['token']?.trim();
  if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
  return trimmed;
}
