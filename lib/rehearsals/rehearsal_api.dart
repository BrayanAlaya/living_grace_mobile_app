import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../data/session/in_memory_token_store.dart';
import 'rehearsal.dart';

/// Consume los endpoints de ensayos del backend.
class RehearsalApi {
  RehearsalApi({required this.tokenStore, http.Client? client})
      : _client = client ?? http.Client();

  final InMemoryTokenStore tokenStore;
  final http.Client _client;

  /// `GET /rehearsals`: ensayos visibles para el usuario, ordenados por fecha.
  Future<List<Rehearsal>> fetchAll() async {
    final json = await _get('/rehearsals?limit=100');
    final items = json['items'] as List;
    return items
        .map((item) => Rehearsal.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Ensayos de hoy en adelante (los ya pasados de días anteriores se omiten).
  Future<List<Rehearsal>> fetchUpcoming() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all = await fetchAll();
    return all.where((r) => !r.startAt.isBefore(today)).toList();
  }

  /// `GET /rehearsals/{id}`
  Future<Rehearsal> fetchDetail(int id) async {
    final json = await _get('/rehearsals/$id');
    return Rehearsal.fromJson(json);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await tokenStore.readAccessToken();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(ApiConfig.timeout);

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los ensayos (${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
