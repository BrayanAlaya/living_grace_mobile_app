import 'package:flutter/material.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../notifications/app_notification.dart';
import '../../notifications/notification_controller.dart';
import '../widgets/notification_inbox.dart';
import '../../rehearsals/rehearsal_widgets.dart';

/// Historial completo desde Ajustes.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onOpen,
  });

  final NotificationController controller;
  final VoidCallback onBack;
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.dark,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CircleIconButton(
                icon: Icons.chevron_left_rounded,
                onPressed: onBack,
              ),
            ),
          ),
          Expanded(
            child: NotificationInbox(
              controller: controller,
              onOpen: (item) async {
                await controller.markRead(item.id);
                onOpen(item);
              },
            ),
          ),
        ],
      ),
    );
  }
}
