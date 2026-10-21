import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/presentation/admin/admin_catalog.dart';
import 'package:living_grace/presentation/pages/admin_panel_page.dart';

void main() {
  testWidgets('el panel muestra las secciones y el atrás vuelve a ajustes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var backs = 0;
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: AdminPanelPage(
          greetingName: 'Jhanpool',
          onBack: () => backs++,
          onItemSelected: (id) => selected = id,
        ),
      ),
    );

    expect(find.text('Administración'), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Jhanpool'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('Ensayos'), findsOneWidget);
    expect(find.text('Programar Ensayos'), findsOneWidget);
    expect(find.text('Asistencia'), findsOneWidget);
    expect(find.text('Generar Código QR'), findsOneWidget);
    expect(find.text('Musica'), findsOneWidget);
    expect(find.text('Canciones'), findsOneWidget);
    expect(find.text('Ministerio'), findsOneWidget);
    expect(find.text('Fondos del Ministerio'), findsOneWidget);
    expect(find.text('Miembros'), findsOneWidget);
    expect(find.text('Control'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);
    expect(find.text('Configuración de Multas'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pump();
    expect(backs, 1);

    await tester.tap(find.text('Programar Ensayos'));
    await tester.pump();
    expect(selected, AdminItemId.scheduleRehearsals);

    await tester.scrollUntilVisible(find.text('Configuración de Multas'), 300);
    await tester.tap(find.text('Configuración de Multas'));
    await tester.pump();
    expect(selected, AdminItemId.fines);
  });
}
