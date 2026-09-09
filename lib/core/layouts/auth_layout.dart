import 'package:flutter/material.dart';

import '../../presentation/widgets/living_grace_logo.dart';
import '../theme/app_colors.dart';
import 'app_layout.dart';

/// Layout de autenticación: cabecera negra + panel blanco con curva superior izquierda.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.headerFlex = 4,
    this.bodyFlex = 6,
  });

  final Widget child;
  final int headerFlex;
  final int bodyFlex;

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      backgroundColor: AppColors.black,
      statusBarBrightness: Brightness.light,
      extendBodyBehindSafeArea: true,
      child: Column(
        children: [
          Expanded(
            flex: headerFlex,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: LivingGraceLogo(
                  color: AppColors.white,
                  livingFontSize: 26,
                  graceFontSize: 52,
                ),
              ),
            ),
          ),
          Expanded(
            flex: bodyFlex,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(72),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
