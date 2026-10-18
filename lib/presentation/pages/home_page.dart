import 'package:flutter/material.dart';

import '../../core/layouts/home_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../widgets/panel_drawer.dart';

/// Dashboard principal tras el login (contenido pendiente del diseño).
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.onOpenSettings,
    required this.onDestinationSelected,
  });

  final User user;
  final VoidCallback onOpenSettings;
  final ValueChanged<String> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return HomeLayout(
      currentDestinationId: PanelMenuDestinations.home.id,
      onDestinationSelected: onDestinationSelected,
      onProfilePressed: onOpenSettings,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.label,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: Center(
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
