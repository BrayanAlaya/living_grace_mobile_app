import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'presentation/app_shell.dart';
import 'presentation/controllers/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inyección de dependencias simple (DIP): la UI depende del contrato, no del mock.
  final authRepository = MockAuthRepository();
  final authController = AuthController(authRepository: authRepository);

  runApp(LivingGraceApp(authController: authController));
}

class LivingGraceApp extends StatelessWidget {
  const LivingGraceApp({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Living Grace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(authController: authController),
    );
  }
}
