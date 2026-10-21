import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Cabecera de Ajustes: volver, título, foto y nombre.
class SettingsHero extends StatelessWidget {
  const SettingsHero({
    super.key,
    required this.displayName,
    required this.onBack,
    this.profileImageUrl,
    this.onEditPhoto,
  });

  final String displayName;
  final VoidCallback onBack;
  final String? profileImageUrl;
  final VoidCallback? onEditPhoto;

  static const _avatarSize = 108.0;

  @override
  Widget build(BuildContext context) {
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
                _HeaderBar(onBack: onBack),
                const SizedBox(height: _avatarSize / 2),
              ],
            ),
            Positioned(
              bottom: 0,
              child: _ProfileAvatar(
                size: _avatarSize,
                imageUrl: profileImageUrl,
                onEditPhoto: onEditPhoto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            displayName,
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
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.onBack});

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
                tooltip: 'Inicio',
                icon: Icons.chevron_left_rounded,
                onPressed: onBack,
              ),
              const Expanded(
                child: Text(
                  'Ajustes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
    this.size = 46,
    this.iconSize = 28,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: AppColors.black.withValues(alpha: 0.18),
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
  const _ProfileAvatar({
    required this.size,
    required this.imageUrl,
    required this.onEditPhoto,
  });

  final double size;
  final String? imageUrl;
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasPhoto = url != null && url.isNotEmpty;

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
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: ColoredBox(
                  color: AppColors.inputFill,
                  child: SizedBox.expand(
                    child: hasPhoto
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _AvatarFallback(),
                          )
                        : const _AvatarFallback(),
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

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.inputFill,
      child: Center(
        child: Icon(Icons.person_rounded, size: 48, color: AppColors.label),
      ),
    );
  }
}
