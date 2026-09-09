import 'package:flutter/material.dart';

import '../../core/layouts/home_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../widgets/living_grace_logo.dart';
import '../widgets/primary_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final User user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return HomeLayout(
      title: 'Inicio',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const LivingGraceLogo(
              livingFontSize: 22,
              graceFontSize: 44,
            ),
            const SizedBox(height: 28),
            Text(
              'Bienvenido, ${user.displayName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.label,
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Cerrar sesión',
              onPressed: onLogout,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
