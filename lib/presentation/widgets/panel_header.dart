import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Header del panel: menú hamburguesa (izquierda) + perfil (derecha).
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.onMenuPressed,
    required this.onProfilePressed,
    this.profileImageUrl,
  });

  final VoidCallback onMenuPressed;
  final VoidCallback onProfilePressed;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HeaderCircleButton(
            onPressed: onMenuPressed,
            child: const Icon(
              Icons.menu_rounded,
              size: 22,
              color: AppColors.black,
            ),
          ),
          _ProfileButton(
            onPressed: onProfilePressed,
            imageUrl: profileImageUrl,
          ),
        ],
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: AppColors.black.withValues(alpha: 0.18),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.onPressed,
    this.imageUrl,
  });

  final VoidCallback onPressed;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: AppColors.black.withValues(alpha: 0.18),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ProfilePlaceholder(),
                  )
                : const _ProfilePlaceholder(),
          ),
        ),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.inputFill,
      child: const Icon(
        Icons.person_rounded,
        size: 26,
        color: AppColors.label,
      ),
    );
  }
}
