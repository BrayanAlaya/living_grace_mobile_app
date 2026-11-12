import 'dart:io';

/// Conexión autenticada a `WS /ws/notifications`.
abstract class NotificationSocket {
  Stream<dynamic> get messages;

  Future<void> close();
}

typedef NotificationSocketConnect =
    Future<NotificationSocket> Function({
      required String url,
      required String ticket,
    });

/// Subprotocolos: `living-grace.notifications` y `ticket.<ticket>`.
Future<NotificationSocket> connectNotificationSocket({
  required String url,
  required String ticket,
}) async {
  final socket = await WebSocket.connect(url, protocols: [
    'living-grace.notifications',
    'ticket.$ticket',
  ]).timeout(const Duration(seconds: 8));
  return _IoNotificationSocket(socket);
}

class _IoNotificationSocket implements NotificationSocket {
  _IoNotificationSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get messages => _socket;

  @override
  Future<void> close() => _socket.close();
}
