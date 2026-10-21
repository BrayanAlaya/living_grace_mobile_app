import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/data/models/token_response_dto.dart';
import 'package:living_grace/domain/entities/user_role.dart';
import 'package:living_grace/presentation/pages/settings_page.dart';
import 'package:living_grace/presentation/settings/settings_catalog.dart';

void main() {
  test('sin idRol el login queda en admin', () {
    final token = TokenResponseDto.fromJson({'access_token': 'tok'});

    expect(token.role, UserRole.admin);
  });

  test('idRol 2 es usuario e idRol 1 es admin', () {
    expect(
      TokenResponseDto.fromJson({'access_token': 'tok', 'idRol': 2}).role,
      UserRole.user,
    );
    expect(
      TokenResponseDto.fromJson({'access_token': 'tok', 'idRol': '1'}).role,
      UserRole.admin,
    );
  });

  test('un usuario no ve la card de administración', () {
    final sections = SettingsCatalog.forRole(UserRole.user);
    final titles = sections.map((section) => section.title);

    expect(titles, isNot(contains('Administrador')));
    expect(titles, contains('Cuenta'));
  });

  testWidgets('ajustes de un usuario oculta el panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          displayName: 'Ana',
          sections: SettingsCatalog.forRole(UserRole.user),
          onBack: () {},
          onLogout: () {},
          onItemSelected: (_) {},
        ),
      ),
    );

    expect(find.text('Panel de Administrador'), findsNothing);
    expect(find.text('Mi Perfil'), findsOneWidget);
  });
}
