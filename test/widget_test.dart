import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/core/network/api_client.dart';
import 'package:living_grace/core/session/token_store.dart';
import 'package:living_grace/data/repositories/mock_auth_repository.dart';
import 'package:living_grace/domain/entities/rehearsal_draft.dart';
import 'package:living_grace/domain/entities/user_profile.dart';
import 'package:living_grace/domain/failures/profile_failure.dart';
import 'package:living_grace/domain/failures/rehearsal_failure.dart';
import 'package:living_grace/domain/repositories/profile_repository.dart';
import 'package:living_grace/domain/repositories/rehearsal_repository.dart';
import 'package:living_grace/main.dart';
import 'package:living_grace/presentation/controllers/auth_controller.dart';
import 'package:living_grace/presentation/controllers/profile_controller.dart';
import 'package:living_grace/presentation/controllers/rehearsal_form_controller.dart';
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
        profileController: ProfileController(
          repository: _IdleProfileRepository(),
        ),
        rehearsalFormController: RehearsalFormController(
          repository: _IdleRehearsalRepository(),
        ),
        registerController: _registerController(),
        registerValidator: RegisterValidator(),
      ),
    );

    expect(find.text('Cargando...'), findsOneWidget);
    expect(find.text('Grace'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);

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
      client: ApiClient(baseUrl: 'http://localhost', tokenStore: TokenStore()),
    ),
  );
}

class _IdleRehearsalRepository implements RehearsalRepository {
  @override
  Future<RehearsalFailure?> create(RehearsalDraft draft) async => null;

  @override
  Future<RehearsalFailure?> update(
    int rehearsalId,
    RehearsalDraft draft,
  ) async {
    return null;
  }

  @override
  Future<({List<MinistryMember>? members, RehearsalFailure? failure})>
  listMembers(int ministryId) async {
    return (members: const <MinistryMember>[], failure: null);
  }

  @override
  Future<({List<MinistryOption>? ministries, RehearsalFailure? failure})>
  listMinistries() async {
    return (ministries: const <MinistryOption>[], failure: null);
  }
}

class _IdleProfileRepository implements ProfileRepository {
  @override
  Future<({UserProfile? profile, ProfileFailure? failure})> getMine() async {
    return (profile: null, failure: const ProfileNetworkFailure());
  }
}

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
