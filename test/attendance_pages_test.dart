import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/attendance/admin_attendance_page.dart';
import 'package:living_grace/attendance/attendance_home_card.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/domain/entities/rehearsal_draft.dart';
import 'package:living_grace/presentation/pages/home_page.dart';
import 'package:living_grace/rehearsals/rehearsal.dart';
import 'package:living_grace/rehearsals/rehearsal_api.dart';

void main() {
  testWidgets('el dashboard muestra la sección de asistencias', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          name: 'Ana',
          onOpenSettings: () {},
          onDestinationSelected: (_) {},
          rehearsalApi: _EmptyRehearsalApi(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ensayos'), findsOneWidget);
    expect(find.text('Asistencias'), findsOneWidget);
    expect(find.text('No hay ensayos programados.'), findsOneWidget);
    expect(find.text('Aún no hay asistencias registradas.'), findsOneWidget);
  });

  testWidgets('el historial maqueta se abre desde asistencias', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AttendanceHomeCard())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Última asistencia'));
    await tester.pumpAndSettle();

    expect(find.text('Asistencias'), findsWidgets);
    expect(find.text('Presente'), findsWidgets);
    expect(find.text('Tarde'), findsOneWidget);
    expect(find.text('Ausente'), findsOneWidget);
  });

  testWidgets('el admin ve ensayos y despliega miembros con estado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(home: AdminAttendancePage(onBack: () => backs++)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asistencia'), findsOneWidget);
    expect(find.text('Ensayo General'), findsOneWidget);
    expect(find.text('Ana Paz'), findsNothing);

    await tester.tap(find.text('Ensayo General'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Paz'), findsOneWidget);
    expect(find.text('Luis Rey'), findsOneWidget);
    expect(find.text('Presente'), findsWidgets);
    expect(find.text('Tarde'), findsWidgets);
    expect(find.text('Ausente'), findsWidgets);

    await tester.tap(find.byTooltip('Administración'));
    await tester.pump();
    expect(backs, 1);
  });
}

class _EmptyRehearsalApi extends RehearsalApi {
  _EmptyRehearsalApi() : super(tokenStore: InMemoryTokenStore());

  @override
  Future<List<Rehearsal>> fetchUpcoming() async => const [];

  @override
  Future<List<Rehearsal>> fetchAll() async => const [];

  @override
  Future<({List<Rehearsal> items, int total})> fetchPage({
    int limit = 20,
    int offset = 0,
    int? ministryId,
  }) async => (items: const <Rehearsal>[], total: 0);

  @override
  Future<List<MinistryOption>> listMinistries() async => const [];
}
