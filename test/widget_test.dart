import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/core/network/api_client.dart';
import 'package:living_grace/core/session/token_store.dart';
import 'package:living_grace/data/repositories/mock_auth_repository.dart';
import 'package:living_grace/main.dart';
import 'package:living_grace/presentation/controllers/auth_controller.dart';
import 'package:living_grace/register/ministry/alabanza_ministry.dart';
import 'package:living_grace/register/ministry/ministry_catalog.dart';
import 'package:living_grace/register/ministry/produccion_ministry.dart';
import 'package:living_grace/register/register_api.dart';
import 'package:living_grace/register/register_controller.dart';
import 'package:living_grace/register/register_validator.dart';

void main() {
  testWidgets('muestra splash y luego el login', (tester) async {
    final authController = AuthController(
      authRepository: MockAuthRepository(
        delay: const Duration(milliseconds: 10),
      ),
    );

    await tester.pumpWidget(
      LivingGraceApp(
        authController: authController,
        registerController: _registerController(),
        ministryCatalog: _ministryCatalog,
        registerValidator: RegisterValidator(),
      ),
    );

    expect(find.text('Cargando...'), findsOneWidget);
    expect(find.text('Grace'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('E-mail o Usuario'), findsOneWidget);

    _tapSpan(tester, 'Regístrate');
    await tester.pumpAndSettle();

    expect(find.text('Datos Personales'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);
  });
}

RegisterController _registerController() {
  return RegisterController(
    validator: RegisterValidator(),
    api: RegisterApi(
      client: ApiClient(
        baseUrl: 'http://localhost',
        tokenStore: TokenStore(),
      ),
    ),
  );
}

const _ministryCatalog = MinistryCatalog([
  AlabanzaMinistry(),
  ProduccionMinistry(),
]);

void _tapSpan(WidgetTester tester, String label) {
  final richText = tester.widget<RichText>(
    find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().contains(label),
    ),
  );

  var tapped = false;
  void visit(InlineSpan span) {
    if (span is! TextSpan) return;
    if (span.text == label && span.recognizer is TapGestureRecognizer) {
      (span.recognizer as TapGestureRecognizer).onTap?.call();
      tapped = true;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      visit(child);
    }
  }

  visit(richText.text);
  expect(tapped, isTrue, reason: 'No se encontró el enlace $label');
}
