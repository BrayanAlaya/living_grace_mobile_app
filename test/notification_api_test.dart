import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/notifications/app_notification.dart';
import 'package:living_grace/notifications/notification_api.dart';
import 'package:living_grace/notifications/notification_controller.dart';
import 'package:living_grace/notifications/notification_socket.dart';

void main() {
  final sample = {
    'id': 42,
    'type': 'REHEARSAL_ASSIGNED',
    'title': 'New rehearsal assignment',
    'message': 'You have been assigned to rehearsal "Sunday practice".',
    'resource_type': 'rehearsal',
    'resource_id': 306,
    'is_read': false,
    'created_at': '2026-11-12T21:00:00Z',
  };

  test('normaliza type HTTP y notification_type del socket', () {
    final fromHttp = AppNotification.fromJson(sample);
    final fromSocket = AppNotification.fromJson({
      'id': 42,
      'notification_type': 'REHEARSAL_ASSIGNED',
      'title': 'New rehearsal assignment',
      'message': 'Assigned',
      'resource_type': 'rehearsal',
      'resource_id': 306,
      'is_read': false,
      'created_at': '2026-11-12T21:00:00Z',
    });

    expect(fromHttp.type, NotificationType.rehearsalAssigned);
    expect(fromSocket.type, NotificationType.rehearsalAssigned);
    expect(fromHttp.resourceId, 306);
  });

  test('GET /notifications y unread-count usan el JWT', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');
    late Uri seenList;
    late Uri seenCount;
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer abc');
      if (request.url.path.endsWith('/unread-count')) {
        seenCount = request.url;
        return http.Response(jsonEncode({'unread_count': 5}), 200);
      }
      seenList = request.url;
      return http.Response(
        jsonEncode({
          'total': 1,
          'limit': 20,
          'offset': 0,
          'items': [sample],
        }),
        200,
      );
    });

    final api = NotificationApi(tokenStore: store, client: client);
    final page = await api.list();
    final unread = await api.unreadCount();

    expect(seenList.path, '/notifications');
    expect(seenList.queryParameters['limit'], '20');
    expect(seenCount.path, '/notifications/unread-count');
    expect(page.items.single.id, 42);
    expect(unread, 5);
  });

  test('marca una y todas como leídas', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/read-all')) {
        return http.Response(jsonEncode({'updated_count': 5}), 200);
      }
      return http.Response(jsonEncode({'id': 42, 'is_read': true}), 200);
    });

    final api = NotificationApi(tokenStore: store, client: client);
    await api.markRead(42);
    expect(await api.markAllRead(), 5);
    expect(paths, [
      'PATCH /notifications/42/read',
      'PATCH /notifications/read-all',
    ]);
  });

  test('el controlador carga, marca leídas y evita duplicados del socket', () async {
    final incoming = StreamController<dynamic>.broadcast();
    final api = _MemoryNotificationApi()
      ..items = [
        AppNotification.fromJson(sample),
      ]
      ..unread = 1;
    var tickets = 0;
    final controller = NotificationController(
      api: api,
      socketUrl: 'wss://example.test/ws/notifications',
      connect: ({required url, required ticket}) async {
        tickets++;
        expect(url, 'wss://example.test/ws/notifications');
        expect(ticket, isNotEmpty);
        return _FakeSocket(incoming.stream);
      },
      wait: (_) async {},
    );

    await controller.start();
    await Future<void>.delayed(Duration.zero);
    expect(controller.items.single.id, 42);
    expect(controller.unreadCount, 1);
    expect(tickets, 1);

    incoming.add(
      jsonEncode({
        'type': 'notification.created',
        'data': {
          'id': 42,
          'notification_type': 'REHEARSAL_ASSIGNED',
          'title': 'New rehearsal assignment',
          'message': 'Assigned',
          'resource_type': 'rehearsal',
          'resource_id': 306,
          'is_read': false,
          'created_at': '2026-11-12T21:00:00Z',
        },
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.items, hasLength(1));
    expect(controller.unreadCount, 1);

    incoming.add(
      jsonEncode({
        'type': 'notification.created',
        'data': {
          'id': 43,
          'notification_type': 'MEMBERSHIP_APPROVED',
          'title': 'Approved',
          'message': 'Welcome',
          'resource_type': 'membership',
          'resource_id': 8,
          'is_read': false,
          'created_at': '2026-11-12T22:00:00Z',
        },
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.items.first.id, 43);
    expect(controller.unreadCount, 2);

    await controller.markRead(43);
    expect(controller.unreadCount, 1);
    expect(controller.items.first.isRead, isTrue);

    await controller.markAllRead();
    expect(controller.unreadCount, 0);
    expect(controller.items.every((item) => item.isRead), isTrue);

    await controller.stop();
    expect(controller.items, isEmpty);
    expect(controller.unreadCount, 0);
    expect(controller.connected, isFalse);
  });

  test('reconecta con un ticket nuevo y vuelve a consultar HTTP', () async {
    final first = StreamController<dynamic>();
    final second = StreamController<dynamic>.broadcast();
    final api = _MemoryNotificationApi()..unread = 0;
    final tickets = <String>[];
    var connects = 0;
    final controller = NotificationController(
      api: api,
      connect: ({required url, required ticket}) async {
        tickets.add(ticket);
        connects++;
        return _FakeSocket(connects == 1 ? first.stream : second.stream);
      },
      wait: (_) async {},
    );

    await controller.start();
    await Future<void>.delayed(Duration.zero);
    expect(tickets, ['ticket-1']);
    expect(api.listCalls, 1);

    await first.close();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(tickets, ['ticket-1', 'ticket-2']);
    expect(api.listCalls, greaterThanOrEqualTo(2));
    await controller.stop();
  });

  test('start termina aunque el websocket no conecte', () async {
    final api = _MemoryNotificationApi();
    final controller = NotificationController(
      api: api,
      connect: ({required url, required ticket}) {
        return Completer<NotificationSocket>().future;
      },
      wait: (_) async {},
      backoff: (_) => const Duration(days: 1),
    );

    await controller.start().timeout(const Duration(seconds: 1));
    expect(api.listCalls, 1);
    await controller.stop();
  });
}

class _FakeSocket implements NotificationSocket {
  _FakeSocket(this.messages);

  @override
  final Stream<dynamic> messages;

  @override
  Future<void> close() async {}
}

class _MemoryNotificationApi extends NotificationApi {
  _MemoryNotificationApi() : super(tokenStore: InMemoryTokenStore());

  List<AppNotification> items = const [];
  int unread = 0;
  int listCalls = 0;
  int tickets = 0;

  @override
  Future<NotificationPage> list({
    int limit = 20,
    int offset = 0,
    bool? isRead,
  }) async {
    listCalls++;
    return NotificationPage(
      total: items.length,
      limit: limit,
      offset: offset,
      items: items.skip(offset).take(limit).toList(),
    );
  }

  @override
  Future<int> unreadCount() async => unread;

  @override
  Future<void> markRead(int id) async {
    items = [
      for (final item in items)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    unread = items.where((item) => !item.isRead).length;
  }

  @override
  Future<int> markAllRead() async {
    final updated = items.where((item) => !item.isRead).length;
    items = [for (final item in items) item.copyWith(isRead: true)];
    unread = 0;
    return updated;
  }

  @override
  Future<String> issueSocketTicket() async {
    tickets++;
    return 'ticket-$tickets';
  }
}
