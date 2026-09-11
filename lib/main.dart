import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/session/token_store.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/living_grace_api.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/api_register_repository.dart';
import 'presentation/app_shell.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/register_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('API base URL: ${ApiConfig.baseUrl}');

  final tokenStore = TokenStore();
  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenStore: tokenStore,
  );
  final api = LivingGraceApi(client: apiClient);

  final authRepository = ApiAuthRepository(
    api: api,
    tokenStore: tokenStore,
  );
  final authController = AuthController(authRepository: authRepository);

  final registerRepository = ApiRegisterRepository(api: api);
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
