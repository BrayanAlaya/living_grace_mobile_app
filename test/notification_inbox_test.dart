import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/notifications/app_notification.dart';
import 'package:living_grace/notifications/notification_api.dart';
import 'package:living_grace/notifications/notification_controller.dart';
import 'package:living_grace/notifications/notification_socket.dart';
import 'package:living_grace/presentation/widgets/notification_bell.dart';
import 'package:living_grace/presentation/widgets/notification_inbox.dart';

void main() {
  testWidgets('la campana muestra el contador y abre el historial', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final socket = StreamController<dynamic>.broadcast();
    addTearDown(socket.close);
    final controller = NotificationController(
      api: _SeedApi(),
      connect: ({required url, required ticket}) async =>
          _IdleSocket(socket.stream),
      wait: (_) async {},
      backoff: (_) => const Duration(days: 1),
    );
    await controller.start();
    addTearDown(controller.stop);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationBell(
            controller: controller,
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('New rehearsal assignment'), findsOneWidget);
    expect(find.text('Membership pending'), findsOneWidget);
    expect(find.text('Marcar todas como leídas'), findsOneWidget);

    await tester.tap(find.text('New rehearsal assignment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.unreadCount, 1);
    expect(controller.items.firstWhere((item) => item.id == 42).isRead, isTrue);
  });

  testWidgets('el historial marca todas como leídas', (tester) async {
    final socket = StreamController<dynamic>.broadcast();
    addTearDown(socket.close);
    final controller = NotificationController(
      api: _SeedApi(),
      connect: ({required url, required ticket}) async =>
          _IdleSocket(socket.stream),
      wait: (_) async {},
      backoff: (_) => const Duration(days: 1),
    );
    await controller.start();
    addTearDown(controller.stop);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationInbox(
            controller: controller,
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Marcar todas como leídas'));
    await tester.pump();
    expect(controller.unreadCount, 0);
  });
}

class _IdleSocket implements NotificationSocket {
  _IdleSocket(this.messages);

  @override
  final Stream<dynamic> messages;

  @override
  Future<void> close() async {}
}

class _SeedApi extends NotificationApi {
  _SeedApi() : super(tokenStore: InMemoryTokenStore());

  List<AppNotification> items = [
    AppNotification(
      id: 42,
      type: NotificationType.rehearsalAssigned,
      title: 'New rehearsal assignment',
      message: 'Sunday practice',
      isRead: false,
      createdAt: DateTime(2026, 11, 12, 16),
      resourceType: 'rehearsal',
      resourceId: 306,
    ),
    AppNotification(
      id: 43,
      type: NotificationType.membershipPending,
      title: 'Membership pending',
      message: 'Someone joined',
      isRead: false,
      createdAt: DateTime(2026, 11, 12, 15),
    ),
  ];

  @override
  Future<NotificationPage> list({
    int limit = 20,
    int offset = 0,
    bool? isRead,
  }) async {
    return NotificationPage(
      total: items.length,
      limit: limit,
      offset: offset,
      items: items,
    );
  }

  @override
  Future<int> unreadCount() async =>
      items.where((item) => !item.isRead).length;

  @override
  Future<void> markRead(int id) async {
    items = [
      for (final item in items)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  @override
  Future<int> markAllRead() async {
    final count = items.where((item) => !item.isRead).length;
    items = [for (final item in items) item.copyWith(isRead: true)];
    return count;
  }

  @override
  Future<String> issueSocketTicket() async => 'ticket';
}
