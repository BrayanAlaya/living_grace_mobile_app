import 'package:flutter/material.dart';

import '../../presentation/widgets/panel_drawer.dart';
import '../../presentation/widgets/panel_header.dart';
import '../theme/app_colors.dart';
import 'app_layout.dart';

/// Layout del panel (home / ajustes / demás secciones autenticadas).
/// Incluye el header con menú lateral y acceso a perfil/ajustes.
class HomeLayout extends StatelessWidget {
  const HomeLayout({
    super.key,
    required this.child,
    required this.currentDestinationId,
    required this.onDestinationSelected,
    required this.onProfilePressed,
    this.profileImageUrl,
  });

  final Widget child;
  final String currentDestinationId;
  final ValueChanged<String> onDestinationSelected;
  final VoidCallback onProfilePressed;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        drawer: PanelDrawer(
          currentDestinationId: currentDestinationId,
          onDestinationSelected: onDestinationSelected,
        ),
        body: Builder(
          builder: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PanelHeader(
                  onMenuPressed: () => Scaffold.of(context).openDrawer(),
                  onProfilePressed: onProfilePressed,
                  profileImageUrl: profileImageUrl,
                ),
                Expanded(child: child),
              ],
            );
          },
        ),
      ),
    );
  }
}
