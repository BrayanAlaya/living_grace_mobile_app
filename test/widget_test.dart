import 'package:flutter_test/flutter_test.dart';

import 'package:living_grace/core/network/api_client.dart';
import 'package:living_grace/core/session/token_store.dart';
import 'package:living_grace/login/login_api.dart';
import 'package:living_grace/login/login_controller.dart';
import 'package:living_grace/login/login_user_mapper.dart';
import 'package:living_grace/login/login_validator.dart';
import 'package:living_grace/main.dart';
import 'package:living_grace/register/ministry/alabanza_ministry.dart';
import 'package:living_grace/register/ministry/ministry_catalog.dart';
import 'package:living_grace/register/ministry/produccion_ministry.dart';
import 'package:living_grace/register/register_api.dart';
import 'package:living_grace/register/register_controller.dart';
import 'package:living_grace/register/register_validator.dart';

void main() {
  testWidgets('muestra splash y luego el login', (tester) async {
    final tokenStore = TokenStore();
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: tokenStore,
    );
    final loginController = LoginController(
      validator: LoginValidator(),
      api: LoginApi(client: apiClient),
      mapper: LoginUserMapper(),
      tokenStore: tokenStore,
    );
    final registerValidator = RegisterValidator();
    final registerController = RegisterController(
      validator: registerValidator,
      api: RegisterApi(client: apiClient),
    );

    await tester.pumpWidget(
      LivingGraceApp(
        loginController: loginController,
        registerController: registerController,
        ministryCatalog: const MinistryCatalog([
          AlabanzaMinistry(),
          ProduccionMinistry(),
        ]),
        registerValidator: registerValidator,
      ),
    );

    expect(find.text('Cargando...'), findsOneWidget);
    expect(find.text('Grace'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('E-mail o Usuario'), findsOneWidget);
  });
}
