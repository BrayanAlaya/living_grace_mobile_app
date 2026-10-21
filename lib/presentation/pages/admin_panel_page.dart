import 'package:flutter/material.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../admin/admin_catalog.dart';
import '../settings/settings_menu.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/settings/settings_section_card.dart';

/// S — compone el panel. Las secciones llegan del catálogo.
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({
    super.key,
    required this.greetingName,
    required this.onBack,
    required this.onItemSelected,
    this.sections = AdminCatalog.sections,
  });

  final String greetingName;
  final VoidCallback onBack;
  final ValueChanged<String> onItemSelected;
  final List<SettingsSection> sections;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.light,
      extendBodyBehindSafeArea: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset + 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminHeader(greetingName: greetingName, onBack: onBack),
            const SizedBox(height: 28),
            for (final section in sections) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SettingsSectionCard(
                  section: section,
                  onItemSelected: onItemSelected,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
