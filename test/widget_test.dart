import 'package:flutter_test/flutter_test.dart';

import 'package:living_grace/core/network/api_client.dart';
import 'package:living_grace/core/session/token_store.dart';
import 'package:living_grace/login/login_controller.dart';
import 'package:living_grace/main.dart';
import 'package:living_grace/register/register_controller.dart';

void main() {
  testWidgets('muestra splash y luego el login', (tester) async {
    final tokenStore = TokenStore();
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: tokenStore,
    );

    await tester.pumpWidget(
      LivingGraceApp(
        loginController: LoginController(
          client: apiClient,
          tokenStore: tokenStore,
        ),
        registerController: RegisterController(client: apiClient),
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
