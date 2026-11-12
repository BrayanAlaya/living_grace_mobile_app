import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../settings/settings_menu.dart';

/// O — el panel pinta esta lista; una opción nueva se agrega aquí.
abstract final class AdminCatalog {
  static const sections = <SettingsSection>[
    SettingsSection(
      id: 'rehearsals',
      title: 'Ensayos',
      items: [
        SettingsMenuItem(
          id: AdminItemId.scheduleRehearsals,
          title: 'Programar Ensayos',
          subtitle: 'Crear y gestionar Ensayos',
          icon: Icons.add_circle_outline,
          iconColor: AppColors.error,
        ),
        SettingsMenuItem(
          id: AdminItemId.attendance,
          title: 'Asistencia',
          subtitle: 'Gestionar asistencias, tardanzas e inasistencias',
          icon: Icons.calendar_month_outlined,
          iconColor: AppColors.accent,
        ),
        SettingsMenuItem(
          id: AdminItemId.qrCode,
          title: 'Generar Código QR',
          subtitle: 'Generar códigos para asistencia',
          icon: Icons.qr_code_2_outlined,
          iconColor: AppColors.success,
        ),
      ],
    ),
    SettingsSection(
      id: 'ministry',
      title: 'Ministerio',
      items: [
        SettingsMenuItem(
          id: AdminItemId.members,
          title: 'Miembros',
          subtitle: 'Administrar miembros del ministerio',
          icon: Icons.people_outline,
          iconColor: AppColors.accent,
        ),
      ],
    ),
  ];
}

abstract final class AdminItemId {
  static const scheduleRehearsals = 'schedule-rehearsals';
  static const attendance = 'attendance';
  static const qrCode = 'qr-code';
  static const members = 'members';
}
