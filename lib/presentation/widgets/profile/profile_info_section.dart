import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/profile_view_mapper.dart';

/// Tarjeta de datos. [onEdit] muestra el enlace solo en información personal.
class ProfileInfoSection extends StatelessWidget {
  const ProfileInfoSection({
    super.key,
    required this.title,
    required this.fields,
    this.onEdit,
  });

  final String title;
  final List<ProfileFieldData> fields;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                  height: 1.2,
                ),
              ),
            ),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.link,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Editar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
          ],
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
              for (var i = 0; i < fields.length; i++) ...[
                _ProfileFieldTile(field: fields[i]),
                if (i != fields.length - 1)
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

class _ProfileFieldTile extends StatelessWidget {
  const _ProfileFieldTile({required this.field});

  final ProfileFieldData field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(field.icon, color: AppColors.black, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  field.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.label,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
