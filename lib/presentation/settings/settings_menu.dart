import 'package:flutter/widgets.dart';

enum SettingsItemEmphasis { regular, accent }

/// Una fila del menú de ajustes.
class SettingsMenuItem {
  const SettingsMenuItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.emphasis = SettingsItemEmphasis.regular,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final SettingsItemEmphasis emphasis;
}

/// Grupo de filas con un título visible.
class SettingsSection {
  const SettingsSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<SettingsMenuItem> items;
}

abstract final class SettingsItemId {
  static const profile = 'profile';
  static const password = 'password';
  static const notifications = 'notifications';
  static const adminPanel = 'admin-panel';
}
