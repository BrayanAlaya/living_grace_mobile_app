import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:living_grace/core/network/api_client.dart';
import 'package:living_grace/core/session/token_store.dart';
import 'package:living_grace/domain/entities/register_data.dart';
import 'package:living_grace/domain/failures/register_failure.dart';
import 'package:living_grace/presentation/pages/register_page.dart';
import 'package:living_grace/register/ministry/ministry_catalog.dart';
import 'package:living_grace/register/ministry/ministry_definition.dart';
import 'package:living_grace/register/ministry/service_area.dart';
import 'package:living_grace/register/register_api.dart';
import 'package:living_grace/register/register_validator.dart';

void main() {
  test('lee los servicios de cada ministerio', () {
    final ministry = MinistryDefinition.fromJson({
      'id': 2,
      'name': 'Alabanza',
      'description': null,
      'functions': ['Voz'],
      'function_options': [
        {'id': 8, 'name': 'Voz'},
        {'id': 9, 'name': 'Guitarra'},
      ],
    });

    expect(ministry.id, 2);
    expect(ministry.serviceAreas.map((area) => area.name), ['Voz', 'Guitarra']);
    expect(
      const MinistryCatalog([MinistryDefinition(id: 2, name: 'Alabanza')])
          .areasFor(1),
      isEmpty,
    );
  });

  test('el registro envia el ministerio y el servicio elegidos', () async {
    late Map<String, dynamic> body;
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/users/register');
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'id': 1,
          'email': 'ana@grace.test',
          'first_name': 'Ana',
          'last_name': 'Paz',
          'phone': '987654321',
          'birth_date': '2000-01-02',
          'status': 'ACTIVE',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
          'deleted_at': null,
        }),
        201,
      );
    });

    final api = RegisterApi(
      client: ApiClient(
        baseUrl: 'https://api.test',
        tokenStore: TokenStore(),
        httpClient: client,
      ),
    );

    await api.register(
      const RegisterData(
        firstName: 'Ana',
        lastName: 'Paz',
        phone: '987654321',
        birthDate: '2000-01-02',
        email: 'ana@grace.test',
        ministryId: 2,
        serviceAreaId: 8,
        password: 'secreto12',
        confirmPassword: 'secreto12',
      ),
    );

    expect(body.containsKey('username'), isFalse);
    expect(body['memberships'], [
      {
        'ministry_id': 2,
        'function_ids': [8],
      },
    ]);
  });

  testWidgets('cambiar de ministerio actualiza sus servicios', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(
          catalog: MinistryCatalog([
            MinistryDefinition(
              id: 1,
              name: 'Alabanza',
              serviceAreas: const [
                ServiceArea(id: 8, name: 'Voz'),
                ServiceArea(id: 9, name: 'Guitarra'),
              ],
            ),
            const MinistryDefinition(
              id: 2,
              name: 'Producción',
              serviceAreas: [ServiceArea(id: 20, name: 'Audio')],
            ),
          ]),
          validator: RegisterValidator(),
          initialStep: 1,
          onSubmit: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _choose(tester, 'Alabanza');
    await _openServices(tester);

    expect(find.text('Voz'), findsOneWidget);
    expect(find.text('Guitarra'), findsOneWidget);
    expect(find.text('Audio'), findsNothing);

    await tester.tap(find.text('Voz'));
    await tester.pumpAndSettle();
    await _choose(tester, 'Producción');
    await _openServices(tester);

    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Voz'), findsNothing);
    expect(find.text('Guitarra'), findsNothing);
  });

  testWidgets('volver conserva las credenciales y regresa al primer paso', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const failure = RegisterValidationFailure('Ese correo ya está registrado.');
    late StateSetter refresh;
    RegisterFailure? shown;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            refresh = setState;
            return RegisterPage(
              catalog: const MinistryCatalog([]),
              validator: RegisterValidator(),
              initialStep: 1,
              failure: shown,
              onSubmit: (_) async {},
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'clave1234');
    await tester.pump();

    refresh(() => shown = failure);
    await tester.pump();

    expect(find.text('Ese correo ya está registrado.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'clave1234',
    );

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();

    expect(find.text('Datos Personales'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });
}

Future<void> _choose(WidgetTester tester, String name) async {
  final opener = find.byIcon(Icons.keyboard_arrow_down_rounded).first;
  await tester.ensureVisible(opener);
  await tester.tap(opener);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _openServices(WidgetTester tester) async {
  final opener = find.byIcon(Icons.keyboard_arrow_down_rounded).last;
  await tester.ensureVisible(opener);
  await tester.tap(opener);
  await tester.pumpAndSettle();
}
