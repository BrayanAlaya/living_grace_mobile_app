import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/config/api_config.dart';
import 'app_notification.dart';
import 'notification_api.dart';
import 'notification_socket.dart';

const _pageSize = 20;
const _maxBackoff = Duration(seconds: 30);

/// Estado de notificaciones: HTTP + WebSocket, aislado por sesión.
class NotificationController extends ChangeNotifier {
  NotificationController({
    required this.api,
    NotificationSocketConnect? connect,
    String? socketUrl,
    Duration Function(int attempt)? backoff,
    Future<void> Function(Duration delay)? wait,
  }) : _connect = connect ?? connectNotificationSocket,
       _socketUrl = socketUrl ?? '${ApiConfig.wsBaseUrl}/ws/notifications',
       _backoff = backoff ?? _defaultBackoff,
       _wait = wait ?? Future<void>.delayed;

  final NotificationApi api;
  final NotificationSocketConnect _connect;
  final String _socketUrl;
  final Duration Function(int attempt) _backoff;
  final Future<void> Function(Duration delay) _wait;

  List<AppNotification> items = const [];
  int total = 0;
  int unreadCount = 0;
  bool loading = false;
  bool loadingMore = false;
  bool connected = false;
  Object? error;

  bool _active = false;
  int _generation = 0;
  int _attempt = 0;
  NotificationSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  AppNotification? lastIncoming;

  bool get hasMore => items.length < total;

  AppNotification? takeIncoming() {
    final incoming = lastIncoming;
    lastIncoming = null;
    return incoming;
  }

  Future<void> start() async {
    _generation++;
    final generation = _generation;
    _active = true;
    _attempt = 0;
    await _syncHttp();
    if (!_active || generation != _generation) return;
    unawaited(_openSocket(generation, syncAfter: false));
  }

  Future<void> stop() async {
    _generation++;
    _active = false;
    await _detachSocket();
    items = const [];
    total = 0;
    unreadCount = 0;
    loading = false;
    loadingMore = false;
    connected = false;
    error = null;
    lastIncoming = null;
    notifyListeners();
  }

  Future<void> reload() => _syncHttp();

  Future<void> loadMore() async {
    if (!_active || loading || loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await api.list(limit: _pageSize, offset: items.length);
      if (!_active) return;
      items = _merge(items, page.items);
      total = page.total;
      error = null;
    } catch (err) {
      if (!_active) return;
      error = err;
    } finally {
      loadingMore = false;
      if (_active) notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    final index = items.indexWhere((item) => item.id == id);
    final wasUnread = index >= 0 && !items[index].isRead;
    try {
      await api.markRead(id);
    } catch (err) {
      error = err;
      notifyListeners();
      rethrow;
    }
    if (!_active) return;
    if (index >= 0 && wasUnread) {
      final updated = [...items];
      updated[index] = updated[index].copyWith(isRead: true);
      items = updated;
      if (unreadCount > 0) unreadCount -= 1;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    try {
      await api.markAllRead();
    } catch (err) {
      error = err;
      notifyListeners();
      rethrow;
    }
    if (!_active) return;
    items = [for (final item in items) item.copyWith(isRead: true)];
    unreadCount = 0;
    notifyListeners();
  }

  Future<void> _syncHttp() async {
    if (!_active) return;
    loading = items.isEmpty;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.list(limit: _pageSize, offset: 0),
        api.unreadCount(),
      ]);
      if (!_active) return;
      final page = results[0] as NotificationPage;
      items = page.items;
      total = page.total;
      unreadCount = results[1] as int;
      error = null;
    } catch (err) {
      if (!_active) return;
      error = err;
    } finally {
      loading = false;
      if (_active) notifyListeners();
    }
  }

  Future<void> _openSocket(int generation, {required bool syncAfter}) async {
    if (!_active || generation != _generation) return;
    try {
      final ticket = await api.issueSocketTicket();
      if (!_active || generation != _generation) return;
      await _detachSocket();
      final socket = await _connect(url: _socketUrl, ticket: ticket);
      if (!_active || generation != _generation) {
        await socket.close();
        return;
      }
      _socket = socket;
      connected = true;
      _attempt = 0;
      notifyListeners();
      _subscription = socket.messages.listen(
        _onMessage,
        onError: (_) => _onDisconnected(generation),
        onDone: () => _onDisconnected(generation),
        cancelOnError: true,
      );
      if (syncAfter) await _syncHttp();
    } catch (_) {
      connected = false;
      if (_active && generation == _generation) notifyListeners();
      unawaited(_scheduleReconnect(generation));
    }
  }

  void _onMessage(dynamic raw) {
    if (!_active) return;
    final event = _decodeEvent(raw);
    if (event == null) return;
    if (event['type'] != 'notification.created') return;
    final data = event['data'];
    if (data is! Map) return;
    final AppNotification incoming;
    try {
      incoming = AppNotification.fromJson(Map<String, dynamic>.from(data));
    } on Object {
      return;
    }
    if (items.any((item) => item.id == incoming.id)) return;
    items = [incoming, ...items];
    total += 1;
    if (!incoming.isRead) unreadCount += 1;
    lastIncoming = incoming;
    notifyListeners();
  }

  void _onDisconnected(int generation) {
    if (!_active || generation != _generation) return;
    connected = false;
    notifyListeners();
    unawaited(_scheduleReconnect(generation));
  }

  Future<void> _scheduleReconnect(int generation) async {
    if (!_active || generation != _generation) return;
    _attempt += 1;
    await _wait(_backoff(_attempt));
    if (!_active || generation != _generation) return;
    await _openSocket(generation, syncAfter: true);
  }

  Future<void> _detachSocket() async {
    await _subscription?.cancel();
    _subscription = null;
    final socket = _socket;
    _socket = null;
    connected = false;
    if (socket != null) {
      try {
        await socket.close();
      } on Object {
        // La sesión ya se cerró.
      }
    }
  }

  Map<String, dynamic>? _decodeEvent(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is! String || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on Object {
      return null;
    }
    return null;
  }
}

Duration _defaultBackoff(int attempt) {
  final seconds = 1 << (attempt - 1).clamp(0, 5);
  final delay = Duration(seconds: seconds);
  return delay > _maxBackoff ? _maxBackoff : delay;
}

List<AppNotification> _merge(
  List<AppNotification> current,
  List<AppNotification> extra,
) {
  final seen = {for (final item in current) item.id};
  return [
    ...current,
    for (final item in extra)
      if (seen.add(item.id)) item,
  ];
}
