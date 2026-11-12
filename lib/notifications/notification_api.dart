import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../data/session/in_memory_token_store.dart';
import 'app_notification.dart';

/// Consume los endpoints HTTP de `/notifications`.
class NotificationApi {
  NotificationApi({required this.tokenStore, http.Client? client})
    : _client = client ?? http.Client();

  final InMemoryTokenStore tokenStore;
  final http.Client _client;

  Future<NotificationPage> list({
    int limit = 20,
    int offset = 0,
    bool? isRead,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (isRead != null) 'is_read': '$isRead',
    };
    final path = '/notifications?${Uri(queryParameters: query).query}';
    final body = await _send('GET', path, expected: 200);
    return NotificationPage.fromJson(body);
  }

  Future<int> unreadCount() async {
    final body = await _send('GET', '/notifications/unread-count', expected: 200);
    final count = body['unread_count'];
    if (count is int) return count;
    if (count is num) return count.toInt();
    throw const FormatException('NotificationUnreadCount');
  }

  Future<void> markRead(int id) async {
    await _send('PATCH', '/notifications/$id/read', expected: 200);
  }

  Future<int> markAllRead() async {
    final body = await _send('PATCH', '/notifications/read-all', expected: 200);
    final count = body['updated_count'];
    if (count is int) return count;
    if (count is num) return count.toInt();
    return 0;
  }

  /// Ticket de un solo uso. No se persiste ni se registra.
  Future<String> issueSocketTicket() async {
    final body = await _send('POST', '/notifications/ws-ticket', expected: 200);
    final ticket = body['ticket'];
    if (ticket is! String || ticket.isEmpty) {
      throw const FormatException('NotificationSocketTicket');
    }
    return ticket;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    required int expected,
  }) async {
    final token = await tokenStore.readAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await switch (method) {
      'POST' => _client.post(uri, headers: headers),
      'PATCH' => _client.patch(uri, headers: headers),
      _ => _client.get(uri, headers: headers),
    }.timeout(ApiConfig.timeout);

    if (response.statusCode != expected) {
      throw Exception(
        'No se pudieron actualizar las notificaciones (${response.statusCode}).',
      );
    }
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('NotificationResponse');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
