import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/session/token_store.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/http_auth_remote_datasource.dart';
import 'data/datasources/http_profile_remote_datasource.dart';
import 'data/datasources/http_rehearsal_remote_datasource.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/api_profile_repository.dart';
import 'data/repositories/api_rehearsal_repository.dart';
import 'data/session/in_memory_token_store.dart';
import 'presentation/app_shell.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/profile_controller.dart';
import 'presentation/controllers/rehearsal_form_controller.dart';
import 'register/register_api.dart';
import 'register/register_controller.dart';
import 'register/register_validator.dart';
import 'rehearsals/rehearsal_api.dart';

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
  final profileController = ProfileController(
    repository: ApiProfileRepository(
      remoteDataSource: HttpProfileRemoteDataSource(tokenStore: tokenStore),
    ),
  );
  final rehearsalFormController = RehearsalFormController(
    repository: ApiRehearsalRepository(
      remoteDataSource: HttpRehearsalRemoteDataSource(tokenStore: tokenStore),
    ),
  );

  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenStore: TokenStore(),
  );
  final registerValidator = RegisterValidator();
  final registerController = RegisterController(
    validator: registerValidator,
    api: RegisterApi(client: apiClient),
  );

  runApp(
    LivingGraceApp(
      authController: authController,
      profileController: profileController,
      rehearsalFormController: rehearsalFormController,
      registerController: registerController,
      registerValidator: registerValidator,
      rehearsalApi: RehearsalApi(tokenStore: tokenStore),
    ),
  );
}

class LivingGraceApp extends StatelessWidget {
  const LivingGraceApp({
    super.key,
    required this.authController,
    required this.profileController,
    required this.rehearsalFormController,
    required this.registerController,
    required this.registerValidator,
    this.rehearsalApi,
  });

  final AuthController authController;
  final ProfileController profileController;
  final RehearsalFormController rehearsalFormController;
  final RegisterController registerController;
  final RegisterValidator registerValidator;
  final RehearsalApi? rehearsalApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Living Grace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(
        authController: authController,
        profileController: profileController,
        rehearsalFormController: rehearsalFormController,
        registerController: registerController,
        registerValidator: registerValidator,
        rehearsalApi:
            rehearsalApi ?? RehearsalApi(tokenStore: InMemoryTokenStore()),
      ),
    );
  }
}
