import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/domain/entities/user_profile.dart';
import 'package:living_grace/domain/failures/profile_failure.dart';
import 'package:living_grace/presentation/pages/profile_page.dart';
import 'package:living_grace/presentation/profile/profile_view_mapper.dart';

void main() {
  const profile = UserProfile(
    firstName: 'Jhanpool',
    lastName: 'Curay',
    email: 'jhanpool.curay17@outlook.com',
    phone: '980985755',
    birthDate: '1999-09-23',
    createdAt: '2026-08-12T12:00:00',
    memberships: [
      ProfileMembership(ministry: 'Alabanza', functions: ['Guitarrista']),
      ProfileMembership(ministry: 'Producción', functions: ['Guitarrista']),
    ],
  );

  testWidgets('muestra los datos de GET /users/me y el atrás vuelve', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var backs = 0;
    var edits = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          headerTitle: 'JhanC17',
          isLoading: false,
          data: ProfileViewMapper.map(profile, username: 'JhanC17'),
          onBack: () => backs++,
          onRetry: () {},
          onEdit: () => edits++,
        ),
      ),
    );

    expect(find.text('JhanC17'), findsWidgets);
    expect(find.text('Jhanpool Curay'), findsWidgets);
    expect(find.text('Guitarrista'), findsOneWidget);
    expect(find.text('Información Personal'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('jhanpool.curay17@outlook.com'), findsOneWidget);
    expect(find.text('980985755'), findsOneWidget);
    expect(find.text('23 de Septiembre de 1999'), findsOneWidget);
    expect(find.text('12 de Agosto de 2026'), findsOneWidget);
    expect(find.text('Información Adicional'), findsOneWidget);
    expect(find.text('Alabanza / Producción'), findsOneWidget);
    expect(find.text('Nombre de Usuario'), findsOneWidget);

    expect(find.text('Dirección'), findsNothing);
    expect(find.text('Género'), findsNothing);
    expect(find.text('Instrumento Principal'), findsNothing);
    expect(find.text('Descripción'), findsNothing);
    expect(find.text('Activo'), findsNothing);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pump();
    expect(backs, 1);

    await tester.tap(find.text('Editar'));
    await tester.pump();
    expect(edits, 1);
  });

  testWidgets('muestra la carga y el error con reintento', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          headerTitle: 'JhanC17',
          isLoading: true,
          onBack: () {},
          onRetry: () => retries++,
        ),
      ),
    );

    expect(find.text('Cargando perfil...'), findsOneWidget);
    expect(find.text('Información Personal'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(
          headerTitle: 'JhanC17',
          isLoading: false,
          failure: ProfileNetworkFailure(),
          onBack: _noop,
          onRetry: _noop,
        ),
      ),
    );

    expect(
      find.text('No pudimos cargar tu perfil. Intenta de nuevo.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          headerTitle: 'JhanC17',
          isLoading: false,
          failure: const ProfileNetworkFailure(),
          onBack: () {},
          onRetry: () => retries++,
        ),
      ),
    );
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(retries, 1);
  });
}

void _noop() {}
