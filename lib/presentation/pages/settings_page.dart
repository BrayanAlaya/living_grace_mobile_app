import 'package:flutter/material.dart';

import '../../core/layouts/home_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../widgets/panel_drawer.dart';
import '../widgets/primary_button.dart';

/// Pantalla de ajustes (accesible desde el perfil del header).
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onDestinationSelected,
    required this.onOpenSettings,
  });

  final User user;
  final VoidCallback onLogout;
  final ValueChanged<String> onDestinationSelected;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return HomeLayout(
      currentDestinationId: PanelMenuDestinations.settings.id,
      onDestinationSelected: onDestinationSelected,
      onProfilePressed: onOpenSettings,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ajustes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.label,
              ),
            ),
            const SizedBox(height: 28),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: AppColors.black),
              title: Text(user.displayName),
              subtitle: const Text('Perfil'),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Cerrar sesión',
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}
