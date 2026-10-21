import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/settings_menu.dart';

/// Pinta cualquier sección; no conoce destinos concretos.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.section,
    required this.onItemSelected,
  });

  final SettingsSection section;
  final ValueChanged<String> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: AppColors.white,
          elevation: 8,
          shadowColor: const Color(0x33000000),
          surfaceTintColor: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < section.items.length; i++) ...[
                _SettingsMenuTile(
                  item: section.items[i],
                  onTap: () => onItemSelected(section.items[i].id),
                ),
                if (i != section.items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.inputFill,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({required this.item, required this.onTap});

  final SettingsMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = item.emphasis == SettingsItemEmphasis.accent;
    final titleColor = accent ? AppColors.accent : AppColors.black;
    final subtitleColor = accent ? AppColors.accent : AppColors.label;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: item.iconColor ?? AppColors.accent,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
