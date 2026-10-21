import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/presentation/pages/settings_page.dart';
import 'package:living_grace/presentation/settings/settings_menu.dart';

void main() {
  testWidgets(
    'ajustes muestra cuenta y administrador, y el atrás va al inicio',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var backTaps = 0;
      var logoutTaps = 0;
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            displayName: 'Jhanpool Curay',
            onBack: () => backTaps++,
            onLogout: () => logoutTaps++,
            onItemSelected: (id) => selected = id,
          ),
        ),
      );

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Jhanpool Curay'), findsOneWidget);
      expect(find.text('Cuenta'), findsOneWidget);
      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Cambiar Contraseña'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Administrador'), findsOneWidget);
      expect(find.text('Panel de Administrador'), findsOneWidget);
      expect(find.text('Gestión de Ministerio'), findsOneWidget);
      expect(find.text('Cerrar Sesión'), findsOneWidget);

      expect(find.text('Privacidad'), findsNothing);
      expect(find.text('Preferencias'), findsNothing);
      expect(find.text('Tema'), findsNothing);
      expect(find.text('Idioma'), findsNothing);
      expect(find.text('Ayuda y Soporte'), findsNothing);
      expect(find.text('Solicitudes'), findsNothing);
      expect(find.text('Ingresar Nueva Solicitud'), findsNothing);

      await tester.tap(find.byTooltip('Inicio'));
      await tester.pump();
      expect(backTaps, 1);

      await tester.tap(find.text('Mi Perfil'));
      await tester.pump();
      expect(selected, SettingsItemId.profile);

      await tester.scrollUntilVisible(find.text('Cerrar Sesión'), 200);
      await tester.tap(find.text('Cerrar Sesión'));
      await tester.pump();
      expect(logoutTaps, 1);
    },
  );

  testWidgets('pinta solo las secciones que recibe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          displayName: 'Ana',
          onBack: () {},
          onLogout: () {},
          onItemSelected: (_) {},
          sections: const [
            SettingsSection(
              id: 'extra',
              title: 'Extra',
              items: [
                SettingsMenuItem(
                  id: 'one',
                  title: 'Opción extra',
                  subtitle: 'Detalle',
                  icon: Icons.star_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('Extra'), findsOneWidget);
    expect(find.text('Opción extra'), findsOneWidget);
    expect(find.text('Cuenta'), findsNothing);
    expect(find.text('Administrador'), findsNothing);
  });
}
