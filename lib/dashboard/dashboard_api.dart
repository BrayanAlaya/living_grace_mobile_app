import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../data/session/in_memory_token_store.dart';
import 'dashboard.dart';

/// Consume `GET /dashboard/me`.
class DashboardApi {
  DashboardApi({required this.tokenStore, http.Client? client})
    : _client = client ?? http.Client();

  final InMemoryTokenStore tokenStore;
  final http.Client _client;

  Future<DashboardSnapshot> fetch({int? ministryId}) async {
    final token = await tokenStore.readAccessToken();
    final query = {
      if (ministryId != null) 'ministry_id': '$ministryId',
    };
    final path = query.isEmpty
        ? '/dashboard/me'
        : '/dashboard/me?${Uri(queryParameters: query).query}';
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo cargar el dashboard (${response.statusCode}).',
      );
    }
    debugPrint('GET $path => ${response.body}', wrapWidth: 1024);
    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw const FormatException('DashboardResponse');
    }
    return DashboardSnapshot.fromJson(Map<String, dynamic>.from(body));
  }
}
