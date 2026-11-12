import 'package:flutter/material.dart';

import '../../core/layouts/home_layout.dart';
import '../../dashboard/dashboard_api.dart';
import '../../dashboard/dashboard_home.dart';
import '../../rehearsals/rehearsal_api.dart';
import '../controllers/rehearsal_form_controller.dart';
import '../widgets/panel_drawer.dart';

/// Dashboard principal tras el login (`GET /dashboard/me`).
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.name,
    required this.onOpenSettings,
    required this.onDestinationSelected,
    required this.rehearsalApi,
    this.dashboardApi,
    this.loadingName = false,
    this.rehearsalFormController,
    this.canManageRehearsals = false,
  });

  /// Nombre de pila del perfil. No usa el usuario de inicio de sesión.
  final String name;
  final bool loadingName;
  final RehearsalApi rehearsalApi;
  final DashboardApi? dashboardApi;
  final RehearsalFormController? rehearsalFormController;
  final bool canManageRehearsals;
  final VoidCallback onOpenSettings;
  final ValueChanged<String> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return HomeLayout(
      currentDestinationId: PanelMenuDestinations.home.id,
      onDestinationSelected: onDestinationSelected,
      onProfilePressed: onOpenSettings,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: DashboardHome(
          name: name,
          loadingName: loadingName,
          rehearsalApi: rehearsalApi,
          dashboardApi: dashboardApi,
          rehearsalFormController: rehearsalFormController,
          canManageRehearsals: canManageRehearsals,
        ),
      ),
    );
  }
}
