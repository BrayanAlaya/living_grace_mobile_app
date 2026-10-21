import 'package:flutter/material.dart';

import '../../domain/entities/user_role.dart';
import 'settings_menu.dart';

/// O — la pantalla pinta esta lista; una opción nueva se agrega aquí.
///
/// Privacidad, Preferencias y Solicitudes no forman parte de Ajustes.
abstract final class SettingsCatalog {
  static const adminSectionId = 'admin';

  static List<SettingsSection> forRole(UserRole role) {
    if (role.isAdmin) return sections;
    return [
      for (final section in sections)
        if (section.id != adminSectionId) section,
    ];
  }

  static const sections = <SettingsSection>[
    SettingsSection(
      id: 'account',
      title: 'Cuenta',
      items: [
        SettingsMenuItem(
          id: SettingsItemId.profile,
          title: 'Mi Perfil',
          subtitle: 'Ver y editar mis datos',
          icon: Icons.person_outline,
        ),
        SettingsMenuItem(
          id: SettingsItemId.password,
          title: 'Cambiar Contraseña',
          subtitle: 'Actualiza tu contraseña',
          icon: Icons.password_outlined,
        ),
        SettingsMenuItem(
          id: SettingsItemId.notifications,
          title: 'Notificaciones',
          subtitle: 'Configura tus notificaciones',
          icon: Icons.notifications_none_outlined,
        ),
      ],
    ),
    SettingsSection(
      id: adminSectionId,
      title: 'Administrador',
      items: [
        SettingsMenuItem(
          id: SettingsItemId.adminPanel,
          title: 'Panel de Administrador',
          subtitle: 'Gestión de Ministerio',
          icon: Icons.storage_outlined,
          emphasis: SettingsItemEmphasis.accent,
        ),
      ],
    ),
  ];
}
