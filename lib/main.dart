import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/session/token_store.dart';
import 'core/theme/app_theme.dart';
import 'login/login_api.dart';
import 'login/login_controller.dart';
import 'login/login_user_mapper.dart';
import 'login/login_validator.dart';
import 'presentation/app_shell.dart';
import 'register/ministry/alabanza_ministry.dart';
import 'register/ministry/ministry_catalog.dart';
import 'register/ministry/produccion_ministry.dart';
import 'register/register_api.dart';
import 'register/register_controller.dart';
import 'register/register_validator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('API base URL: ${ApiConfig.baseUrl}');

  final tokenStore = TokenStore();
  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenStore: tokenStore,
  );

  // Login: solo S — cada clase concreta tiene una responsabilidad.
  final loginController = LoginController(
    validator: LoginValidator(),
    api: LoginApi(client: apiClient),
    mapper: LoginUserMapper(),
    tokenStore: tokenStore,
  );

  // Register: S + O — ministerios nuevos se agregan sin tocar el formulario.
  final ministryCatalog = const MinistryCatalog([
    AlabanzaMinistry(),
    ProduccionMinistry(),
  ]);
  final registerValidator = RegisterValidator();
  final registerController = RegisterController(
    validator: registerValidator,
    api: RegisterApi(client: apiClient),
  );

  runApp(
    LivingGraceApp(
      loginController: loginController,
      registerController: registerController,
      ministryCatalog: ministryCatalog,
      registerValidator: registerValidator,
    ),
  );
}

class LivingGraceApp extends StatelessWidget {
  const LivingGraceApp({
    super.key,
    required this.loginController,
    required this.registerController,
    required this.ministryCatalog,
    required this.registerValidator,
  });

  final LoginController loginController;
  final RegisterController registerController;
  final MinistryCatalog ministryCatalog;
  final RegisterValidator registerValidator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Living Grace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(
        loginController: loginController,
        registerController: registerController,
        ministryCatalog: ministryCatalog,
        registerValidator: registerValidator,
      ),
    );
  }
}
