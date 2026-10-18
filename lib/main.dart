import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/http_auth_remote_datasource.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/session/in_memory_token_store.dart';
import 'presentation/app_shell.dart';
import 'presentation/controllers/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // DIP: la UI solo conoce AuthRepository / AuthController.
  final tokenStore = InMemoryTokenStore();
  final authRemote = HttpAuthRemoteDataSource();
  final authRepository = ApiAuthRepository(
    remoteDataSource: authRemote,
    tokenStore: tokenStore,
  );
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
