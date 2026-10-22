import 'package:flutter/material.dart';

import '../../core/layouts/home_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../rehearsals/rehearsal_api.dart';
import '../../rehearsals/rehearsal_home_card.dart';
import '../controllers/rehearsal_form_controller.dart';
import '../widgets/panel_drawer.dart';

/// Dashboard principal tras el login (contenido pendiente del diseño).
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.name,
    required this.onOpenSettings,
    required this.onDestinationSelected,
    required this.rehearsalApi,
    this.loadingName = false,
    this.rehearsalFormController,
    this.canManageRehearsals = false,
  });

  /// Nombre de pila del perfil. No usa el usuario de inicio de sesión.
  final String name;
  final bool loadingName;
  final RehearsalApi rehearsalApi;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hola',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.label,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: loadingName
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        height: 1.1,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            RehearsalHomeCard(
              api: rehearsalApi,
              formController: rehearsalFormController,
              canManage: canManageRehearsals,
            ),
          ],
        ),
      ),
    );
  }
}
