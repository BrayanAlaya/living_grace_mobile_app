import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/session/token_store.dart';
import 'core/theme/app_theme.dart';
import 'login/login_controller.dart';
import 'presentation/app_shell.dart';
import 'register/register_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('API base URL: ${ApiConfig.baseUrl}');

  final tokenStore = TokenStore();
  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenStore: tokenStore,
  );

  runApp(
    LivingGraceApp(
      loginController: LoginController(
        client: apiClient,
        tokenStore: tokenStore,
      ),
      registerController: RegisterController(client: apiClient),
    ),
  );
}

class LivingGraceApp extends StatelessWidget {
  const LivingGraceApp({
    super.key,
    required this.loginController,
    required this.registerController,
  });

  final LoginController loginController;
  final RegisterController registerController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Living Grace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(
        loginController: loginController,
        registerController: registerController,
      ),
    );
  }
}
