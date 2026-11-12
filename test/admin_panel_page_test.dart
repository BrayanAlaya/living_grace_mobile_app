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
    expect(find.text('Musica'), findsNothing);
    expect(find.text('Canciones'), findsNothing);
    expect(find.text('Ministerio'), findsOneWidget);
    expect(find.text('Fondos del Ministerio'), findsNothing);
    expect(find.text('Miembros'), findsOneWidget);
    expect(find.text('Control'), findsNothing);
    expect(find.text('Reportes'), findsNothing);
    expect(find.text('Configuración de Multas'), findsNothing);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pump();
    expect(backs, 1);

    await tester.tap(find.text('Programar Ensayos'));
    await tester.pump();
    expect(selected, AdminItemId.scheduleRehearsals);

    await tester.tap(find.text('Generar Código QR'));
    await tester.pump();
    expect(selected, AdminItemId.qrCode);

    await tester.tap(find.text('Miembros'));
    await tester.pump();
    expect(selected, AdminItemId.members);
  });
}
