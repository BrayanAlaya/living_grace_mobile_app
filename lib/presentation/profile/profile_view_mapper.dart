import 'package:flutter/material.dart';

import '../../domain/entities/user_profile.dart';
import 'profile_date_format.dart';

class ProfileFieldData {
  const ProfileFieldData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class ProfileViewData {
  const ProfileViewData({
    required this.fullName,
    required this.personal,
    required this.additional,
    this.role,
  });

  final String fullName;
  final String? role;
  final List<ProfileFieldData> personal;
  final List<ProfileFieldData> additional;
}

/// Arma las filas visibles a partir de GET /users/me.
///
/// Dirección, género, instrumento, descripción y estado no vienen en UserProfile.
abstract final class ProfileViewMapper {
  static const emptyValue = '—';

  static ProfileViewData map(UserProfile profile, {String? username}) {
    final additional = <ProfileFieldData>[
      ProfileFieldData(
        icon: Icons.account_balance_outlined,
        label: 'Ministerio',
        value: _ministries(profile),
      ),
    ];

    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) {
      additional.add(
        ProfileFieldData(
          icon: Icons.person_outline,
          label: 'Nombre de Usuario',
          value: handle,
        ),
      );
    }

    return ProfileViewData(
      fullName: profile.fullName,
      role: _role(profile),
      personal: [
        ProfileFieldData(
          icon: Icons.person_outline,
          label: 'Nombres y Apellidos',
          value: _text(profile.fullName),
        ),
        ProfileFieldData(
          icon: Icons.mail_outline,
          label: 'Correo Electrónico',
          value: _text(profile.email),
        ),
        ProfileFieldData(
          icon: Icons.phone_outlined,
          label: 'Teléfono',
          value: _text(profile.phone),
        ),
        ProfileFieldData(
          icon: Icons.calendar_today_outlined,
          label: 'Fecha de Nacimiento',
          value:
              ProfileDateFormat.calendarDate(profile.birthDate) ?? emptyValue,
        ),
        ProfileFieldData(
          icon: Icons.calendar_today_outlined,
          label: 'Fecha de Registro',
          value:
              ProfileDateFormat.dateTime(profile.createdAt) ??
              profile.createdAt,
        ),
      ],
      additional: additional,
    );
  }

  static String? _role(UserProfile profile) {
    final seen = <String>{};
    final labels = <String>[];
    for (final membership in profile.memberships) {
      for (final function in membership.functions) {
        final label = function.trim();
        if (label.isEmpty) continue;
        if (seen.add(label.toLowerCase())) labels.add(label);
      }
    }
    if (labels.isEmpty) return null;
    return labels.join(' · ');
  }

  static String _ministries(UserProfile profile) {
    final names = <String>[];
    final seen = <String>{};
    for (final membership in profile.memberships) {
      final name = membership.ministry.trim();
      if (name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) names.add(name);
    }
    if (names.isEmpty) return emptyValue;
    return names.join(' / ');
  }

  static String _text(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? emptyValue : text;
  }
}
