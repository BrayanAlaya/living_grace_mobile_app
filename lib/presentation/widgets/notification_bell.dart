import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../notifications/app_notification.dart';
import '../../notifications/notification_controller.dart';
import 'notification_inbox.dart';

/// Campana del encabezado con contador de no leídas.
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  final NotificationController controller;
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final count = controller.unreadCount;
        return Tooltip(
          message: 'Notificaciones',
          child: Material(
            color: AppColors.white,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: AppColors.black.withValues(alpha: 0.18),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showNotificationInbox(
                context: context,
                controller: controller,
                onOpen: onOpen,
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: AppColors.black,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: _Badge(count: count),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: label.length > 1 ? 4 : 5,
          vertical: 2,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Future<void> showNotificationInbox({
  required BuildContext context,
  required NotificationController controller,
  required ValueChanged<AppNotification> onOpen,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: NotificationInbox(
            controller: controller,
            compact: true,
            onOpen: (item) async {
              await controller.markRead(item.id);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              onOpen(item);
            },
          ),
        ),
      );
    },
  );
}
