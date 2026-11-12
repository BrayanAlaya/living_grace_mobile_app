import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../notifications/app_notification.dart';
import '../../notifications/notification_controller.dart';
import '../../rehearsals/rehearsal.dart';
import 'app_loading_indicator.dart';

/// Historial de notificaciones: leídas, no leídas y paginación.
class NotificationInbox extends StatefulWidget {
  const NotificationInbox({
    super.key,
    required this.controller,
    required this.onOpen,
    this.compact = false,
  });

  final NotificationController controller;
  final ValueChanged<AppNotification> onOpen;
  final bool compact;

  @override
  State<NotificationInbox> createState() => _NotificationInboxState();
}

class _NotificationInboxState extends State<NotificationInbox> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 80) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notificaciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: state.unreadCount == 0
                          ? null
                          : () => state.markAllRead(),
                      child: const Text('Marcar todas como leídas'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(state)),
          ],
        );
      },
    );
  }

  Widget _body(NotificationController state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(
        child: AppLoadingIndicator(message: 'Cargando notificaciones...'),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No se pudieron cargar las notificaciones.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: state.reload, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return const Center(
        child: Text(
          'No tienes notificaciones.',
          style: TextStyle(color: AppColors.label),
        ),
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16, 0, 16, widget.compact ? 16 : 28),
      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final item = state.items[index];
        return _NotificationTile(
          item: item,
          onTap: () => widget.onOpen(item),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return Material(
      color: unread ? const Color(0xFFF4F6FF) : AppColors.inputFill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: unread ? AppColors.black : AppColors.white,
                child: Icon(
                  _iconFor(item.type),
                  size: 18,
                  color: unread ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.label,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatDayMonth(item.createdAt)} · ${formatTime(item.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 6),
                  child: CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String type) {
  return switch (type) {
    NotificationType.rehearsalAssigned => Icons.event_available_outlined,
    NotificationType.rehearsalUpdated => Icons.edit_calendar_outlined,
    NotificationType.rehearsalCancelled => Icons.event_busy_outlined,
    NotificationType.membershipPending => Icons.person_add_alt_1_outlined,
    NotificationType.membershipApproved => Icons.verified_outlined,
    _ => Icons.notifications_none_outlined,
  };
}
