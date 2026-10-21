import 'package:flutter/material.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../settings/settings_catalog.dart';
import '../settings/settings_menu.dart';
import '../widgets/settings/settings_hero.dart';
import '../widgets/settings/settings_logout_button.dart';
import '../widgets/settings/settings_section_card.dart';

/// S — compone Ajustes. La navegación llega por callbacks.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.displayName,
    required this.onBack,
    required this.onLogout,
    required this.onItemSelected,
    this.onEditPhoto,
    this.profileImageUrl,
    this.sections = SettingsCatalog.sections,
  });

  final String displayName;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final ValueChanged<String> onItemSelected;
  final VoidCallback? onEditPhoto;
  final String? profileImageUrl;
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
            SettingsHero(
              displayName: displayName,
              onBack: onBack,
              profileImageUrl: profileImageUrl,
              onEditPhoto: onEditPhoto,
            ),
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
            const SizedBox(height: 8),
            SettingsLogoutButton(onPressed: onLogout),
          ],
        ),
      ),
    );
  }
}
