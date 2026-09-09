import 'package:flutter/material.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/living_grace_logo.dart';

/// Primera vista de carga de la app.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.onReady,
    this.duration = const Duration(milliseconds: 2200),
  });

  final VoidCallback onReady;
  final Duration duration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.duration, () {
      if (!mounted) return;
      widget.onReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.dark,
      child: Stack(
        children: [
          const Center(child: LivingGraceLogo()),
          const Align(
            alignment: Alignment(0, 0.55),
            child: AppLoadingIndicator(message: 'Cargando...'),
          ),
        ],
      ),
    );
  }
}
