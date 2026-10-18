import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/session/token_store.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/http_auth_remote_datasource.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/session/in_memory_token_store.dart';
import 'presentation/app_shell.dart';
import 'presentation/controllers/auth_controller.dart';
import 'register/ministry/alabanza_ministry.dart';
import 'register/ministry/ministry_catalog.dart';
import 'register/ministry/produccion_ministry.dart';
import 'register/register_api.dart';
import 'register/register_controller.dart';
import 'register/register_validator.dart';

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

  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenStore: TokenStore(),
  );
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
      authController: authController,
      registerController: registerController,
      ministryCatalog: ministryCatalog,
      registerValidator: registerValidator,
    ),
  );
}

class LivingGraceApp extends StatelessWidget {
  const LivingGraceApp({
    super.key,
    required this.authController,
    required this.registerController,
    required this.ministryCatalog,
    required this.registerValidator,
  });

  final AuthController authController;
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
        authController: authController,
        registerController: registerController,
        ministryCatalog: ministryCatalog,
        registerValidator: registerValidator,
      ),
    );
  }
}
