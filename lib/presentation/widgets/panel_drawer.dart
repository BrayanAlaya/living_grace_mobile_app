import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PanelMenuDestination {
  const PanelMenuDestination({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Destinos del menú lateral del panel.
abstract final class PanelMenuDestinations {
  static const home = PanelMenuDestination(
    id: 'home',
    label: 'Inicio',
    icon: Icons.home_outlined,
  );

  static const settings = PanelMenuDestination(
    id: 'settings',
    label: 'Ajustes',
    icon: Icons.settings_outlined,
  );

  static const all = <PanelMenuDestination>[home, settings];
}

class PanelDrawer extends StatelessWidget {
  const PanelDrawer({
    super.key,
    required this.currentDestinationId,
    required this.onDestinationSelected,
  });

  final String currentDestinationId;
  final ValueChanged<String> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Menú',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final destination in PanelMenuDestinations.all)
                    ListTile(
                      leading: Icon(
                        destination.icon,
                        color: destination.id == currentDestinationId
                            ? AppColors.black
                            : AppColors.label,
                      ),
                      title: Text(
                        destination.label,
                        style: TextStyle(
                          fontWeight: destination.id == currentDestinationId
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                      selected: destination.id == currentDestinationId,
                      selectedTileColor: AppColors.inputFill,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onDestinationSelected(destination.id);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
