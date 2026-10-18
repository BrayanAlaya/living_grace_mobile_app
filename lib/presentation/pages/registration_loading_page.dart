import 'package:flutter/material.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/living_grace_logo.dart';

/// Vista intermedia mientras el servicio de registro responde.
class RegistrationLoadingPage extends StatelessWidget {
  const RegistrationLoadingPage({super.key});

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
            child: AppLoadingIndicator(message: 'Creando tu cuenta...'),
          ),
        ],
      ),
    );
  }
}
