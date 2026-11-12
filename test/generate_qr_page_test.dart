import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/attendance/attendance_qr.dart';
import 'package:living_grace/attendance/attendance_qr_api.dart';
import 'package:living_grace/attendance/attendance_qr_display_page.dart';
import 'package:living_grace/attendance/generate_qr_page.dart';
import 'package:living_grace/rehearsals/rehearsal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final rehearsals = [
    _rehearsal(1, 'Ensayo General', 1, 'Alabanza'),
    _rehearsal(2, 'Ensayo de voces', 1, 'Alabanza'),
    _rehearsal(3, 'Coreografía domingo', 2, 'Danza'),
    _rehearsal(4, 'Ensayo de danza', 2, 'Danza'),
    _rehearsal(5, 'Montaje de luces', 3, 'Multimedia'),
  ];

  AttendanceQrApi api() => AttendanceQrApi(
    delay: Duration.zero,
    rehearsals: rehearsals,
  );

  test('filtra por ministerio y pagina el listado', () async {
    final qrApi = api();

    final all = await qrApi.listRehearsals(page: 1, pageSize: 2);
    expect(all.items, hasLength(2));
    expect(all.total, 5);
    expect(all.totalPages, 3);
    expect(all.items.first.name, 'Ensayo General');
    expect(all.ministries.map((m) => m.name), [
      'Alabanza',
      'Danza',
      'Multimedia',
    ]);

    final page2 = await qrApi.listRehearsals(page: 2, pageSize: 2);
    expect(page2.items.first.name, 'Coreografía domingo');

    final danza = await qrApi.listRehearsals(
      ministryId: 2,
      page: 1,
      pageSize: 5,
    );
    expect(danza.items, hasLength(2));
    expect(danza.items.every((item) => item.ministryName == 'Danza'), isTrue);
  });

  test('simula la generación del QR con vigencia de tolerancia', () async {
    final qr = await api().generate(rehearsals.first);
    expect(qr.payload, contains('rehearsalId=1'));
    expect(qr.expiresAt.difference(qr.generatedAt), const Duration(minutes: 10));
    expect(
      formatToleranceRemaining(const Duration(minutes: 7, seconds: 42)),
      '07 min 42 seg',
    );
  });

  testWidgets('lista, filtra, pagina y muestra el QR al confirmar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GenerateQrPage(
          onBack: () => backs++,
          qrApi: api(),
          pageSize: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Generar Código QR'), findsOneWidget);
    expect(find.text('Filtrar por ministerio'), findsOneWidget);

    await tester.tap(find.byTooltip('Administración'));
    await tester.pump();
    expect(backs, 1);

    expect(find.text('Ensayo General'), findsOneWidget);
    expect(find.text('Ensayo de voces'), findsOneWidget);
    expect(find.text('Coreografía domingo'), findsNothing);
    expect(find.text('Página 1 de 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Coreografía domingo'), findsOneWidget);
    expect(find.text('Página 2 de 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ministry-2')));
    await tester.pumpAndSettle();
    expect(find.text('Coreografía domingo'), findsOneWidget);
    expect(find.text('Ensayo de danza'), findsOneWidget);
    expect(find.text('Ensayo General'), findsNothing);
    expect(find.text('Página 1 de 1'), findsOneWidget);

    await tester.tap(find.text('Coreografía domingo'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '¿Generar el código de asistencia para "Coreografía domingo" de Danza?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar'), findsNothing);

    await tester.tap(find.text('Coreografía domingo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Generar'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AttendanceQrDisplayPage), findsOneWidget);
    expect(find.text('Registrar'), findsOneWidget);
    expect(find.text('Escanea el Código QR\nde ensayo'), findsOneWidget);
    expect(find.text('Código generado'), findsOneWidget);
    expect(find.text('Coreografía domingo'), findsWidgets);
    expect(find.text('Danza'), findsWidgets);
    expect(find.textContaining('Tolerancia restante:'), findsOneWidget);
  });
}

Rehearsal _rehearsal(int id, String name, int ministryId, String ministry) {
  return Rehearsal(
    id: id,
    name: name,
    description: null,
    ministryId: ministryId,
    ministryName: ministry,
    leaderName: 'Luis Rey',
    startAt: DateTime(2026, 11, 14, 17),
    endAt: DateTime(2026, 11, 14, 19),
    toleranceMinutes: 10,
  );
}
