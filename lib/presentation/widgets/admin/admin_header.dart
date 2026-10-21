import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Cabecera del panel: volver, título, foto y saludo.
class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.greetingName,
    required this.onBack,
  });

  final String greetingName;
  final VoidCallback onBack;

  static const _avatarSize = 86.0;

  @override
  Widget build(BuildContext context) {
    final name = greetingName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _AdminBar(onBack: onBack),
            const Positioned(
              right: 22,
              bottom: -_avatarSize / 2,
              child: _AdminAvatar(size: _avatarSize),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 120, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.label,
                ),
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                    height: 1.1,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              const Text(
                'Administrador',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.label,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminBar extends StatelessWidget {
  const _AdminBar({required this.onBack});

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 44),
          child: Row(
            children: [
              _CircleButton(onPressed: onBack),
              const Expanded(
                child: Text(
                  'Administración',
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ajustes',
      child: Material(
        color: AppColors.inputFill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.size});

  final double size;

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
                        size: 40,
                        color: AppColors.label,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
