import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/presentation/pages/change_password_page.dart';
import 'package:living_grace/presentation/pages/forgot_password_page.dart';
import 'package:living_grace/presentation/pages/login_page.dart';

void main() {
  testWidgets('olvidé mi contraseña pide clave temporal y la nueva', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? capturedEmail;
    String? capturedTemporary;
    String? capturedNext;
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          onBack: () {},
          onSubmit: ({
            required identifier,
            required temporaryPassword,
            required newPassword,
          }) async {
            capturedEmail = identifier;
            capturedTemporary = temporaryPassword;
            capturedNext = newPassword;
            return null;
          },
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'ana@livinggrace.com');
    await tester.enterText(fields.at(1), 'Temp#99');
    await tester.enterText(fields.at(2), 'NuevaClave8');
    await tester.enterText(fields.at(3), 'NuevaClave8');
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pump();

    expect(capturedEmail, 'ana@livinggrace.com');
    expect(capturedTemporary, 'Temp#99');
    expect(capturedNext, 'NuevaClave8');
  });

  testWidgets('el login abre olvide mi contraseña', (tester) async {
    var forgot = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onSubmit: (_, _) async {},
          onForgotPassword: () => forgot++,
        ),
      ),
    );

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    expect(forgot, 1);
  });

  testWidgets('cambiar contraseña envía actual y nueva', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? current;
    String? next;
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(
          onBack: () {},
          onSubmit: ({required currentPassword, required newPassword}) async {
            current = currentPassword;
            next = newPassword;
            return null;
          },
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'vieja1234');
    await tester.enterText(fields.at(1), 'NuevaClave8');
    await tester.enterText(fields.at(2), 'NuevaClave8');
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(current, 'vieja1234');
    expect(next, 'NuevaClave8');
  });
}
