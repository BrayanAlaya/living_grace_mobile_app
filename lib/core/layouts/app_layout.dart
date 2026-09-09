import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Layout raíz: envuelve toda la app (status bar, fondo, safe area).
class AppLayout extends StatelessWidget {
  const AppLayout({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.white,
    this.statusBarBrightness = Brightness.dark,
    this.extendBodyBehindSafeArea = false,
  });

  final Widget child;
  final Color backgroundColor;
  final Brightness statusBarBrightness;
  final bool extendBodyBehindSafeArea;

  @override
  Widget build(BuildContext context) {
    final overlay = statusBarBrightness == Brightness.light
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: extendBodyBehindSafeArea
            ? child
            : SafeArea(child: child),
      ),
    );
  }
}
