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
          icon: Icons.code,
          iconColor: AppColors.success,
        ),
      ],
    ),
    SettingsSection(
      id: 'music',
      title: 'Musica',
      items: [
        SettingsMenuItem(
          id: AdminItemId.songs,
          title: 'Canciones',
          subtitle: 'Crear y administrar canciones',
          icon: Icons.music_note_outlined,
          iconColor: AppColors.warning,
        ),
      ],
    ),
    SettingsSection(
      id: 'ministry',
      title: 'Ministerio',
      items: [
        SettingsMenuItem(
          id: AdminItemId.funds,
          title: 'Fondos del Ministerio',
          subtitle: 'Gestionar fondos y contribuciones',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.success,
        ),
        SettingsMenuItem(
          id: AdminItemId.members,
          title: 'Miembros',
          subtitle: 'Administrar miembros del ministerio',
          icon: Icons.people_outline,
          iconColor: AppColors.accent,
        ),
      ],
    ),
    SettingsSection(
      id: 'control',
      title: 'Control',
      items: [
        SettingsMenuItem(
          id: AdminItemId.reports,
          title: 'Reportes',
          subtitle: 'Ver reportes y estadísticas',
          icon: Icons.folder_outlined,
          iconColor: AppColors.warning,
        ),
        SettingsMenuItem(
          id: AdminItemId.fines,
          title: 'Configuración de Multas',
          subtitle: 'Ajustes del ministerio',
          icon: Icons.settings_outlined,
          iconColor: AppColors.black,
        ),
      ],
    ),
  ];
}

abstract final class AdminItemId {
  static const scheduleRehearsals = 'schedule-rehearsals';
  static const attendance = 'attendance';
  static const qrCode = 'qr-code';
  static const songs = 'songs';
  static const funds = 'funds';
  static const members = 'members';
  static const reports = 'reports';
  static const fines = 'fines';
}
