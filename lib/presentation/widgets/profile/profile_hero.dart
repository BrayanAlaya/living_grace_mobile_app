import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Cabecera del perfil: volver, usuario, foto y nombre.
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.title,
    required this.onBack,
    this.fullName,
    this.role,
    this.onEditPhoto,
  });

  final String title;
  final VoidCallback onBack;
  final String? fullName;
  final String? role;
  final VoidCallback? onEditPhoto;

  static const _avatarSize = 108.0;

  @override
  Widget build(BuildContext context) {
    final name = fullName?.trim();
    final function = role?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderBar(title: title, onBack: onBack),
                const SizedBox(height: _avatarSize / 2),
              ],
            ),
            Positioned(
              bottom: 0,
              child: _ProfileAvatar(
                size: _avatarSize,
                onEditPhoto: onEditPhoto,
              ),
            ),
          ],
        ),
        if (name != null && name.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
          ),
        ],
        if (function != null && function.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              function,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.label,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 56),
          child: Row(
            children: [
              _CircleIconButton(
                tooltip: 'Ajustes',
                icon: Icons.chevron_left_rounded,
                onPressed: onBack,
                backgroundColor: AppColors.inputFill,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 46),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.white,
    this.size = 46,
    this.iconSize = 28,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: AppColors.black),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size, required this.onEditPhoto});

  final double size;
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: ClipOval(
                child: ColoredBox(
                  color: AppColors.inputFill,
                  child: SizedBox.expand(
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppColors.label,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _CircleIconButton(
              tooltip: 'Cambiar foto',
              icon: Icons.photo_camera_outlined,
              onPressed: onEditPhoto,
              size: 34,
              iconSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
