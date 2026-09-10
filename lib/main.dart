import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'data/repositories/mock_register_repository.dart';
import 'presentation/app_shell.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/register_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inyección de dependencias simple (DIP): la UI depende del contrato, no del mock.
  final authRepository = MockAuthRepository();
  final authController = AuthController(authRepository: authRepository);

  final registerRepository = MockRegisterRepository();
  final registerController =
      RegisterController(registerRepository: registerRepository);

  runApp(
    LivingGraceApp(
      authController: authController,
      registerController: registerController,
    ),
  );
}

class LivingGraceApp extends StatelessWidget {
  const LivingGraceApp({
    super.key,
    required this.authController,
    required this.registerController,
  });

  final AuthController authController;
  final RegisterController registerController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Living Grace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(
        authController: authController,
        registerController: registerController,
      ),
    );
  }
}
