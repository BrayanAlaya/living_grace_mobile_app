import 'package:flutter_test/flutter_test.dart';

import 'package:living_grace/data/repositories/mock_auth_repository.dart';
import 'package:living_grace/data/repositories/mock_register_repository.dart';
import 'package:living_grace/main.dart';
import 'package:living_grace/presentation/controllers/auth_controller.dart';
import 'package:living_grace/presentation/controllers/register_controller.dart';

void main() {
  testWidgets('muestra splash y luego el login', (tester) async {
    final authController = AuthController(
      authRepository: MockAuthRepository(
        delay: const Duration(milliseconds: 10),
      ),
    );

    final registerController = RegisterController(
      registerRepository: MockRegisterRepository(
        delay: const Duration(milliseconds: 10),
      ),
    );

    await tester.pumpWidget(
      LivingGraceApp(
        authController: authController,
        registerController: registerController,
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
